#!/bin/sh
set -e

SKILL_DIR="${HOME}/.codex/skills/codex-dispatch"
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -d "${HOME}/.codex/skills" ]; then
    mkdir -p "${HOME}/.codex/skills"
fi

if [ -d "$SKILL_DIR" ]; then
    echo "Error: $SKILL_DIR already exists. Remove it first or install to a different location."
    exit 1
fi

cp -r "$SRC_DIR/." "$SKILL_DIR"
echo "Installed codex-dispatch to ${SKILL_DIR}. Restart Codex to load the skill."
exit 0
