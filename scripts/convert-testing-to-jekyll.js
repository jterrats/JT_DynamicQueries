/**
 * Convert testing.html to Jekyll format with /testing/ permalink
 */

import { readFileSync, writeFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Read the current testing.html
const testingPath = join(__dirname, "../docs/testing.html");
const content = readFileSync(testingPath, "utf-8");

// Split by lines
const lines = content.split("\n");

// Find where the main content starts (after </head> and <body>) and ends (before </body>)
let startLine = -1;
let endLine = -1;

for (let i = 0; i < lines.length; i++) {
  // Content starts after the </head> tag
  if (lines[i].includes("</head>")) {
    // Skip <body> tag and find the first content
    for (let j = i + 1; j < lines.length; j++) {
      if (lines[j].trim() && !lines[j].includes("<body>")) {
        startLine = j;
        break;
      }
    }
  }
  // Content ends at the </body> tag
  if (lines[i].trim() === "</body>") {
    endLine = i - 1;
    break;
  }
}

if (startLine === -1 || endLine === -1) {
  console.error("❌ Could not find content boundaries");
  console.log(`startLine: ${startLine}, endLine: ${endLine}`);
  process.exit(1);
}

// Extract the main content
const mainContent = lines.slice(startLine, endLine + 1).join("\n");

// Create Jekyll file with front matter
const jekyllContent = `---
layout: default
title: Testing Methodology
permalink: /testing/
description: Comprehensive testing approach using E2E, EDD, TDD, and BDD methodologies. Learn how I ensure quality in the Dynamic Query Framework.
og_title: Testing with EDD - Dynamic Query Framework
og_description: Error-Driven Development as the core methodology. Combining EDD, E2E, TDD, and BDD for comprehensive test coverage and quality assurance.
---

${mainContent}
`;

// Write the new testing.html
writeFileSync(testingPath, jekyllContent, "utf-8");

console.log("✅ testing.html converted to Jekyll format!");
console.log(`📄 Extracted lines: ${startLine}-${endLine}`);
console.log(`📝 Content length: ${mainContent.split("\n").length} lines`);
console.log(`🔗 Permalink: /testing/`);
