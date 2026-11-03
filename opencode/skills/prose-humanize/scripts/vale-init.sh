#!/usr/bin/env bash
# Set up Vale with the ai-tells style in the current repo.
# Usage: ./vale-init.sh [glob]   (default: *.md)
set -euo pipefail

GLOB="${1:-*.md}"

if ! command -v vale >/dev/null 2>&1; then
  echo "vale not found. Install with: brew install vale" >&2
  exit 1
fi

if [ -f .vale.ini ]; then
  echo "Note: .vale.ini exists and will be backed up."
  cp .vale.ini .vale.ini.bak
fi

cat > .vale.ini <<EOF
StylesPath = .vale/styles
MinAlertLevel = suggestion
Packages = ai-tells

[${GLOB}]
BasedOnStyles = ai-tells
; Rules that misfire on ordinary technical prose. Remove the line to re-enable.
ai-tells.ExplainerHeadings = NO
ai-tells.ConsequenceClause = NO
ai-tells.FigurativeStays = NO
ai-tells.MortalityMetaphors = NO
ai-tells.FormalTransitions = NO
EOF

echo "Syncing style package..."
vale sync

printf '.vale/styles/\n' >> .gitignore
sort -u .gitignore -o .gitignore

echo
echo "Done. Run:  vale ."
echo "Add to CI:  errata-ai/vale-action, or  vale --output=line . && exit 0"
