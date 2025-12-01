# 🚀 Deploy and Test Workflow

## Pre-Commit Validation Process

**Rule:** Never commit without testing in target org.

---

## 📋 Complete Workflow

### 1. Local Development
```bash
# Make your changes
# Write/update tests
npm run test:e2e        # Run E2E tests locally
```

### 2. Deploy to Org
```bash
# Deploy to your target org (sandbox/scratch)
sf project deploy start --target-org <your-alias>

# Wait for deployment to complete
# Check for any deployment errors
```

### 3. Run Apex Tests in Org
```bash
# Run all local tests in the org
sf apex run test --target-org <your-alias> \
  --test-level RunLocalTests \
  --result-format human \
  --code-coverage

# Verify:
# - All tests pass ✓
# - Coverage > 75% ✓
# - No failures ✓
```

### 4. Manual Validation in Org UI

#### Navigate to Component
```
1. Login to org
2. Navigate to App Launcher → Dynamic Queries
3. Open Query Viewer tab
```

#### Test All Scenarios
```
□ Select configuration from dropdown
□ Verify query preview shows SOQL
□ Verify data preview table appears
□ Check pagination controls (if > 3 records)
□ Click Previous/Next buttons
□ Change parameter values
□ Verify preview reloads
□ Click Execute Query
□ Verify results display correctly
□ Test "Run As User" (if admin)
□ Test "Create Configuration" (if sandbox)
□ Open Create Modal
□ Validate SOQL
□ Save configuration
□ Verify "Where is this used?" feature
□ Test cache clearing
□ Open cache modal
□ Select options
□ Clear cache
□ Verify refresh
```

#### Check for Errors
```
□ Open browser DevTools (F12)
□ Check Console tab for errors
□ Verify no red error messages
□ Check Network tab for failed requests
□ Verify no 500/400 errors
```

#### Test Edge Cases
```
□ Select config with no records → Empty table displays
□ Select config with parameters → Inputs appear
□ Enter invalid parameter → Error message shows
□ Select config with > 10 records → Pagination works
□ Clear configuration → UI resets
□ Test on mobile viewport (optional)
□ Test toast notifications → Auto-dismiss after 5s
```

### 5. Validate Deployment (Optional but Recommended)
```bash
# Validate deployment without actually deploying
sf project deploy validate --target-org <your-alias>

# This runs all tests without modifying org
# Useful for final check before commit
```

### 6. Commit and Push (Only After ALL Above Pass)
```bash
# Stage changes
git add -A

# Commit with descriptive message
git commit -m "feat(preview): Add query data preview

✨ Feature: Query preview with pagination
✅ Org Tests: All pass in target org
✅ Manual Validation: Complete
✅ Edge Cases: Tested

Tested in: my-sandbox-alias
Deployed: Success
Apex Tests: 100% pass
Coverage: 84.5%
E2E Tests: 11/11 pass"

# Push to remote
git push origin main
```

---

## 🎯 Quick Commands

### Deploy + Test (One Command)
```bash
# Deploy and run tests in one go
sf project deploy start --target-org <alias> --test-level RunLocalTests

# Or use this alias (add to ~/.zshrc or ~/.bashrc)
alias sf-deploy-test='sf project deploy start --target-org $(sf config get target-org --json | jq -r .result[0].value) --test-level RunLocalTests'
```

### Validate Only (No Deploy)
```bash
# Run validation without deploying
sf project deploy validate --target-org <alias> --test-level RunLocalTests

# Useful for checking if changes will deploy successfully
```

### Quick Deploy (If Already Validated)
```bash
# If you just ran validate, you can quick deploy
sf project deploy quick --target-org <alias> --use-most-recent

# Uses the most recent validation to deploy faster
```

---

## 🔴 Common Issues and Fixes

### Issue: "Test Failures in Org"
```bash
# Get detailed test results
sf apex get test --test-run-id <id> --target-org <alias>

# Check specific test failure
sf apex get test --test-run-id <id> --target-org <alias> --output-dir ./test-results
```

**Action:** Fix the failing test, redeploy, revalidate.

### Issue: "Deployment Failed"
```bash
# Get deployment status
sf project deploy report --target-org <alias>

# Check for specific errors
sf project deploy report --target-org <alias> --verbose
```

**Common causes:**
- Missing dependencies
- Invalid field references
- Permission issues
- Governor limits in tests

**Action:** Fix the deployment error, redeploy, revalidate.

### Issue: "Manual Validation Failed"
**Action:** 
1. Fix the issue locally
2. Redeploy
3. Revalidate manually
4. Do NOT commit until validation passes

### Issue: "Code Coverage Below 75%"
```bash
# Check which classes need coverage
sf apex run test --target-org <alias> \
  --code-coverage \
  --result-format json > coverage.json

# View coverage report
cat coverage.json | jq '.result.coverage.coverage'
```

**Action:** Add more test methods to cover uncovered lines.

---

## 📊 Example: Complete Workflow

```bash
# 1. Make changes locally
# ... edit files ...

# 2. Run local E2E tests
npm run test:e2e
# ✅ 11/11 tests pass

# 3. Deploy to org
sf project deploy start --target-org my-sandbox
# ✅ Deploy Succeeded

# 4. Run Apex tests in org
sf apex run test --target-org my-sandbox \
  --test-level RunLocalTests \
  --code-coverage
# ✅ 723 tests pass
# ✅ Coverage: 84.5%

# 5. Manual validation in org
# ... login to org ...
# ... test all scenarios ...
# ✅ All scenarios work
# ✅ No console errors
# ✅ Edge cases tested

# 6. Commit and push
git add -A
git commit -m "feat: Add data preview"
git push origin main
# ✅ Done!
```

---

## 🎓 Why This Process Matters

### Prevents Issues:
- ❌ Deploying broken code
- ❌ Breaking existing functionality
- ❌ Governor limit violations
- ❌ Permission issues
- ❌ UI bugs in production

### Ensures Quality:
- ✅ Code works in real Salesforce environment
- ✅ All tests pass in target org
- ✅ Manual validation confirms UX
- ✅ Edge cases covered
- ✅ Confidence before commit

---

## 🚨 Red Flags (DO NOT COMMIT)

- ❌ Any Apex test fails in org
- ❌ Deployment fails
- ❌ Console errors in browser
- ❌ UI doesn't match BDD scenario
- ❌ Edge case fails
- ❌ Code coverage below 75%
- ❌ Manual validation incomplete

**If any red flag appears:** Fix → Redeploy → Revalidate → Then commit.

---

## ✅ Green Lights (SAFE TO COMMIT)

- ✅ All Apex tests pass in org
- ✅ Deployment succeeds
- ✅ No console errors
- ✅ All BDD scenarios work
- ✅ Edge cases tested
- ✅ Code coverage > 75%
- ✅ Manual validation complete

**All green?** Commit with confidence! 🚀

---

Remember: **Local tests are not enough. Org validation is mandatory.**

