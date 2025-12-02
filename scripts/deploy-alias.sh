#!/bin/bash
# Setup shell alias for automatic deployment

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Setting up shell aliases"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Detect shell
if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
    SHELL_NAME="zsh"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
    SHELL_NAME="bash"
else
    echo "❌ Unsupported shell"
    exit 1
fi

echo "📝 Shell detected: $SHELL_NAME"
echo "📄 RC file: $SHELL_RC"
echo ""

# Alias for smart deploy
ALIAS_DEPLOY="alias jt-deploy='cd $PROJECT_DIR && ./scripts/smart-deploy.sh'"

# Alias for quick setup
ALIAS_SETUP="alias jt-setup='cd $PROJECT_DIR && ./scripts/setup-org-url.sh && source .env'"

# Check if aliases already exist
if grep -q "jt-deploy" "$SHELL_RC"; then
    echo "⚠️  Aliases already exist in $SHELL_RC"
    echo ""
    echo "To update, remove existing aliases first:"
    echo "  grep -v 'jt-deploy\\|jt-setup' $SHELL_RC > temp && mv temp $SHELL_RC"
    echo ""
else
    # Add aliases
    echo "" >> "$SHELL_RC"
    echo "# JT Dynamic Queries - Auto aliases" >> "$SHELL_RC"
    echo "$ALIAS_DEPLOY" >> "$SHELL_RC"
    echo "$ALIAS_SETUP" >> "$SHELL_RC"
    
    echo "✅ Aliases added to $SHELL_RC"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Available commands:"
echo ""
echo "  jt-setup    → Setup Named Credential for current org"
echo "  jt-deploy   → Smart deploy (auto-detects org changes)"
echo ""
echo "💡 Reload your shell:"
echo "  source $SHELL_RC"
echo ""
echo "🎯 Usage example:"
echo "  sf config set target-org my-sandbox"
echo "  jt-deploy  # Auto-detects change and updates!"

