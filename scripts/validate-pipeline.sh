#!/bin/bash
# Validate GitHub Actions workflows locally using act

set -e

echo "🎬 act - Local GitHub Actions Testing"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if act is installed
if ! command -v act &> /dev/null; then
    echo -e "${RED}❌ act is not installed${NC}"
    echo "Install it with: brew install act"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker is not running${NC}"
    echo "Please start Docker Desktop"
    exit 1
fi

echo -e "${GREEN}✅ act is installed${NC}"
echo -e "${GREEN}✅ Docker is running${NC}"
echo ""

# Show available workflows
echo "📋 Available workflows:"
echo ""
act -l
echo ""

# Parse command line arguments
WORKFLOW=""
JOB=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --workflow|-w)
            WORKFLOW="$2"
            shift 2
            ;;
        --job|-j)
            JOB="$2"
            shift 2
            ;;
        --dry-run|-d)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -w, --workflow NAME    Workflow file to run (e.g., apex-tests.yml)"
            echo "  -j, --job NAME         Specific job to run"
            echo "  -d, --dry-run          Show what would run without executing"
            echo "  -h, --help             Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                                    # List all workflows"
            echo "  $0 -w apex-tests.yml                 # Run specific workflow"
            echo "  $0 -w apex-tests.yml -j test         # Run specific job"
            echo "  $0 -d                                # Dry run (show what would execute)"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Build act command
ACT_CMD="act"

if [ "$DRY_RUN" = true ]; then
    ACT_CMD="$ACT_CMD -n"
    echo -e "${YELLOW}🔍 DRY RUN MODE${NC}"
fi

if [ -n "$WORKFLOW" ]; then
    ACT_CMD="$ACT_CMD -W .github/workflows/$WORKFLOW"
    echo -e "${GREEN}Running workflow: $WORKFLOW${NC}"
fi

if [ -n "$JOB" ]; then
    ACT_CMD="$ACT_CMD -j $JOB"
    echo -e "${GREEN}Running job: $JOB${NC}"
fi

echo ""
echo -e "${YELLOW}🚀 Executing: $ACT_CMD${NC}"
echo ""

# Run act
eval $ACT_CMD

echo ""
echo -e "${GREEN}✨ Done!${NC}"


