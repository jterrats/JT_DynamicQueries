---
layout: default
title: Translation Workbench
permalink: /TRANSLATION_WORKBENCH/
---
# Translation Workbench Configuration

## Status: ✅ ENABLED

Translation Workbench has been enabled in this org and configured with the following languages.

## Supported Languages

| Language                | Code    | Status  | Translations      |
| ----------------------- | ------- | ------- | ----------------- |
| 🇺🇸 English (US)         | `en_US` | Default | Base (142 labels) |
| 🇪🇸 Spanish (Mexico)     | `es_MX` | Active  | 142 translations  |
| 🇫🇷 French               | `fr`    | Active  | 142 translations  |
| 🇩🇪 German               | `de`    | Active  | 142 translations  |
| 🇮🇹 Italian              | `it`    | Active  | 142 translations  |
| 🇯🇵 Japanese             | `ja`    | Active  | 142 translations  |
| 🇧🇷 Portuguese (Brazil)  | `pt_BR` | Active  | 142 translations  |
| 🇨🇳 Chinese (Simplified) | `zh_CN` | Active  | 142 translations  |

**Total:** 142 Custom Labels × 8 languages = 1,136 total label entries

## Setup Required (One-Time)

Translation Workbench must be enabled manually in each org:

1. **Setup → Translation Workbench → Translation Settings**
2. Check: ☑️ **Enable Translation Workbench**
3. Click **Add** to add each language above
4. **Save**

## Deployment

Once Translation Workbench is enabled in an org, deploy translations:

```bash
# Deploy Custom Labels (English base)
sf project deploy start --source-dir force-app/main/default/labels

# Deploy translations for all 7 languages
sf project deploy start --source-dir force-app/main/default/translations
```

## Files in This Directory

- `de.translation-meta.xml` - German translations (142)
- `es_MX.translation-meta.xml` - Spanish (Mexico) translations (142)
- `fr.translation-meta.xml` - French translations (142)
- `it.translation-meta.xml` - Italian translations (142)
- `ja.translation-meta.xml` - Japanese translations (142)
- `pt_BR.translation-meta.xml` - Portuguese (Brazil) translations (142)
- `zh_CN.translation-meta.xml` - Chinese (Simplified) translations (142)

## How Users Select Language

Users can select their preferred language:

1. **Setup → My Personal Information → Language & Time Zone**
2. Change **Language** to their preferred option
3. **Save** and refresh the page

All Custom Labels will automatically display in the selected language.

## Managing Translations

### View All Labels

**Setup → Custom Labels** → Filter by `JT_`

### Edit Translations

**Setup → Translation Workbench → Translate**

1. Select **Language** (e.g., Español)
2. Select **Setup Component**: Custom Labels
3. Find label (e.g., `JT_jtQueryViewer_executeQuery`)
4. Enter/edit translation
5. Click **Save**

### Export for Professional Translation

**Setup → Translation Workbench → Export**

1. Select **Language**
2. Select **Custom Labels**
3. Click **Export**
4. Send `.stf` file to translator
5. **Import** when translations are complete

## Coverage

All LWC components use these Custom Labels:

- `jtQueryViewer` - 89 labels
- `jtSupport` - 25 labels
- `jtDocumentation` - 30 labels
- `jtConfigModal` - 8 labels

**Total:** 142 unique labels with full translation coverage.

## Notes

- ⚠️ Translation Workbench settings (`Settings:Translation`) **cannot be retrieved** as metadata
- ⚠️ Must be enabled **manually in each org** via Setup UI
- ⚠️ This is a Salesforce platform limitation, not a project issue
- ✅ Once enabled, translations deploy normally via Metadata API

## References

- [Translation Workbench Overview](https://help.salesforce.com/s/articleView?id=sf.workbench_overview.htm)
- [Enable Translation Workbench](https://help.salesforce.com/s/articleView?id=sf.workbench_enable.htm)
- [Translate Custom Labels](https://help.salesforce.com/s/articleView?id=sf.cl_translate.htm)

---

Last Updated: 2025-12-05
Translation Workbench Version: Enabled in Production Org
