#!/usr/bin/env bash
# Open a Hunk review in a new Ghostty window and print the new live session's id.
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
if [ "$(uname)" != Darwin ] || ! osascript -e 'id of application "Ghostty"' >/dev/null 2>&1; then
  echo "Ghostty on macOS is required to open a window; run this instead: $manual" >&2
  exit 2
fi

launch=$(mktemp "${TMPDIR:-/tmp}/hunk-review.XXXXXX")
{
  # Ghostty starts the command without a login profile; keep the caller's PATH
  # and editor so Hunk can open files.
  printf '#!/usr/bin/env bash\nexport PATH=%q\n' "$PATH"
  for var in EDITOR VISUAL; do
    if [ -n "${!var:-}" ]; then
      printf 'export %s=%q\n' "$var" "${!var}"
    fi
  done
  printf 'cd %q\nexec hunk' "$repo"
  printf ' %q' "$@"
  printf '\n'
} > "$launch"
chmod +x "$launch"

sessions() { hunk session list --json | jq -r '.sessions[] | .sessionId // .id' | sort; }
before=$(sessions)
osascript - "$launch" "$repo" >/dev/null <<'APPLESCRIPT'
on run argv
  tell application "Ghostty"
    set cfg to new surface configuration
    set command of cfg to item 1 of argv
    set initial working directory of cfg to item 2 of argv
    new window with configuration cfg
  end tell
end run
APPLESCRIPT

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
