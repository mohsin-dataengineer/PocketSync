#!/usr/bin/env bash
# Local development helper — injects USER_CONFIG from .env.local, then
# starts `firebase serve` (which auto-serves Firebase credentials via
# /__/firebase/init.json so no credentials need to be in source code).
#
# Usage:
#   cp .env.example .env.local   # first time only
#   # fill in .env.local with real values
#   ./scripts/dev.sh

set -euo pipefail

if [ ! -f .env.local ]; then
  echo "Error: .env.local not found."
  echo "Run:  cp .env.example .env.local  then fill in the values."
  exit 1
fi

# Load env vars from .env.local (skip comment lines and blanks)
set -a
# shellcheck disable=SC1091
source .env.local
set +a

# Inject USER_CONFIG into a temporary copy of index.html
cp public/index.html public/index.html.bak
cp firestore.rules   firestore.rules.bak

python3 - <<'PYEOF'
import os

content = open('public/index.html').read()
content = content.replace('__USER_CONFIG__', os.environ['USER_CONFIG'])
open('public/index.html', 'w').write(content)

rules = open('firestore.rules').read()
rules = rules.replace('__RULE_EMAILS__', os.environ['RULE_EMAILS'])
open('firestore.rules', 'w').write(rules)
PYEOF

# Restore originals on exit (Ctrl-C or error)
trap 'echo "Restoring source files..."; mv public/index.html.bak public/index.html; mv firestore.rules.bak firestore.rules' EXIT

echo "Config injected. Starting firebase serve..."
firebase serve
