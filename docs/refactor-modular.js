#!/usr/bin/env node
/**
 * Refactor index.html to use external CSS and JS files
 * Preserves all content while making it modular
 */
const fs = require("fs");
const path = require("path");

const htmlPath = path.join(__dirname, "index.html");
const cssPath = path.join(__dirname, "css", "main.css");
const jsPath = path.join(__dirname, "js", "main.js");

console.log("📦 Refactoring index.html to modular structure...\n");

// Read original HTML
let html = fs.readFileSync(htmlPath, "utf-8");

// 1. Replace inline <style> with link to external CSS
console.log("1️⃣ Extracting CSS...");
const styleMatch = html.match(/<style>([\s\S]*?)<\/style>/);
if (styleMatch) {
  const cssContent = styleMatch[1].trim().replace(/^      /gm, "");
  fs.writeFileSync(cssPath, cssContent);
  console.log(`   ✅ Wrote ${cssContent.length} chars to css/main.css`);

  html = html.replace(
    /<style>[\s\S]*?<\/style>/,
    '\n    <!-- External Styles -->\n    <link rel="stylesheet" href="css/main.css" />'
  );
} else {
  console.log("   ⚠️  No <style> found, skipping");
}

// 2. Extract and replace inline <script> with external module
console.log("\n2️⃣ Extracting JavaScript...");
const scriptMatch = html.match(
  /<script>\s*\/\/ Language content[\s\S]*?<\/script>/
);
if (scriptMatch) {
  const scriptContent = scriptMatch[0]
    .replace(/<script>/, "")
    .replace(/<\/script>/, "")
    .trim();

  console.log(`   Found script block (${scriptContent.length} chars)`);

  // The script is already created, just replace in HTML
  html = html.replace(
    /<script>\s*\/\/ Language content[\s\S]*?<\/script>/,
    '\n    <!-- External Scripts (Module) -->\n    <script type="module" src="js/main.js"></script>'
  );
  console.log("   ✅ Replaced inline script with external module import");
} else {
  console.log("   ⚠️  No inline script found, skipping");
}

// 3. Write the refactored HTML
fs.writeFileSync(htmlPath, html);
console.log(`\n✅ Refactored index.html written (${html.length} chars)`);

// 4. Show stats
const originalSize = 1486; // lines before
const newSize = html.split("\n").length;
const reduction = ((1 - newSize / originalSize) * 100).toFixed(1);

console.log("\n📊 Refactoring Stats:");
console.log(`   Original: ~${originalSize} lines`);
console.log(`   New:      ${newSize} lines`);
console.log(`   Reduced:  ${reduction}% smaller`);
console.log(`\n✨ Modular structure created:`);
console.log(`   📄 index.html  - Structure only (~${newSize} lines)`);
console.log(`   🎨 css/main.css - All styles`);
console.log(`   🌍 js/translations.js - All translations (8 languages)`);
console.log(`   ⚙️  js/main.js - Logic and language switching`);
