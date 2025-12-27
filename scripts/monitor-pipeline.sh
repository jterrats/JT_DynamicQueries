#!/bin/bash
# Monitor GitHub Actions pipeline for current branch

BRANCH=$(git branch --show-current)
echo "🔍 Monitoring pipeline for branch: $BRANCH"
echo ""

# Get the latest run
LATEST_RUN=$(gh run list --branch "$BRANCH" --limit 1 --json databaseId,status,conclusion --jq '.[0].databaseId')

if [ -z "$LATEST_RUN" ] || [ "$LATEST_RUN" == "null" ]; then
  echo "❌ No runs found for branch $BRANCH"
  exit 1
fi

echo "📊 Latest Run ID: $LATEST_RUN"
echo ""

# Get initial status
STATUS=$(gh run view "$LATEST_RUN" --json status --jq '.status')
echo "📋 Current Status: $STATUS"
echo ""

# If already completed, show summary
if [ "$STATUS" == "completed" ]; then
  CONCLUSION=$(gh run view "$LATEST_RUN" --json conclusion --jq '.conclusion')
  echo "✅ Conclusion: $CONCLUSION"
  echo ""
  echo "📋 Jobs Summary:"
  gh run view "$LATEST_RUN" --json jobs --jq '.jobs[] | "  \(.name): \(.status) - \(.conclusion // "N/A")"'
  echo ""
  echo "🔗 View details: https://github.com/jterrats/JT_DynamicQueries/actions/runs/$LATEST_RUN"
else
  echo "⏳ Pipeline is still running. Monitoring..."
  echo ""
  # Watch the run (will update every 3 seconds)
  gh run watch "$LATEST_RUN"
fi
