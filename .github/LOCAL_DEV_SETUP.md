# 🚀 Salesforce Local Dev (Hot Reload) Setup

## What is Local Dev?

**Local Dev (Beta)** es el nuevo feature de Salesforce (Winter '25 / Dreamforce 2024) que permite:

- ✅ **Hot Module Replacement (HMR)** - Cambios se reflejan instantáneamente
- ✅ **No deploy para ver cambios** - Solo guarda y ve cambios en browser
- ✅ **Preserva estado de página** - No refresh completo
- ✅ **Ahorra 3-10 segundos por cambio** - Se acumula en horas al día

**Reemplaza al antiguo:** LWC Local Development Server (deprecated Sept 2025)

---

## 📋 Setup Instructions

### 1. Install Local Dev Plugin

```bash
# Install the plugin
sf plugins install @salesforce/plugin-lightning-dev

# Verify installation
sf plugins
```

### 2. Enable in Org

#### For Sandbox/Production:

1. Login to org
2. Setup → Quick Find → "Local Dev"
3. Check "Enable Local Dev (Beta)"
4. Save

#### For Scratch Org:

Edit `config/project-scratch-def.json`:

```json
{
  "settings": {
    "enableLightningPreviewPref": true
  }
}
```

### 3. Disable Cookie Restriction

Setup → Quick Find → "My Domain"

- Uncheck "Require first-party use of Salesforce cookies"

---

## 🚀 How to Use Local Dev

### Start Local Dev Server

```bash
# For Lightning Experience app
sf lightning dev app --name "Dynamic Queries"

# Or let CLI prompt you
sf lightning dev app

# For mobile preview (iOS)
sf lightning dev app --target org my-sandbox --device-type ios

# For mobile preview (Android)
sf lightning dev app --device-type android
```

### What Happens:

1. Browser opens at special dev preview URL
2. WebSocket connection established
3. **Save any LWC file → Changes appear instantly!**
4. Page state preserved (no refresh needed)

---

## ✅ What Works with Hot Reload

Changes that **automatically update** without deploy:

| Change Type           | Example                      | Auto-Reload |
| --------------------- | ---------------------------- | ----------- |
| HTML changes          | `<div>` → `<section>`        | ✅ Yes      |
| CSS changes           | `color: blue` → `color: red` | ✅ Yes      |
| JavaScript logic      | Event handlers, methods      | ✅ Yes      |
| Component references  | Add `<c-my-component>`       | ✅ Yes      |
| Template conditionals | `if:true={show}` changes     | ✅ Yes      |

---

## ❌ What Requires Manual Deploy

Changes that **require deploy + restart**:

| Change Type           | Example                      | Auto-Reload    |
| --------------------- | ---------------------------- | -------------- |
| `@api` properties     | Add new `@api myProp`        | ❌ No - Deploy |
| `@wire` adapters      | Add/change wire config       | ❌ No - Deploy |
| Apex methods          | Change `@AuraEnabled` method | ❌ No - Deploy |
| `@salesforce` imports | Import new module            | ❌ No - Deploy |
| `.js-meta.xml`        | Change metadata              | ❌ No - Deploy |
| Service components    | Revise library               | ❌ No - Deploy |

---

## 🔄 Updated Development Workflow

### Option A: Local Dev (For UI/Style Changes)

```bash
# 1. Start Local Dev server
sf lightning dev app --name "Dynamic Queries"

# 2. Make changes to HTML/CSS/JS
# ... edit jtQueryViewer.html ...
# ... edit jtQueryViewer.css ...

# 3. Save file (Cmd+S)
# → Changes appear instantly in browser! ✨

# 4. Iterate quickly
# → Edit → Save → See changes → Repeat

# 5. When done with UI, deploy to org
sf project deploy start

# 6. Run tests in org
sf apex run test --test-level RunLocalTests

# 7. Run E2E tests
npm run test:e2e

# 8. Commit
git add -A && git commit -m "..."
```

### Option B: Traditional Deploy (For Apex/API Changes)

```bash
# 1. Make changes to Apex/@api/@wire
# ... edit JT_QueryViewerController.cls ...
# ... add @api property ...

# 2. Deploy to org (REQUIRED for Apex changes)
sf project deploy start

# 3. Run Apex tests in org
sf apex run test --test-level RunLocalTests

# 4. Run E2E tests
npm run test:e2e

# 5. Manual validation
# 6. Commit
```

---

## 🎯 When to Use Local Dev vs Traditional Deploy

### Use Local Dev For:

- ✅ UI/UX iterations (HTML/CSS changes)
- ✅ Styling adjustments
- ✅ Layout refinements
- ✅ Visual polish
- ✅ Event handler logic (non-@api)
- ✅ Quick prototyping

### Use Traditional Deploy For:

- ❌ Apex method changes
- ❌ Adding @api/@wire properties
- ❌ Metadata changes
- ❌ New @salesforce imports
- ❌ Backend logic changes
- ❌ Integration testing

---

## 📊 Example: Local Dev Workflow

### Scenario: Fix Dropdown Styles

```bash
# 1. Start Local Dev
sf lightning dev app --name "Dynamic Queries"

# Browser opens at: https://your-org.develop.lightning.force.com

# 2. Edit CSS
# File: jtSearchableCombobox.css
# Change: .slds-dropdown { left: 0 !important; }
# To:     .slds-dropdown { /* removed */ }

# 3. Save (Cmd+S)
# → Browser updates instantly! ✨
# → See dropdown alignment fixed in real-time

# 4. Iterate more
# Edit padding, margins, colors
# Each save → instant preview

# 5. Happy with styles? Deploy
sf project deploy start

# 6. Test in org
sf apex run test --test-level RunLocalTests
npm run test:e2e

# 7. Commit
git add force-app/main/default/lwc/jtSearchableCombobox/
git commit -m "fix(styles): Align dropdown correctly"
```

**Time Saved:**

- Without Local Dev: 10 seconds per change × 20 changes = **200 seconds (3.3 min)**
- With Local Dev: 0 seconds per change × 20 changes = **0 seconds**

---

## 🎨 Perfect for Visual Validation

### Local Dev + E2E Videos = Perfect Combo

1. **Develop with Local Dev** (instant feedback)
2. **Deploy when ready**
3. **Run E2E tests** (record videos)
4. **Review videos** (validate final result)
5. **Manual test in org** (confirm)
6. **Commit**

This gives you:

- ✅ Fast iteration (Local Dev)
- ✅ Automated validation (E2E tests)
- ✅ Visual proof (E2E videos)
- ✅ Real-world confirmation (manual test)

---

## 🚨 Limitations to Know

### Not Supported in Local Dev:

- ❌ Testing with real Salesforce data
- ❌ Testing governor limits
- ❌ Testing USER_MODE security
- ❌ Testing sharing rules
- ❌ Integration with Tooling API
- ❌ Platform Cache testing

### Still Need Org Testing For:

- Security validation
- Data access validation
- Governor limit testing
- Real user scenarios
- Integration points

---

## 📝 Updated Workflow Summary

```
UI/Style Changes:
Local Dev → Instant preview → Deploy → Test in org → E2E → Commit

Backend/API Changes:
Deploy → Test Apex → E2E → Manual test → Commit

Both:
Fast iteration + Real org validation = Quality + Speed
```

---

## 🎯 Commands Reference

```bash
# Start Local Dev
sf lightning dev app

# Start with specific app
sf lightning dev app --name "Dynamic Queries"

# Preview on iOS
sf lightning dev app --device-type ios

# Preview on Android
sf lightning dev app --device-type android

# Preview single component (Winter '26+)
sf lightning dev component --name "jtQueryViewer"

# Stop Local Dev
# Press Ctrl+C in terminal
```

---

## 🔗 Learn More

- [Official Salesforce Blog](https://developer.salesforce.com/blogs/2024/10/develop-lwc-at-lightning-speed-with-the-new-local-dev-experience)
- [Documentation](https://developer.salesforce.com/docs/platform/lwc/guide/get-started-test-components.html)
- Trailhead: "Set Up Your Lightning Web Components Developer Tools"

---

**Local Dev = Game Changer for UI development! 🚀**


