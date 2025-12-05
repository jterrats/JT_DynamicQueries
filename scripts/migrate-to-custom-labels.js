/**
 * @description Migrate labels.js to Salesforce Custom Labels + Translation Workbench
 * @author Jaime Terrats
 * @date 2025-12-05
 * 
 * Extracts all labels from labels.js files and generates:
 * 1. CustomLabels.labels-meta.xml (English base labels)
 * 2. Translation files for 8 languages
 * 3. Migration guide for updating LWC imports
 */

const fs = require('fs');
const path = require('path');

const LABELS_DIR = path.join(__dirname, '../force-app/main/default/lwc');
const OUTPUT_DIR = path.join(__dirname, '../force-app/main/default/labels');
const TRANSLATIONS_DIR = path.join(__dirname, '../force-app/main/default/translations');

// Supported languages
const LANGUAGES = {
  'en_US': { name: 'English', flag: '🇺🇸' },
  'es_MX': { name: 'Español', flag: '🇪🇸' },
  'fr': { name: 'Français', flag: '🇫🇷' },
  'de': { name: 'Deutsch', flag: '🇩🇪' },
  'it': { name: 'Italiano', flag: '🇮🇹' },
  'ja': { name: '日本語', flag: '🇯🇵' },
  'pt_BR': { name: 'Português', flag: '🇧🇷' },
  'zh_CN': { name: '中文', flag: '🇨🇳' }
};

// Create output directories
[OUTPUT_DIR, TRANSLATIONS_DIR].forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

/**
 * Extract labels from a labels.js file
 */
function extractLabelsFromFile(filePath, componentName) {
  console.log(`\n📖 Reading: ${path.basename(path.dirname(filePath))}/${path.basename(filePath)}`);
  
  const content = fs.readFileSync(filePath, 'utf-8');
  const labels = {};
  
  // Extract LABELS object using regex
  const labelsMatch = content.match(/const LABELS = \{([\s\S]*?)\};/);
  if (!labelsMatch) {
    console.log('   ⚠️  No LABELS object found, skipping');
    return labels;
  }
  
  // Parse each language section
  const languages = ['en', 'es', 'fr', 'de', 'it', 'ja', 'pt', 'zh'];
  
  languages.forEach(lang => {
    const langRegex = new RegExp(`${lang}\\s*:\\s*\\{([\\s\\S]*?)\\}(?=,\\s*(?:${languages.join('|')}):|\\s*\\};)`, 'g');
    const langMatch = labelsMatch[1].match(langRegex);
    
    if (langMatch) {
      langMatch.forEach(match => {
        const labelPattern = /(\w+):\s*["']([^"']*?)["']/g;
        let labelMatch;
        
        while ((labelMatch = labelPattern.exec(match)) !== null) {
          const key = labelMatch[1];
          const value = labelMatch[2];
          
          if (!labels[key]) {
            labels[key] = {
              component: componentName,
              en: '',
              es: '',
              fr: '',
              de: '',
              it: '',
              ja: '',
              pt: '',
              zh: ''
            };
          }
          
          labels[key][lang] = value;
        }
      });
    }
  });
  
  const count = Object.keys(labels).length;
  console.log(`   ✅ Extracted ${count} labels`);
  
  return labels;
}

/**
 * Find all labels.js files
 */
function findLabelsFiles() {
  const components = fs.readdirSync(LABELS_DIR);
  const labelsFiles = [];
  
  components.forEach(comp => {
    const labelsPath = path.join(LABELS_DIR, comp, 'labels.js');
    if (fs.existsSync(labelsPath)) {
      labelsFiles.push({ path: labelsPath, component: comp });
    }
  });
  
  return labelsFiles;
}

/**
 * Generate Custom Labels XML
 */
