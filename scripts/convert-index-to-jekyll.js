/**
 * Convert index.html to Jekyll format
 * Extracts main content (without header/footer) and adds front matter
 */

import { readFileSync, writeFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Read the current index.html
const indexPath = join(__dirname, "../docs/index.html");
const content = readFileSync(indexPath, "utf-8");

// Split by lines
const lines = content.split("\n");

// Find where the main content starts (after header) and ends (before footer)
let startLine = -1;
let endLine = -1;

for (let i = 0; i < lines.length; i++) {
  // Main content starts at the Hero Section comment
  if (lines[i].includes("<!-- Hero Section -->")) {
    startLine = i;
  }
  // Main content ends at the footer tag
  if (lines[i].includes("<footer>")) {
    endLine = i - 1;
    break;
  }
}

if (startLine === -1 || endLine === -1) {
  console.error("❌ Could not find content boundaries");
  process.exit(1);
}

// Extract the main content
const mainContent = lines.slice(startLine, endLine + 1).join("\n");

// Create Jekyll file with front matter
const jekyllContent = `---
layout: default
title: Home
permalink: /
description: Transform how you work with Salesforce data. Dynamic Query Framework is a comprehensive LWC development tool with pre-configured queries, Run As User testing, tree view relationships, and enterprise-scale performance (50k+ records).
og_title: Dynamic Query Framework - Beyond Simple SOQL Queries
og_description: A comprehensive Salesforce development framework that transforms how developers interact with data. Pre-configured queries, Run As User testing, tree view relationships, and enterprise-scale performance.
og_image: 01-query-execution.gif
---

${mainContent}
`;

// Write the new index.html
writeFileSync(indexPath, jekyllContent, "utf-8");

console.log("✅ index.html converted to Jekyll format!");
console.log(`📄 Extracted lines: ${startLine}-${endLine}`);
console.log(`📝 Content length: ${mainContent.split("\n").length} lines`);
