/**
 * Generate @salesforce/label imports for a component
 */
const fs = require('fs');
const path = require('path');

const componentName = process.argv[2] || 'jtQueryViewer';
const labelsPath = path.join(__dirname, `../force-app/main/default/lwc/${componentName}/labels.js`);

if (!fs.existsSync(labelsPath)) {
  console.error(`❌ labels.js not found for ${componentName}`);
  process.exit(1);
}

const content = fs.readFileSync(labelsPath, 'utf-8');

// Extract English labels (keys)
const enMatch = content.match(/en:\s*\{([^}]+(?:\}[^}]+)*)\}/s);
if (!enMatch) {
  console.error('❌ Could not find "en" section');
  process.exit(1);
}

const enSection = enMatch[1];
const labelPattern = /(\w+):/g;
const labels = [];
let match;

while ((match = labelPattern.exec(enSection)) !== null) {
  labels.push(match[1]);
}

console.log(`\n// Import Custom Labels from Salesforce Translation Workbench (${labels.length} labels)`);
labels.forEach(label => {
  console.log(`import ${label} from "@salesforce/label/c.JT_${componentName}_${label}";`);
});

console.log(`\n  // Custom Labels object (${labels.length} labels)`);
console.log(`  labels = {`);
labels.forEach((label, idx) => {
  const comma = idx < labels.length - 1 ? ',' : '';
  console.log(`    ${label}${comma}`);
});
console.log(`  };`);

console.log(`\n✅ Generated ${labels.length} label imports for ${componentName}`);