function generateCustomLabelsXML(allLabels) {
  console.log('\n📝 Generating CustomLabels.labels-meta.xml...');
  
  let xml = `<?xml version="1.0" encoding="UTF-8"?>
<CustomLabels xmlns="http://soap.sforce.com/2006/04/metadata">
`;

  Object.entries(allLabels).sort().forEach(([key, data]) => {
    // Skip labels with no English value
    if (!data.en || data.en.trim() === '') {
      console.log(`   ⚠️  Skipping ${key} (no English value)`);
      return;
    }
    
    const fullName = `JT_${data.component}_${key}`;
    const value = data.en.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    const shortDescription = `${data.component} - ${key}`;
    
    xml += `    <labels>
        <fullName>${fullName}</fullName>
        <language>en_US</language>
        <protected>false</protected>
        <shortDescription>${shortDescription}</shortDescription>
        <value>${value}</value>
    </labels>
`;
  });

  xml += `</CustomLabels>
`;

  const outputPath = path.join(OUTPUT_DIR, 'CustomLabels.labels-meta.xml');
  fs.writeFileSync(outputPath, xml);
  
  const count = Object.keys(allLabels).length;
  console.log(`   ✅ Created ${count} Custom Labels`);
  console.log(`   📁 ${outputPath}`);
  
  return count;
}

/**
 * Generate translation files for each language
 */
function generateTranslations(allLabels) {
  console.log('\n🌍 Generating translation files...');
  
  const langMap = {
    'es': 'es_MX',
    'fr': 'fr',
    'de': 'de',
    'it': 'it',
    'ja': 'ja',
    'pt': 'pt_BR',
    'zh': 'zh_CN'
  };
  
  Object.entries(langMap).forEach(([shortLang, salesforceLang]) => {
    const translationFile = path.join(TRANSLATIONS_DIR, `${salesforceLang}.translation-meta.xml`);
    
    let xml = `<?xml version="1.0" encoding="UTF-8"?>
<Translations xmlns="http://soap.sforce.com/2006/04/metadata">
    <customLabels>
`;

    let translatedCount = 0;
    Object.entries(allLabels).sort().forEach(([key, data]) => {
      const fullName = `JT_${data.component}_${key}`;
      const translation = (data[shortLang] || data.en || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
      
      if (translation) {
        xml += `        <name>${fullName}</name>
        <label>${translation}</label>
`;
        translatedCount++;
      }
    });

    xml += `    </customLabels>
</Translations>
`;

    fs.writeFileSync(translationFile, xml);
    const langInfo = LANGUAGES[salesforceLang];
    console.log(`   ✅ ${langInfo.flag} ${langInfo.name} (${salesforceLang}): ${translatedCount} translations`);
  });
}

/**
 * Generate migration guide
 */
function generateMigrationGuide(allLabels) {
  console.log('\n📚 Generating migration guide...');
  
  let guide = `# Custom Labels Migration Guide

## Overview

This project has been migrated from JavaScript \`labels.js\` files to Salesforce **Custom Labels** with **Translation Workbench** support.

## Benefits

✅ **Centralized Management** - All translations in one place
✅ **Salesforce UI** - Non-developers can translate
✅ **Export/Import** - Send to professional translators
✅ **Version Control** - Part of metadata
✅ **Consistency** - Same label across components

## Languages Supported

${Object.entries(LANGUAGES).map(([code, info]) => `- ${info.flag} **${info.name}** (\`${code}\`)`).join('\n')}

## Custom Labels Created

Total: **${Object.keys(allLabels).length}** labels

### By Component

`;

  // Group by component
  const byComponent = {};
  Object.entries(allLabels).forEach(([key, data]) => {
    if (!byComponent[data.component]) {
      byComponent[data.component] = [];
    }
    byComponent[data.component].push(key);
  });

  Object.entries(byComponent).sort().forEach(([component, keys]) => {
    guide += `\n#### ${component} (${keys.length} labels)\n\n`;
    guide += `Example imports:\n\n\`\`\`javascript\n`;
    keys.slice(0, 3).forEach(key => {
      guide += `import ${key}Label from '@salesforce/label/c.JT_${component}_${key}';\n`;
    });
    guide += `// ... ${keys.length - 3} more\n\`\`\`\n`;
  });

  guide += `\n## How to Update LWC Components

### Before (labels.js):

\`\`\`javascript
import { getLabel } from './labels';

export default class MyComponent extends LightningElement {
  label = {
    executeQuery: getLabel('executeQuery'),
    cancel: getLabel('cancel')
  };
}
\`\`\`

### After (Custom Labels):

\`\`\`javascript
import executeQueryLabel from '@salesforce/label/c.JT_jtQueryViewer_executeQuery';
import cancelLabel from '@salesforce/label/c.JT_jtQueryViewer_cancel';

export default class MyComponent extends LightningElement {
  label = {
    executeQuery: executeQueryLabel,
    cancel: cancelLabel
  };
}
\`\`\`

## Translation Management

### Add New Translation

1. Go to **Setup → Translation Workbench → Translate**
2. Select language (e.g., Español)
3. Select **Custom Labels**
4. Find label (e.g., \`JT_jtQueryViewer_executeQuery\`)
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

Setup → Custom Labels → filter by \`JT_\`

## Migration Status

- ✅ Custom Labels created
- ✅ Translation files created
- ⏳ LWC components (manual update needed)
- ⏳ Deploy to org
- ⏳ Test in all languages

## Files Created

- \`force-app/main/default/labels/CustomLabels.labels-meta.xml\` (${Object.keys(allLabels).length} labels)
${Object.keys(LANGUAGES).map(lang => `- \`force-app/main/default/translations/${lang}.translation-meta.xml\``).join('\n')}

