# Custom Labels Migration Guide

## Overview

This project has been migrated from JavaScript `labels.js` files to Salesforce **Custom Labels** with **Translation Workbench** support.

## Benefits

✅ **Centralized Management** - All translations in one place
✅ **Salesforce UI** - Non-developers can translate
✅ **Export/Import** - Send to professional translators
✅ **Version Control** - Part of metadata
✅ **Consistency** - Same label across components

## Languages Supported

- 🇺🇸 **English** (`en_US`)
- 🇪🇸 **Español** (`es_MX`)
- 🇫🇷 **Français** (`fr`)
- 🇩🇪 **Deutsch** (`de`)
- 🇮🇹 **Italiano** (`it`)
- 🇯🇵 **日本語** (`ja`)
- 🇧🇷 **Português** (`pt_BR`)
- 🇨🇳 **中文** (`zh_CN`)

## Custom Labels Created

Total: **144** labels

### By Component

#### jtDocumentation (30 labels)

Example imports:

```javascript
import welcomeSubtitleLabel from "@salesforce/label/c.JT_jtDocumentation_welcomeSubtitle";
import frameworkPhilosophyLabel from "@salesforce/label/c.JT_jtDocumentation_frameworkPhilosophy";
import philosophyTextLabel from "@salesforce/label/c.JT_jtDocumentation_philosophyText";
// ... 27 more
```

#### jtQueryViewer (89 labels)

Example imports:

```javascript
import labelRequiredLabel from "@salesforce/label/c.JT_jtQueryViewer_labelRequired";
import labelTooLongLabel from "@salesforce/label/c.JT_jtQueryViewer_labelTooLong";
import developerNameRequiredLabel from "@salesforce/label/c.JT_jtQueryViewer_developerNameRequired";
// ... 86 more
```

#### jtSupport (25 labels)

Example imports:

```javascript
import welcomeTitleLabel from "@salesforce/label/c.JT_jtSupport_welcomeTitle";
import titleLabel from "@salesforce/label/c.JT_jtSupport_title";
import welcomeMessageLabel from "@salesforce/label/c.JT_jtSupport_welcomeMessage";
// ... 22 more
```

## How to Update LWC Components

### Before (labels.js):

```javascript
import { getLabel } from "./labels";

export default class MyComponent extends LightningElement {
  label = {
    executeQuery: getLabel("executeQuery"),
    cancel: getLabel("cancel")
  };
}
```

### After (Custom Labels):

```javascript
import executeQueryLabel from "@salesforce/label/c.JT_jtQueryViewer_executeQuery";
import cancelLabel from "@salesforce/label/c.JT_jtQueryViewer_cancel";

export default class MyComponent extends LightningElement {
  label = {
    executeQuery: executeQueryLabel,
    cancel: cancelLabel
  };
}
```

## Translation Management

### Add New Translation

1. Go to **Setup → Translation Workbench → Translate**
2. Select language (e.g., Español)
3. Select **Custom Labels**
4. Find label (e.g., `JT_jtQueryViewer_executeQuery`)
5. Enter translation
6. Click **Save**

### Export for Professional Translation

1. Go to **Setup → Translation Workbench → Export**
2. Select language
3. Select **Custom Labels**
4. Click **Export**
5. Send .stf file to translator
6. Import when done

### View All Labels

Setup → Custom Labels → filter by `JT_`

## Migration Status

- ✅ Custom Labels created
- ✅ Translation files created
- ⏳ LWC components (manual update needed)
- ⏳ Deploy to org
- ⏳ Test in all languages

## Files Created

- `force-app/main/default/labels/CustomLabels.labels-meta.xml` (144 labels)
- `force-app/main/default/translations/en_US.translation-meta.xml`
- `force-app/main/default/translations/es_MX.translation-meta.xml`
- `force-app/main/default/translations/fr.translation-meta.xml`
- `force-app/main/default/translations/de.translation-meta.xml`
- `force-app/main/default/translations/it.translation-meta.xml`
- `force-app/main/default/translations/ja.translation-meta.xml`
- `force-app/main/default/translations/pt_BR.translation-meta.xml`
- `force-app/main/default/translations/zh_CN.translation-meta.xml`

## Next Steps

1. **Review** generated files for accuracy
2. **Deploy** to your org: `sf project deploy start --source-dir force-app/main/default/labels force-app/main/default/translations`
3. **Update** LWC components to import from `@salesforce/label`
4. **Test** in all languages
5. **Remove** old labels.js files

---

Generated on 2025-12-05T17:24:44.976Z
