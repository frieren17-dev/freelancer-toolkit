#!/usr/bin/env bash
# PostToolUse change logger for the freelancer-toolkit plugin.
#
# Claude Code runs this after every Write. It reads the hook payload (JSON) from
# stdin, finds the file that was just written, and appends a timestamped line to
# changelog.txt so there is a running record of what Claude created.
#
# Registered against the "Write" tool only (the file-creation tool); Edit just
# modifies files that already exist, so it is intentionally not logged here.
#
# Exit codes:
#   0 -> always. Logging must never block or interrupt Claude's work, so even on
#        failure we exit 0 and stay silent.

# 1. Read the entire hook payload from stdin.
input="$(cat)"

# 2. Extract tool_input.file_path. Prefer jq; fall back to a grep/sed parse so
#    the hook still works on machines without jq installed.
file_path=""
if command -v jq >/dev/null 2>&1; then
  file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
fi
if [ -z "$file_path" ]; then
  file_path="$(printf '%s' "$input" \
    | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"' \
    | head -n1 \
    | sed -E 's/^"file_path"[[:space:]]*:[[:space:]]*"//; s/"$//')"
  # Unescape JSON backslashes, e.g. a Windows path "C:\\Users" -> "C:\Users".
  file_path="${file_path//\\\\/\\}"
fi

# Nothing to log if we couldn't determine a path.
[ -n "$file_path" ] || exit 0

# 3. Decide where changelog.txt lives: the project root if Claude Code provided
#    it, otherwise the current working directory.
log_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
log_file="${log_dir}/changelog.txt"

# 4. Append a timestamped entry. ISO-8601 local time keeps lines sortable.
timestamp="$(date '+%Y-%m-%dT%H:%M:%S%z')"
printf '%s\tWrite\t%s\n' "$timestamp" "$file_path" >> "$log_file" 2>/dev/null

# 5. Logging is best-effort and must never disrupt Claude — always succeed.
exit 0
