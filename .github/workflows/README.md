# GitHub Actions Workflows

## Available Workflows

### CI/CD Pipelines

- **`apex-tests.yml`** - Apex unit tests (runs on PR and push)
- **`lwc-tests.yml`** - Lightning Web Component unit tests
- **`e2e-tests.yml`** - End-to-end tests with Playwright
- **`e2e-on-merge.yml`** - E2E tests on merge to main
- **`gh-pages.yml`** - Deploy documentation to GitHub Pages
- **`test-github-pages.yml`** - Test GitHub Pages site

### Validation

- **`validate-metadata.yml`** - Validate Salesforce metadata
- **`code-quality.yml`** - ESLint, Prettier, YAML lint

## Local Testing with act

### Quick Start

```bash
# List all workflows
npm run validate:pipeline:list

# Dry run (see what would execute)
npm run validate:pipeline:dry

# Run specific workflow
npm run validate:pipeline -- -w apex-tests.yml

# Run specific job
npm run validate:pipeline -- -w apex-tests.yml -j test
```

### Full Documentation

See [`scripts/ACT_USAGE.md`](../../scripts/ACT_USAGE.md) for complete act usage guide.

## Workflow Structure

### Triggers

Most workflows are triggered by:
- `push` to `main` branch
- `pull_request` events
- `workflow_dispatch` (manual trigger)

### Jobs

Each workflow typically includes:
1. **Setup** - Install dependencies, authenticate
2. **Lint** - Code quality checks
3. **Test** - Unit/E2E tests
4. **Build** - Compile/package (if needed)
5. **Deploy** - Deploy to org/pages (if applicable)

### Secrets

Required secrets (set in GitHub repo settings):
- `SFDX_AUTH_URL` - Salesforce org authentication
- `SF_JWT_KEY` - JWT key for Salesforce authentication
- (others as needed per workflow)

## Best Practices

### Before Pushing

1. **Validate locally:**
   ```bash
   npm run validate:pipeline -- -w your-workflow.yml
   ```

2. **Run affected tests:**
   ```bash
   npm test
   npm run test:e2e
   ```

3. **Check linting:**
   ```bash
   npm run prettier:verify
   npm run lint
   ```

### Debugging Failures

1. **Check workflow logs** on GitHub Actions tab
2. **Run locally with act:**
   ```bash
   npm run validate:pipeline -- -w failing-workflow.yml
   ```
3. **Use dry run** to understand job dependencies:
   ```bash
   npm run validate:pipeline:dry
   ```

### Workflow Updates

When modifying workflows:

1. ✅ **DO:**
   - Test locally with act first
   - Use workflow_dispatch for manual testing
   - Add comments explaining complex logic
   - Keep jobs idempotent

2. ❌ **DON'T:**
   - Push directly to main without testing
   - Use hardcoded values (use variables/secrets)
   - Create circular dependencies
   - Run heavy operations on every push

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [act - Local Testing Tool](https://github.com/nektos/act)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

