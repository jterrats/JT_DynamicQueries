# 🌐 GitHub Pages E2E Testing

## 📋 Overview

Automated E2E tests for the published GitHub Pages documentation site at:
**https://jterrats.github.io/JT_DynamicQueries/**

## 🎯 What is Tested

### 📄 Page Accessibility

- ✅ All critical documentation pages load (no 404s)
- ✅ Homepage, Gallery, Features, Architecture
- ✅ V3.0 Roadmap and GitHub Issues documentation
- ✅ Technical docs (Run As User, Semantic HTML, E2E reports)
- ✅ Functional documentation

### 🔗 Navigation & Links

- ✅ Internal navigation links work
- ✅ Quick Links section is functional
- ✅ GitHub repository links are correct
- ✅ Issue tracker links work
- ✅ Deploy to Salesforce button is present

### 🎨 UI/UX

- ✅ Responsive design (desktop and mobile)
- ✅ Footer is present with correct content
- ✅ Images load correctly
- ✅ Code blocks are formatted
- ✅ Heading hierarchy is proper

### ♿ Accessibility

- ✅ All images have alt text
- ✅ Proper semantic HTML
- ✅ No console errors
- ✅ External links have proper attributes

### ⚡ Performance

- ✅ Homepage loads within 5 seconds
- ✅ No broken images
- ✅ Efficient resource loading

### 📊 SEO

- ✅ Page metadata present
- ✅ Proper titles and descriptions

## 🚀 Running the Tests

### Install Dependencies

```bash
npm install
```

### Run All GitHub Pages Tests

```bash
npm run test:github-pages
```

### Run with UI Mode (Recommended for Development)

```bash
npm run test:github-pages:headed
```

### View Test Report

```bash
npm run test:github-pages:report
```

### Run Specific Test

```bash
npx playwright test tests/e2e/github-pages.spec.js --grep "Homepage loads successfully"
```

### Run on Specific Browser

```bash
# Chrome
npx playwright test --config=tests/e2e/github-pages.config.js --project=chromium

# Firefox
npx playwright test --config=tests/e2e/github-pages.config.js --project=firefox

# Safari
npx playwright test --config=tests/e2e/github-pages.config.js --project=webkit

# Mobile
npx playwright test --config=tests/e2e/github-pages.config.js --project="Mobile Chrome"
```

## 📊 Test Coverage

### Current Test Suite

| Category           | Tests  | Status |
| ------------------ | ------ | ------ |
| Page Load          | 12     | ✅     |
| Navigation         | 5      | ✅     |
| Content Validation | 8      | ✅     |
| Accessibility      | 4      | ✅     |
| Performance        | 2      | ✅     |
| SEO                | 2      | ✅     |
| **Total**          | **33** | ✅     |

## 🔍 Critical Pages Tested

### Core Documentation

- ✅ `/` - Homepage
- ✅ `/gallery.html` - Demo Gallery
- ✅ `/FEATURES_v2.html` - Features Documentation
- ✅ `/ARCHITECTURE_LAYERS.html` - Architecture

### v3.0 Documentation

- ✅ `/V3_ROADMAP.html` - Complete v3.0 Roadmap
- ✅ `/GITHUB_ISSUES_V3.html` - 18 GitHub Issues with User Stories

### Technical Documentation

- ✅ `/RUN_AS_USER_FEATURE.html` - Run As User Feature
- ✅ `/FUNCTIONAL_RUN_AS.html` - Functional Run As
- ✅ `/SEMANTIC_HTML_FINAL_REPORT.html` - Semantic HTML Report
- ✅ `/E2E_COMPLETE_SUCCESS.html` - E2E Test Results

## 🛠️ Configuration

Tests use a custom Playwright configuration (`github-pages.config.js`) with:

- **Timeout:** 60 seconds (for external site)
- **Retries:** 2 on CI, 1 locally
- **Browsers:** Chrome, Firefox, Safari, Mobile Chrome, Mobile Safari
- **Reports:** HTML, JSON, List

## 🔄 CI/CD Integration

### GitHub Actions Workflow

Add to `.github/workflows/test-github-pages.yml`:

```yaml
name: Test GitHub Pages

on:
  push:
    branches: [main]
  schedule:
    # Run daily at 2 AM UTC
    - cron: "0 2 * * *"
  workflow_dispatch:

jobs:
  test-github-pages:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: "24"

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright Browsers
        run: npx playwright install --with-deps

      - name: Run GitHub Pages Tests
        run: npm run test:github-pages

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: playwright-report-github-pages
          path: playwright-report-github-pages/
          retention-days: 30
```

### Run After Deploy

Add to your existing GitHub Pages deploy workflow:

```yaml
- name: Test Deployed Site
  run: npm run test:github-pages
```

## 📈 Monitoring & Alerts

### Success Criteria

- ✅ All 33 tests pass
- ✅ No 404 errors
- ✅ Load time < 5 seconds
- ✅ Zero console errors
- ✅ All images load

### When to Run

1. **After Each Deploy** - Verify deployment success
2. **Daily** - Monitor site health
3. **Before Releases** - Pre-release validation
4. **On Pull Requests** - Prevent breaking changes

## 🐛 Troubleshooting

### Test Failures

**404 Errors:**

```bash
# Verify file exists in docs/ folder
ls -la docs/RUN_AS_USER_FEATURE.md

# Check GitHub Pages build status
gh run list --workflow=pages-build-deployment
```

**Timeout Errors:**

```bash
# Increase timeout in github-pages.config.js
timeout: 90000  // 90 seconds
```

**Network Issues:**

```bash
# Test site accessibility
curl -I https://jterrats.github.io/JT_DynamicQueries/

# Check DNS resolution
nslookup jterrats.github.io
```

### Common Issues

**Issue:** Tests fail immediately after push

- **Solution:** Wait 2-5 minutes for GitHub Pages to rebuild

**Issue:** Images not loading

- **Solution:** Check image paths are relative and files exist in docs/

**Issue:** 404 on specific page

- **Solution:** Ensure file is in `docs/` folder and committed

## 📝 Adding New Tests

### Example: Test New Documentation Page

```javascript
test("New feature docs are accessible", async ({ page }) => {
  const response = await page.goto(`${BASE_URL}/NEW_FEATURE.html`);
  expect([200, 304]).toContain(response.status());

  await expect(page.locator("body")).toContainText("New Feature");
});
```

### Best Practices

1. **Use data-testid** for stable selectors
2. **Test content**, not implementation
3. **Mock external APIs** if needed
4. **Keep tests fast** (< 30s each)
5. **Use meaningful assertions**
6. **Add comments** for complex tests

## 🎯 Goals

- ✅ **Zero 404 errors** on production site
- ✅ **100% uptime** monitoring
- ✅ **Fast load times** (< 5s)
- ✅ **Accessible** to all users
- ✅ **Mobile-friendly** design

## 📞 Support

- **Issues:** Report test failures as GitHub issues
- **Documentation:** See main E2E testing docs
- **Questions:** Open a discussion on GitHub

## 🔗 Related Documentation

- [Main E2E Tests](./README.md)
- [Accessibility Tests](./accessibility.spec.js)
- [Query Viewer Tests](./queryViewer.spec.js)
- [GitHub Pages Docs](https://jterrats.github.io/JT_DynamicQueries/)

---

**Last Updated:** December 1, 2025
**Test Coverage:** 33 tests, 6 categories
**Status:** ✅ All Passing
