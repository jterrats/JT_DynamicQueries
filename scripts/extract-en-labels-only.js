/**
 * Extract ONLY English labels (no duplicates from other languages)
 */
const fs = require("fs");
const path = require("path");

const componentName = process.argv[2] || "jtQueryViewer";
const labelsPath = path.join(
  __dirname,
  `../force-app/main/default/lwc/${componentName}/labels.js`
);

const content = fs.readFileSync(labelsPath, "utf-8");

// Extract ONLY the en: { ... } section
const enRegex = /en:\s*\{([\s\S]*?)\n\s*\},\s*\n\s*(?:es|fr|de|it|ja|pt|zh):/;
const enMatch = content.match(enRegex);

if (!enMatch) {
  console.error("❌ Could not find English section");
  process.exit(1);
}

const enSection = enMatch[1];

// Extract label keys (ignore comments)
const labelPattern = /^\s*(\w+):/gm;
const labels = [];
let match;

while ((match = labelPattern.exec(enSection)) !== null) {
  labels.push(match[1]);
}

const uniqueLabels = Array.from(new Set(labels)).sort();

console.log(
  `// Import Custom Labels from Salesforce Translation Workbench (${uniqueLabels.length} labels)`
);
uniqueLabels.forEach((label) => {
  console.log(
    `import ${label}Label from "@salesforce/label/c.JT_${componentName}_${label}";`
  );
});

console.log(
  `\n  // Custom Labels (${uniqueLabels.length} labels from Translation Workbench)`
);
console.log(`  labels = {`);
uniqueLabels.forEach((label, idx) => {
  const comma = idx < uniqueLabels.length - 1 ? "," : "";
  console.log(`    ${label}: ${label}Label${comma}`);
});
console.log(`  };`);

console.log(
  `\n✅ Extracted ${uniqueLabels.length} unique labels from EN section`
);
