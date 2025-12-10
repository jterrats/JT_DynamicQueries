/**
 * Convert translations.js to translations.yml for Jekyll
 */

import { readFileSync, writeFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Read the translations.js file
const translationsPath = join(__dirname, "../docs/js/translations.js");
const translationsContent = readFileSync(translationsPath, "utf-8");

// Extract the content object using a simple eval in a controlled context
const contentMatch = translationsContent.match(
  /export const content = ({[\s\S]*});?\s*$/
);
if (!contentMatch) {
  console.error("❌ Could not extract content object");
  process.exit(1);
}

// Parse the JS object
const content = eval(`(${contentMatch[1]})`);

// Convert to YAML manually (to preserve structure and formatting)
function objectToYAML(obj, indent = 0) {
  const spaces = "  ".repeat(indent);
  let yaml = "";

  for (const [key, value] of Object.entries(obj)) {
    if (typeof value === "object" && !Array.isArray(value)) {
      yaml += `${spaces}${key}:\n`;
      yaml += objectToYAML(value, indent + 1);
    } else if (typeof value === "string") {
      // Escape quotes and use quotes if needed
      const needsQuotes =
        value.includes(":") || value.includes("#") || value.includes("\n");
      const escaped = value.replace(/"/g, '\\"');
      yaml += `${spaces}${key}: ${needsQuotes ? `"${escaped}"` : escaped}\n`;
    } else {
      yaml += `${spaces}${key}: ${value}\n`;
    }
  }

  return yaml;
}

// Generate YAML
const yaml = `# Dynamic Query Framework - Translations
# 8 languages: en, es, fr, de, it, ja, pt, zh
# This file is used by Jekyll for i18n support

${objectToYAML(content)}`;

// Write to _data/translations.yml
const outputPath = join(__dirname, "../docs/_data/translations.yml");
writeFileSync(outputPath, yaml, "utf-8");

console.log("✅ Translations converted successfully!");
console.log(`📄 Output: ${outputPath}`);
console.log(`📊 Languages: ${Object.keys(content).length}`);
console.log(`📝 Keys per language: ${Object.keys(content.en).length}`);
