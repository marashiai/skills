#!/usr/bin/env bash
# Open a Hunk review in the user's terminal and print the new live session's id.
# The review opens in a new tab when the terminal can open one and in a new
# window otherwise.
#
# usage: open-hunk.sh <repo> <hunk args...>
#   e.g. open-hunk.sh . diff main...HEAD
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "usage: $0 <repo> <hunk args...>" >&2
  exit 64
fi
repo=$(cd "$1" && pwd)
shift
for tool in hunk jq; do
  command -v "$tool" >/dev/null || { echo "$tool is not installed" >&2; exit 69; }
done

manual="cd $(printf %q "$repo") && hunk$(printf ' %q' "$@")"
name="hunk: $(basename "$repo")"

launch=$(mktemp "${TMPDIR:-/tmp}/hunk-review.XXXXXX")
{
  # Terminals start this script from the login environment, without the
  # agent's environment and without the user's interactive shell configuration
  # (~/.zshrc, ~/.bashrc, config.fish). Start from the agent's PATH and editor
  # as a baseline, then let the user's own shell files take over below.
  printf '#!/usr/bin/env bash\nexport PATH=%q\n' "$PATH"
  for var in EDITOR VISUAL; do
    if [ -n "${!var:-}" ]; then
      printf 'export %s=%q\n' "$var" "${!var}"
    fi
  done
  printf 'cd %q\n' "$repo"
  printf 'set --'
  printf ' %q' "$@"
  printf '\n'
  cat <<'EOF'
# Run Hunk through the user's interactive login shell so the variables from
# their rc and profile files apply, exactly as in a shell tab. Without this,
# EDITOR and PATH entries set in ~/.zshrc or ~/.bashrc are missing and Hunk's
# `e` key reports "$EDITOR is not set". Hunk reads EDITOR only, so fall back
# to VISUAL.
shell=${SHELL:-/bin/sh}
case ${shell##*/} in
  bash|zsh)
    exec "$shell" -l -i -c '[ -n "${EDITOR-}" ] || [ -z "${VISUAL-}" ] || export EDITOR="$VISUAL"; exec hunk "$@"' hunk "$@" ;;
  fish)
    exec "$shell" -l -i -c 'test -n "$EDITOR"; or test -z "$VISUAL"; or set -gx EDITOR "$VISUAL"; exec hunk $argv' "$@" ;;
  *)
    [ -n "${EDITOR-}" ] || [ -z "${VISUAL-}" ] || export EDITOR="$VISUAL"
    exec hunk "$@" ;;
esac
EOF
} > "$launch"
chmod +x "$launch"

ghostty() {
  osascript - "$launch" "$repo" "$1" >/dev/null 2>&1 <<'APPLESCRIPT'
on run argv
  tell application "Ghostty"
    set cfg to new surface configuration
    set command of cfg to item 1 of argv
    set initial working directory of cfg to item 2 of argv
    if item 3 of argv is "tab" then
      new tab in front window with configuration cfg
    else
      new window with configuration cfg
    end if
  end tell
end run
APPLESCRIPT
}

iterm() {
  osascript - "$launch" >/dev/null 2>&1 <<'APPLESCRIPT'
on run argv
  tell application "iTerm2"
    if (count of windows) is 0 then
      create window with default profile command (item 1 of argv)
    else
      tell current window to create tab with default profile command (item 1 of argv)
    end if
  end tell
end run
APPLESCRIPT
}

# Each terminal first tries a tab and then a window. Multiplexers come first
# because they own the tabs the user sees.
open_review() {
  if [ -n "${REX_SESSION:-}" ] && command -v rex >/dev/null; then
    rex window new -s "$REX_SESSION" "$name" -c "$repo" --json -- "$launch" >/dev/null && return
  fi
  if [ -n "${TMUX:-}" ] && command -v tmux >/dev/null; then
    tmux new-window -n "$name" -c "$repo" "$launch" && return
  fi
  if [ -n "${ZELLIJ:-}" ] && command -v zellij >/dev/null; then
    zellij action new-tab -n "$name" -c "$repo" --close-on-exit -- "$launch" >/dev/null && return
  fi
  if [ -n "${WEZTERM_PANE:-}" ]; then
    "${WEZTERM_EXECUTABLE:-wezterm}" cli spawn --cwd "$repo" -- "$launch" >/dev/null && return
  fi
  if [ -n "${KITTY_PID:-}" ]; then
    # A tab needs kitty's remote control; without it, a detached window works.
    kitten @ launch --type=tab --tab-title "$name" --cwd "$repo" "$launch" >/dev/null 2>&1 && return
    kitty --detach --directory "$repo" "$launch" && return
  fi
  if [ "$(uname)" = Darwin ]; then
    case "${TERM_PROGRAM:-}" in
      ghostty) ghostty tab && return; ghostty window && return ;;
      iTerm.app) iterm && return ;;
      Apple_Terminal)
        # Terminal.app cannot script a tab, so open a window.
        osascript -e 'on run argv' -e 'tell application "Terminal" to do script (item 1 of argv)' -e 'end run' \
          "$(printf %q "$launch")" >/dev/null 2>&1 && return ;;
    esac
  fi
  return 1
}

sessions() {
  { hunk session list --json 2>/dev/null || true; } \
    | jq -r '.sessions[]? | .sessionId // .id' | sort
}
before=$(sessions)
if ! open_review; then
  rm -f "$launch"
  echo "Could not open a tab or window in this terminal; run this instead: $manual" >&2
  exit 2
fi

for _ in $(seq 1 40); do
  id=$(comm -13 <(printf '%s\n' "$before") <(sessions) | head -1)
  if [ -n "$id" ]; then
    echo "$id"
    exit 0
  fi
  sleep 0.5
done
echo "Hunk did not start a live session; run this instead: $manual" >&2
exit 1
