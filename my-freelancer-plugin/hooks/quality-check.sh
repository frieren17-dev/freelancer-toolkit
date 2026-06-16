#!/usr/bin/env bash
# PostToolUse content-quality check for the freelancer-toolkit plugin.
#
# Claude Code runs this after every Write/Edit. It reads the hook payload (JSON)
# from stdin, finds the file that was just written, and — only if that file is a
# content file (.md/.txt/.html) — flags two common quality problems:
#   1. Thin content (fewer than 200 words).
#   2. Leftover placeholder / unfinished text ("lorem ipsum" or "TODO").
#
# Exit codes:
#   0  -> no issues, or not a content file -> stay silent.
#   2  -> issues found. The message printed to stderr is fed back to Claude so
#         it can fix the file. (The tool already ran; exit 2 does not undo it.)
# Prefer non-blocking FYI warnings instead? Change the final `exit 2` to `exit 0`.

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

# Nothing to check if we couldn't determine a path.
[ -n "$file_path" ] || exit 0

# 3. Only inspect content files (case-insensitive extension check).
file_lc="$(printf '%s' "$file_path" | tr '[:upper:]' '[:lower:]')"
case "$file_lc" in
  *.md|*.txt|*.html) ;;
  *) exit 0 ;;
esac

# Skip if the file isn't readable (e.g. it was moved or deleted).
[ -f "$file_path" ] || exit 0

# 4. Count words.
word_count="$(wc -w < "$file_path" 2>/dev/null | tr -d '[:space:]')"
[ -n "$word_count" ] || word_count=0

issues=""

# 5a. Thin-content warning.
if [ "$word_count" -lt 200 ]; then
  issues="${issues}  - Thin content: only ${word_count} words (under the 200-word guideline).
"
fi

# 5b. Placeholder / unfinished-text warning.
placeholder_hits="$(grep -niE 'lorem ipsum|\bTODO\b' "$file_path" 2>/dev/null | head -n5)"
if [ -n "$placeholder_hits" ]; then
  issues="${issues}  - Placeholder/unfinished text found (lorem ipsum / TODO):
$(printf '%s\n' "$placeholder_hits" | sed 's/^/      /')
"
fi

# 6. Report any issues to stderr and signal Claude.
if [ -n "$issues" ]; then
  {
    echo "⚠️  Content quality check — ${file_path}"
    printf '%s' "$issues"
  } >&2
  exit 2
fi

exit 0
