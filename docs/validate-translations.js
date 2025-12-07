#!/usr/bin/env node
/**
 * Validates that all translations in index.html have the same keys as English
 */
const fs = require("fs");
const path = require("path");

const indexPath = path.join(__dirname, "index.html");
const content = fs.readFileSync(indexPath, "utf-8");

// Extract the content object from the HTML
const contentMatch = content.match(/const content = \{([\s\S]*?)\n      \};/);
if (!contentMatch) {
  console.error("❌ Could not find content object in index.html");
  process.exit(1);
}

const contentStr = `{${contentMatch[1]}}`;

// Use eval to parse it (safe since we control the source)
const contentObj = eval(`(${contentStr})`);

const languages = Object.keys(contentObj);
const enKeys = Object.keys(contentObj.en).sort();

console.log("🌍 Translation Validation Report\n");
console.log(`📊 Base language (en) has ${enKeys.length} keys\n`);

let hasErrors = false;

languages.forEach((lang) => {
  if (lang === "en") return; // Skip English itself

  const langKeys = Object.keys(contentObj[lang]).sort();
  const missing = enKeys.filter((key) => !langKeys.includes(key));
  const extra = langKeys.filter((key) => !enKeys.includes(key));

  const coverage = ((langKeys.length / enKeys.length) * 100).toFixed(1);
  const icon = coverage === "100.0" ? "✅" : "⚠️";

  console.log(
    `${icon} ${lang.toUpperCase()}: ${langKeys.length}/${enKeys.length} keys (${coverage}%)`
  );

  if (missing.length > 0) {
    hasErrors = true;
    console.log(`   ❌ Missing ${missing.length} keys:`);
    missing.forEach((key) => console.log(`      - ${key}`));
  }

  if (extra.length > 0) {
    hasErrors = true;
    console.log(`   ⚠️  Extra ${extra.length} keys (not in English):`);
    extra.forEach((key) => console.log(`      - ${key}`));
  }

  console.log("");
});

if (hasErrors) {
  console.log(
    "❌ Translation validation FAILED - some languages are incomplete\n"
  );
  process.exit(1);
} else {
  console.log("✅ All translations are complete!\n");
  process.exit(0);
}
