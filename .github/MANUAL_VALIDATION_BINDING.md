# 🔍 Manual Validation: Binding Issue Debugging

## Current Status

✅ **Deploy Successful:**
- All LWC components deployed
- `executeQueryPreview` method deployed
- Debug logging added to `jtQueryViewer.js`

✅ **Apex Tests: 99% Pass Rate (67/68)**
- ❌ 1 failing: `testLogUsageSearch` (unrelated to binding)

---

## 🎯 Goal: Debug Binding Issue

**Error:** `Key 'accountType' does not exist in the bindMap`

**Debugging Strategy:**
We've added extensive console logging to trace where `accountType` parameter gets lost.

---

## 📋 Manual Validation Steps

### Step 1: Login to Org

```bash
sf org open --target-org jaime.terrats@gmail.com
```

Or manually navigate to: `https://[your-org].lightning.force.com`

---

### Step 2: Navigate to Query Viewer

1. Click App Launcher (9 dots icon, top-left)
2. Search for "Dynamic Queries"
3. Click "Query Viewer" tab

---

### Step 3: Open Browser Console (CRITICAL)

**Before** doing anything else:

1. Press `F12` (or `Cmd+Option+I` on Mac)
2. Click "Console" tab
3. Clear console: Click trash icon or `Ctrl+L`

**Keep console visible while testing!**

---

### Step 4: Select Configuration with Parameters

1. In "Select Configuration" dropdown:
   - Type "Dynamic" or scroll
   - Select: **"Dynamic Input Test"** (has parameters)

2. **Watch console output immediately** - you should see:

```javascript
--- Configuration Selected ---
Selected Config: {
  value: "Dynamic_Input_Test",
  label: "Dynamic Input Test",
  baseQuery: "SELECT Id, Name, Type FROM Account WHERE Type = :accountType AND Industry = :industry",
  objectName: "Account",
  hasBindings: false,
  hasParameters: true
}
Parameters Extracted: [
  { name: "accountType", type: "String", required: true },
  { name: "industry", type: "String", required: true }
]
--- End Configuration Selected ---
```

---

### Step 5: Enter Parameter Values

1. You should see 2 input fields appear:
   - `accountType`
   - `industry`

2. **Enter values:**
   - `accountType`: `Customer`
   - `industry`: `Technology`

3. **Watch console after EACH input** - you should see:

```javascript
--- Parameter Changed ---
Parameter Name: accountType
Event Detail: { accountType: "Customer" }
All Values: { accountType: "Customer" }
Updated parameterValues: { accountType: "Customer" }
Current Parameters Array: [
  { name: "accountType", ... },
  { name: "industry", ... }
]
--- End Parameter Changed ---
```

---

### Step 6: Click "Execute Query"

1. Click the **"Execute Query"** button

2. **Watch console CAREFULLY** - you should see:

```javascript
--- Debugging Binding Issue ---
Selected Config: { ... }
Base Query: SELECT Id, Name, Type FROM Account WHERE Type = :accountType AND Industry = :industry
Raw Bindings from Config: null
Parameters from extractQueryParameters: [
  { "name": "accountType", ... },
  { "name": "industry", ... }
]
Current Parameter Values (from inputs): {
  "accountType": "Customer",
  "industry": "Technology"
}
Using User Parameter Values: {"accountType":"Customer","industry":"Technology"}
Final Bindings JSON to send to Apex: {"accountType":"Customer","industry":"Technology"}
Run As User ID: null
--- End Debugging Binding Issue ---
```

---

### Step 7: Check for Errors

**If binding works correctly:**
- ✅ Query executes successfully
- ✅ Results table shows data
- ✅ No error toast

**If binding fails (current bug):**
- ❌ Error toast appears: "Key 'accountType' does not exist in the bindMap"
- ❌ No results displayed

---

### Step 8: Copy Console Output

1. Right-click in console
2. Select "Save as..."
3. Or manually copy all relevant logs

**Send to developer:**
- All console output
- Screenshot of error (if any)
- Configuration selected
- Values entered

---

## 🔍 What We're Looking For

### Critical Questions:

1. **Is `parameterValues` populated correctly after input?**
   ```javascript
   Current Parameter Values (from inputs): {
     "accountType": "Customer",  // ✅ Should be here
     "industry": "Technology"    // ✅ Should be here
   }
   ```

2. **Is the JSON stringified correctly?**
   ```javascript
   Final Bindings JSON to send to Apex: {"accountType":"Customer","industry":"Technology"}
   ```
   - ✅ Should be valid JSON
   - ✅ Should have both keys
   - ❌ Should NOT be empty: `{}`
   - ❌ Should NOT have missing keys

3. **Which branch is taken?**
   ```javascript
   Using User Parameter Values: ...  // ✅ Should see this
   // OR
   Using Config Bindings: ...        // ❌ Should NOT see this for params
   ```

