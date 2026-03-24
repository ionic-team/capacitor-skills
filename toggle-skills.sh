#!/usr/bin/env bash

# Toggle symlinking of Capacitor skills to ~/.claude/skills for local development
# This script will create symlinks if they don't exist, or remove them if they do

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SKILLS_SOURCE_DIR="${SCRIPT_DIR}/skills"
CLAUDE_SKILLS_DIR="${HOME}/.claude/skills"

# Ensure .claude/skills directory exists
if [ ! -d "${CLAUDE_SKILLS_DIR}" ]; then
    echo -e "${YELLOW}Creating ${CLAUDE_SKILLS_DIR} directory...${NC}"
    mkdir -p "${CLAUDE_SKILLS_DIR}"
fi

# Find all skill directories (directories containing SKILL.md)
declare -a SKILL_DIRS=()
while IFS= read -r -d '' skill_file; do
    skill_dir=$(dirname "$skill_file")
    SKILL_DIRS+=("$(basename "$skill_dir")")
done < <(find "${SKILLS_SOURCE_DIR}" -maxdepth 2 -type f -name "SKILL.md" -print0)

if [ ${#SKILL_DIRS[@]} -eq 0 ]; then
    echo -e "${RED}No skills found in ${SKILLS_SOURCE_DIR}${NC}"
    exit 1
fi

# Check if all symlinks exist
all_exist=true
for skill_name in "${SKILL_DIRS[@]}"; do
    target_link="${CLAUDE_SKILLS_DIR}/${skill_name}"
    if [ ! -L "${target_link}" ]; then
        all_exist=false
        break
    fi
done

# Toggle: remove if all exist, otherwise create
if [ "$all_exist" = true ]; then
    # Remove all symlinks
    for skill_name in "${SKILL_DIRS[@]}"; do
        target_link="${CLAUDE_SKILLS_DIR}/${skill_name}"
        if [ -L "${target_link}" ]; then
            rm "${target_link}"
        fi
    done
    echo -e "${GREEN}✓ Removed ${#SKILL_DIRS[@]} skill(s) from local development:${NC}"
    for skill_name in "${SKILL_DIRS[@]}"; do
        echo -e "  - ${skill_name}"
    done
else
    # Create all symlinks
    for skill_name in "${SKILL_DIRS[@]}"; do
        source_dir="${SKILLS_SOURCE_DIR}/${skill_name}"
        target_link="${CLAUDE_SKILLS_DIR}/${skill_name}"

        # Remove existing symlink if it exists (might be pointing to wrong location)
        if [ -L "${target_link}" ]; then
            rm "${target_link}"
        fi

        # Create symlink
        ln -s "${source_dir}" "${target_link}"
    done
    echo -e "${GREEN}✓ Added ${#SKILL_DIRS[@]} skill(s) for local development:${NC}"
    for skill_name in "${SKILL_DIRS[@]}"; do
        echo -e "  - ${skill_name}"
    done
fi
