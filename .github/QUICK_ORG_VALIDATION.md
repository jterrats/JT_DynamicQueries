# ⚡ Quick Org Validation Checklist

## For Binding Issue Debug

```bash
# 1. Open org
sf org open

# 2. Navigate to: App Launcher → Dynamic Queries → Query Viewer

# 3. Open Console (F12) - BEFORE anything else!

# 4. Select config: "Dynamic Input Test"

# 5. Enter values:
#    - accountType: Customer
#    - industry: Technology

# 6. Click "Execute Query"

# 7. Copy ALL console output

# 8. Report:
#    - Did it work? ✅/❌
#    - Console logs (paste)
#    - Error message (if any)
```

---

## Expected Console Output (Success)

```javascript
--- Configuration Selected ---
Parameters Extracted: [
  { name: "accountType", ... },
  { name: "industry", ... }
]

--- Parameter Changed ---
Parameter Name: accountType
Updated parameterValues: { accountType: "Customer" }

--- Parameter Changed ---
Parameter Name: industry
Updated parameterValues: { accountType: "Customer", industry: "Technology" }

--- Debugging Binding Issue ---
Current Parameter Values: {
  "accountType": "Customer",
  "industry": "Technology"
}
Final Bindings JSON: {"accountType":"Customer","industry":"Technology"}
--- End Debugging Binding Issue ---

✅ Query executed successfully
```

---

## If Error Occurs

**Copy this info:**

1. All console logs
2. Error toast message
3. Screenshot of UI
4. Config selected
5. Values entered

**Then we analyze and fix!**