## Next Steps

1. **Review** generated files for accuracy
2. **Deploy** to your org: \`sf project deploy start --source-dir force-app/main/default/labels force-app/main/default/translations\`
3. **Update** LWC components to import from \`@salesforce/label\`
4. **Test** in all languages
5. **Remove** old labels.js files

---

Generated on ${new Date().toISOString()}
`;

  const guidePath = path.join(__dirname, 'TRANSLATION_WORKBENCH_MIGRATION.md');
  fs.writeFileSync(guidePath, guide);
  console.log(`   ✅ Migration guide created`);
  console.log(`   📁 ${guidePath}`);
}

/**
 * Main execution
 */
(async () => {
  console.log('🌍 Custom Labels & Translation Workbench Migration');
  console.log('='.repeat(60));
  
  // Find all labels.js files
  const labelsFiles = findLabelsFiles();
  console.log(`\n📂 Found ${labelsFiles.length} components with labels.js:`);
  labelsFiles.forEach(f => console.log(`   - ${f.component}`));
  
  // Extract all labels
  const allLabels = {};
  labelsFiles.forEach(({ path: filePath, component }) => {
    const labels = extractLabelsFromFile(filePath, component);
    Object.assign(allLabels, labels);
  });
  
  console.log(`\n📊 Total unique labels: ${Object.keys(allLabels).length}`);
  
  // Generate Custom Labels XML
  const labelCount = generateCustomLabelsXML(allLabels);
  
  // Generate translations
  generateTranslations(allLabels);
  
  // Generate migration guide
  generateMigrationGuide(allLabels);
  
  console.log('\n✨ Migration files created successfully!');
  console.log('\n📋 Next Steps:');
  console.log('1. Review generated files in force-app/main/default/labels/ and translations/');
  console.log('2. Deploy: sf project deploy start --source-dir force-app/main/default/labels force-app/main/default/translations');
  console.log('3. Update LWC components to use @salesforce/label imports');
  console.log('4. Test in all 8 languages');
  console.log('5. Remove old labels.js files');
  console.log('\n📖 See scripts/TRANSLATION_WORKBENCH_MIGRATION.md for complete guide');
})();

