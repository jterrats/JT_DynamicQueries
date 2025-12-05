# Enable Translation Workbench in Salesforce

## 🌍 Why Translation Workbench?

Your **142 Custom Labels** have been deployed successfully ✅  
But they're only in **English** 🇺🇸 right now.

To unlock **7 additional languages** (Español, Français, Deutsch, Italiano, 日本語, Português, 中文), you need to **enable Translation Workbench** in your org.

---

## 📋 Steps to Enable

### 1. Navigate to Translation Workbench Settings

1. Go to **Setup** (gear icon ⚙️)
2. In Quick Find, search: `Translation Workbench`
3. Click **Translation Workbench Settings**

### 2. Enable Translation Workbench

1. Check the box: **Enable Translation Workbench**
2. Click **Save**

### 3. Add Supported Languages

1. Still in Translation Workbench Settings
2. Click **Add** under "Supported Languages"
3. Add these languages (one by one):

| Language | Code | Flag |
|----------|------|------|
| Spanish (Mexico) | `es_MX` | 🇪🇸 |
| French | `fr` | 🇫🇷 |
| German | `de` | 🇩🇪 |
| Italian | `it` | 🇮🇹 |
| Japanese | `ja` | 🇯🇵 |
| Portuguese (Brazil) | `pt_BR` | 🇧🇷 |
| Chinese (Simplified) | `zh_CN` | 🇨🇳 |

4. Click **Save** after each

### 4. Deploy Translations

Once Translation Workbench is enabled, run:

\`\`\`bash
sf project deploy start --source-dir force-app/main/default/translations --wait 10
\`\`\`

This will deploy **7 translation files** with **~142 translations each** (994 total translations!).

---

## ✅ Verify Deployment

### View Custom Labels in Setup

1. **Setup → Custom Labels**
2. Filter by: `JT_`
3. You should see **142 labels**

### Test a Label in Different Languages

1. Click any label (e.g., `JT_jtQueryViewer_executeQuery`)
2. Click **Edit**
3. You'll see translations for all active languages

### Change Your User Language

1. **Setup → My Personal Information → Language & Time Zone**
2. Change **Language** to `Español`
3. Save and refresh
4. Your components will now show Spanish labels! 🇪🇸

---

## 📊 Translation Coverage

\`\`\`
🇺🇸 English:    142/142 (100%) ✅ DEPLOYED
🇪🇸 Español:    142/142 (100%) ⏳ Pending Translation Workbench
🇫🇷 Français:   142/142 (100%) ⏳ Pending Translation Workbench
🇩🇪 Deutsch:    142/142 (100%) ⏳ Pending Translation Workbench
🇮🇹 Italiano:   142/142 (100%) ⏳ Pending Translation Workbench
🇯🇵 日本語:      142/142 (100%) ⏳ Pending Translation Workbench
🇧🇷 Português:  142/142 (100%) ⏳ Pending Translation Workbench
🇨🇳 中文:        142/142 (100%) ⏳ Pending Translation Workbench
\`\`\`

---

## 🚀 After Enabling

Once Translation Workbench is enabled and translations are deployed:

1. ✅ Users can select their preferred language
2. ✅ All 142 labels will display in their language
3. ✅ You can manage translations via Salesforce UI
4. ✅ You can export/import .stf files for professional translators

---

## 🐛 Troubleshooting

### "Translation Workbench is not available"

Translation Workbench is available in:
- ✅ Developer Edition
- ✅ Enterprise Edition
- ✅ Unlimited Edition
- ✅ Performance Edition

Not available in:
- ❌ Professional Edition
- ❌ Group Edition
- ❌ Personal Edition

### "Can't find Translation Workbench in Setup"

Try searching: `Translate` or check under:
- **Setup → Company Settings → Translation Workbench**

### "Deployment failed: Not available for deploy"

This means Translation Workbench is not enabled yet. Follow steps above.

---

## 📚 Official Documentation

- [Enable Translation Workbench](https://help.salesforce.com/s/articleView?id=sf.workbench_overview.htm)
- [Add Supported Languages](https://help.salesforce.com/s/articleView?id=sf.workbench_add_languages.htm)
- [Translate Custom Labels](https://help.salesforce.com/s/articleView?id=sf.cl_translate.htm)

---

Generated: ${new Date().toISOString()}