---

## 🐛 Common Issues to Check

### Issue #1: `parameterValues` is empty `{}`

**Console shows:**
```javascript
Current Parameter Values (from inputs): {}
```

**Diagnosis:** `handleParameterChange` not firing or not updating state

**Fix:** Check event binding in `c-jt-parameter-inputs`

---

### Issue #2: `parameterValues` has wrong structure

**Console shows:**
```javascript
Current Parameter Values (from inputs): {
  "param1": { "value": "Customer" }  // ❌ Nested object
}
```

**Diagnosis:** Event detail has wrong structure

**Fix:** Check `jtParameterInputs.js` event dispatch

---

### Issue #3: JSON stringify fails

**Console shows:**
```javascript
Final Bindings JSON to send to Apex: "[object Object]"
```

**Diagnosis:** `JSON.stringify()` not working

**Fix:** Check if `parameterValues` is actually an object

---

### Issue #4: Keys have wrong names

**Console shows:**
```javascript
Current Parameter Values (from inputs): {
  "accountType_input": "Customer"  // ❌ Wrong key name
}
```

**Diagnosis:** Key names don't match parameter names in query

**Fix:** Ensure `handleParameterChange` uses correct key names

---

## 📊 Expected Console Output (Full Example)

```javascript
// 1. Config Selection
--- Configuration Selected ---
Selected Config: {...}
Parameters Extracted: [...]
--- End Configuration Selected ---

// 2. First Parameter Input
--- Parameter Changed ---
Parameter Name: accountType
Event Detail: { accountType: "Customer" }
All Values: { accountType: "Customer" }
Updated parameterValues: { accountType: "Customer" }
--- End Parameter Changed ---

// 3. Second Parameter Input
--- Parameter Changed ---
Parameter Name: industry
Event Detail: { industry: "Technology" }
All Values: { accountType: "Customer", industry: "Technology" }
Updated parameterValues: { accountType: "Customer", industry: "Technology" }
--- End Parameter Changed ---

// 4. Query Execution
--- Debugging Binding Issue ---
Selected Config: {...}
Base Query: SELECT ... WHERE Type = :accountType AND Industry = :industry
Parameters from extractQueryParameters: [...]
Current Parameter Values (from inputs): {
  "accountType": "Customer",
  "industry": "Technology"
}
Using User Parameter Values: {"accountType":"Customer","industry":"Technology"}
Final Bindings JSON to send to Apex: {"accountType":"Customer","industry":"Technology"}
--- End Debugging Binding Issue ---

// 5. Success or Error
✅ Query executed successfully (if working)
❌ Error toast: Key does not exist (if broken)
```

---

## 🚀 Next Steps Based on Results

### If Console Shows Correct Data (but still fails):

**Problem:** Frontend is correct, Apex is receiving wrong data

**Actions:**
1. Check `JT_QueryViewerController.executeQuery()`
2. Add `System.debug()` in Apex
3. Check if `bindingsJson` parameter is received correctly
4. Verify `Database.queryWithBinds()` call

---

### If Console Shows Empty/Wrong Data:

**Problem:** Frontend is not capturing parameters correctly

**Actions:**
1. Check `jtParameterInputs.js` event dispatch
2. Check `jtQueryViewer.js` event handler
3. Verify `this.parameterValues` is being updated
4. Check for race conditions or timing issues

---

### If Console Shows No Logs:

**Problem:** Code not deployed or browser cache

**Actions:**
1. Hard refresh: `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)
2. Clear browser cache
3. Re-verify deployment
4. Check if correct component version is loaded

---

## 📝 Reporting Template

When reporting results, include:

```
Configuration: [Name of config selected]
Parameters Entered:
  - accountType: [value]
  - industry: [value]

Console Output:
[Paste all console logs here]

Error Message (if any):
[Screenshot or text of error]

Result:
[ ] Query executed successfully
[ ] Error occurred
[ ] No response
```

---

## 💡 Tips

1. **Always clear console before testing** to see fresh logs
2. **Test with simple configs first** (no parameters) to verify basic functionality
3. **Test with parameter configs** to isolate binding issue
4. **Take screenshots** at each step if errors occur
5. **Don't navigate away** until you've copied console logs

---

## ⚠️ Known Limitations

- Debug logs add ~100ms to query execution
- Console logs may be verbose
- Some logs may appear out of order due to async operations

---

## 🎯 Success Criteria

✅ All console logs appear as expected
✅ `parameterValues` contains correct keys and values
✅ JSON is properly stringified
✅ Query executes without errors
✅ Results are displayed

Once validated, we can:
1. Remove debug logging (performance)
2. Commit the fix
3. Run E2E tests
4. Deploy to production

