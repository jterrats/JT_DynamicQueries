#!/bin/bash
# Script to prepare static HTML files for local preview
# Replaces Jekyll variables with static values

set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE_DIR"

# Base URL for local preview (empty for root)
BASEURL=""

# Site configuration
SITE_TITLE="Dynamic Query Framework"
SITE_DESCRIPTION="Transform how you work with Salesforce data. Dynamic Query Framework is a comprehensive LWC development tool."
SITE_AUTHOR="Jaime Terrats"
SITE_GITHUB_USERNAME="jterrats"
SITE_REPOSITORY="jterrats/JT_DynamicQueries"
SITE_URL="http://localhost:8000"

echo "🔧 Preparing static HTML files for local preview..."

# Process index.html
if [ -f "index.html" ]; then
  echo "   Processing index.html..."

  # Read the layout
  if [ -f "_layouts/default.html" ]; then
    LAYOUT_CONTENT=$(cat "_layouts/default.html")

    # Process includes
    if [ -f "_includes/head.html" ]; then
      HEAD_CONTENT=$(cat "_includes/head.html")
      # Replace Jekyll variables in head
      HEAD_CONTENT=$(echo "$HEAD_CONTENT" | sed "s|{{ site.baseurl }}|$BASEURL|g")
      HEAD_CONTENT=$(echo "$HEAD_CONTENT" | sed "s|{{ site.title }}|$SITE_TITLE|g")
      HEAD_CONTENT=$(echo "$HEAD_CONTENT" | sed "s|{{ site.description }}|$SITE_DESCRIPTION|g")
      HEAD_CONTENT=$(echo "$HEAD_CONTENT" | sed "s|{{ site.author }}|$SITE_AUTHOR|g")
      HEAD_CONTENT=$(echo "$HEAD_CONTENT" | sed "s|{{ site.github_username }}|$SITE_GITHUB_USERNAME|g")
      HEAD_CONTENT=$(echo "$HEAD_CONTENT" | sed "s|{{ site.repository }}|$SITE_REPOSITORY|g")
      HEAD_CONTENT=$(echo "$HEAD_CONTENT" | sed "s|{{ site.url }}|$SITE_URL|g")
      HEAD_CONTENT=$(echo "$HEAD_CONTENT" | sed "s|{{ page.title }}|Home|g")
      HEAD_CONTENT=$(echo "$HEAD_CONTENT" | sed "s|{{ page.description }}|$SITE_DESCRIPTION|g")
      HEAD_CONTENT=$(echo "$HEAD_CONTENT" | sed "s|{{ page.og_title }}|Dynamic Query Framework - Beyond Simple SOQL Queries|g")
      HEAD_CONTENT=$(echo "$HEAD_CONTENT" | sed "s|{{ page.og_description }}|$SITE_DESCRIPTION|g")
      HEAD_CONTENT=$(echo "$HEAD_CONTENT" | sed "s|{{ page.og_image }}|01-query-execution.gif|g")
      HEAD_CONTENT=$(echo "$HEAD_CONTENT" | sed "s|{{ page.url }}|/|g")
      HEAD_CONTENT=$(echo "$HEAD_CONTENT" | sed "s|{% if page.title %}{{ page.title }} - {{ site.title }}{% else %}{{ site.title }} - Dynamic SOQL Query Framework for Salesforce{% endif %}|$SITE_TITLE - Dynamic SOQL Query Framework for Salesforce|g")
      HEAD_CONTENT=$(echo "$HEAD_CONTENT" | sed "s|{% if page.description %}{{ page.description }}{% else %}{{ site.description }}{% endif %}|$SITE_DESCRIPTION|g")
      HEAD_CONTENT=$(echo "$HEAD_CONTENT" | sed "s|{% if page.og_title %}{{ page.og_title }}{% else %}{{ site.title }} - Beyond Simple SOQL Queries{% endif %}|$SITE_TITLE - Beyond Simple SOQL Queries|g")
      HEAD_CONTENT=$(echo "$HEAD_CONTENT" | sed "s|{% if page.og_description %}{{ page.og_description }}{% else %}A comprehensive Salesforce development framework that transforms how developers interact with data. Pre-configured queries, Run As User testing, tree view relationships, and enterprise-scale performance.{% endif %}|A comprehensive Salesforce development framework that transforms how developers interact with data. Pre-configured queries, Run As User testing, tree view relationships, and enterprise-scale performance.|g")
      HEAD_CONTENT=$(echo "$HEAD_CONTENT" | sed "s|{% if page.og_image %}{{ page.og_image }}{% else %}01-query-execution.gif{% endif %}|01-query-execution.gif|g")
    fi

    if [ -f "_includes/nav.html" ]; then
      NAV_CONTENT=$(cat "_includes/nav.html")
      NAV_CONTENT=$(echo "$NAV_CONTENT" | sed "s|{{ site.baseurl }}|$BASEURL|g")
      NAV_CONTENT=$(echo "$NAV_CONTENT" | sed "s|{{ site.github_username }}|$SITE_GITHUB_USERNAME|g")
      NAV_CONTENT=$(echo "$NAV_CONTENT" | sed "s|{{ page.url }}|/|g")
    fi

    if [ -f "_includes/footer.html" ]; then
      FOOTER_CONTENT=$(cat "_includes/footer.html")
      FOOTER_CONTENT=$(echo "$FOOTER_CONTENT" | sed "s|{{ site.baseurl }}|$BASEURL|g")
      FOOTER_CONTENT=$(echo "$FOOTER_CONTENT" | sed "s|{{ site.github_username }}|$SITE_GITHUB_USERNAME|g")
      FOOTER_CONTENT=$(echo "$FOOTER_CONTENT" | sed "s|{{ site.author }}|$SITE_AUTHOR|g")
      FOOTER_CONTENT=$(echo "$FOOTER_CONTENT" | sed "s|{{ site.license }}|MIT|g")
    fi

    # Get page content (skip front matter)
    PAGE_CONTENT=$(tail -n +11 "index.html" | sed '/^---$/d')

    # Replace in layout
    LAYOUT_CONTENT=$(echo "$LAYOUT_CONTENT" | sed "s|{% include head.html %}|$HEAD_CONTENT|g")
    LAYOUT_CONTENT=$(echo "$LAYOUT_CONTENT" | sed "s|{% include nav.html %}|$NAV_CONTENT|g")
    LAYOUT_CONTENT=$(echo "$LAYOUT_CONTENT" | sed "s|{{ content }}|$PAGE_CONTENT|g")
    LAYOUT_CONTENT=$(echo "$LAYOUT_CONTENT" | sed "s|{% include footer.html %}|$FOOTER_CONTENT|g")
    LAYOUT_CONTENT=$(echo "$LAYOUT_CONTENT" | sed "s|{{ site.baseurl }}|$BASEURL|g")
    LAYOUT_CONTENT=$(echo "$LAYOUT_CONTENT" | sed "s|{{ page.lang | default: 'en' }}|en|g")

    # Write to index-static.html
    echo "$LAYOUT_CONTENT" > "index-static.html"
    echo "   ✅ Created index-static.html"
  fi
fi

echo "✅ Static files prepared!"
echo ""
echo "📝 To preview:"
echo "   python3 -m http.server 8000"
echo "   Then open: http://localhost:8000/index-static.html"

