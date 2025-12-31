#!/usr/bin/env node
/**
 * Script to prepare static HTML files for local preview
 * Replaces Jekyll variables with static values
 */

const fs = require("fs");
const path = require("path");

const BASE_DIR = __dirname;
const BASEURL = ""; // Empty for root
const SITE_TITLE = "Dynamic Query Framework";
const SITE_DESCRIPTION =
  "Transform how you work with Salesforce data. Dynamic Query Framework is a comprehensive LWC development tool.";
const SITE_AUTHOR = "Jaime Terrats";
const SITE_GITHUB_USERNAME = "jterrats";
const SITE_REPOSITORY = "jterrats/JT_DynamicQueries";
const SITE_URL = "http://localhost:8000";
const SITE_LICENSE = "MIT";

// Languages from _config.yml
const SITE_LANGUAGES = [
  { code: "en", name: "English", flag: "🇺🇸" },
  { code: "es", name: "Español", flag: "🇲🇽" },
  { code: "fr", name: "Français", flag: "🇫🇷" },
  { code: "de", name: "Deutsch", flag: "🇩🇪" },
  { code: "pt", name: "Português", flag: "🇧🇷" },
  { code: "it", name: "Italiano", flag: "🇮🇹" },
  { code: "ja", name: "日本語", flag: "🇯🇵" },
  { code: "zh", name: "中文", flag: "🇨🇳" }
];

function replaceJekyllVars(content, pageData = {}) {
  // Replace simple variables first
  content = content
    .replace(/\{\{\s*site\.baseurl\s*\}\}/g, BASEURL)
    .replace(/\{\{\s*site\.title\s*\}\}/g, SITE_TITLE)
    .replace(/\{\{\s*site\.description\s*\}\}/g, SITE_DESCRIPTION)
    .replace(/\{\{\s*site\.author\s*\}\}/g, SITE_AUTHOR)
    .replace(/\{\{\s*site\.github_username\s*\}\}/g, SITE_GITHUB_USERNAME)
    .replace(/\{\{\s*site\.repository\s*\}\}/g, SITE_REPOSITORY)
    .replace(/\{\{\s*site\.url\s*\}\}/g, SITE_URL)
    .replace(/\{\{\s*page\.title\s*\}\}/g, pageData.title || "Home")
    .replace(
      /\{\{\s*page\.description\s*\}\}/g,
      pageData.description || SITE_DESCRIPTION
    )
    .replace(
      /\{\{\s*page\.og_title\s*\}\}/g,
      pageData.og_title || `${SITE_TITLE} - Beyond Simple SOQL Queries`
    )
    .replace(
      /\{\{\s*page\.og_description\s*\}\}/g,
      pageData.og_description || SITE_DESCRIPTION
    )
    .replace(
      /\{\{\s*page\.og_image\s*\}\}/g,
      pageData.og_image || "01-query-execution.gif"
    )
    .replace(/\{\{\s*page\.url\s*\}\}/g, pageData.url || "/")
    .replace(
      /\{\{\s*page\.lang\s*\|\s*default:\s*'en'\s*\}\}/g,
      pageData.lang || "en"
    )
    .replace(/\{\{\s*site\.license\s*\}\}/g, SITE_LICENSE);

  // Replace language loop (must be before includes to process nav.html correctly)
  content = content.replace(
    /\{\%\s*for\s+lang\s+in\s+site\.languages\s*\%\}([\s\S]*?)\{\%\s*endfor\s*\%\}/g,
    (match, loopContent) => {
      return SITE_LANGUAGES.map((lang) => {
        return loopContent
          .replace(/\{\{\s*lang\.code\s*\}\}/g, lang.code)
          .replace(/\{\{\s*lang\.name\s*\}\}/g, lang.name)
          .replace(/\{\{\s*lang\.flag\s*\}\}/g, lang.flag);
      }).join("\n");
    }
  );

  // Replace if/else blocks - title
  content = content.replace(
    /\{\%\s*if\s+page\.title\s*\%\}([^%]+)\{\%\s*else\s*\%\}([^%]+)\{\%\s*endif\s*\%\}/g,
    (match, ifPart, elsePart) => {
      return pageData.title
        ? ifPart
            .replace(/\{\{\s*page\.title\s*\}\}/g, pageData.title)
            .replace(/\{\{\s*site\.title\s*\}\}/g, SITE_TITLE)
        : elsePart.replace(/\{\{\s*site\.title\s*\}\}/g, SITE_TITLE);
    }
  );

  // Replace if/else blocks - description
  content = content.replace(
    /\{\%\s*if\s+page\.description\s*\%\}([^%]+)\{\%\s*else\s*\%\}([^%]+)\{\%\s*endif\s*\%\}/g,
    (match, ifPart, elsePart) => {
      return pageData.description
        ? ifPart.replace(
            /\{\{\s*page\.description\s*\}\}/g,
            pageData.description
          )
        : elsePart.replace(
            /\{\{\s*site\.description\s*\}\}/g,
            SITE_DESCRIPTION
          );
    }
  );

  // Replace if/else blocks - og_title
  content = content.replace(
    /\{\%\s*if\s+page\.og_title\s*\%\}([^%]+)\{\%\s*else\s*\%\}([^%]+)\{\%\s*endif\s*\%\}/g,
    (match, ifPart, elsePart) => {
      return pageData.og_title
        ? ifPart.replace(/\{\{\s*page\.og_title\s*\}\}/g, pageData.og_title)
        : elsePart.replace(/\{\{\s*site\.title\s*\}\}/g, SITE_TITLE);
    }
  );

  // Replace if/else blocks - og_description
  content = content.replace(
    /\{\%\s*if\s+page\.og_description\s*\%\}([^%]+)\{\%\s*else\s*\%\}([^%]+)\{\%\s*endif\s*\%\}/g,
    (match, ifPart, elsePart) => {
      return pageData.og_description
        ? ifPart.replace(
            /\{\{\s*page\.og_description\s*\}\}/g,
            pageData.og_description
          )
        : elsePart;
    }
  );

  // Replace if/else blocks - og_image
  content = content.replace(
    /\{\%\s*if\s+page\.og_image\s*\%\}([^%]+)\{\%\s*else\s*\%\}([^%]+)\{\%\s*endif\s*\%\}/g,
    (match, ifPart, elsePart) => {
      return pageData.og_image
        ? ifPart.replace(/\{\{\s*page\.og_image\s*\}\}/g, pageData.og_image)
        : elsePart;
    }
  );

  // Replace if blocks (without else) - page.url
  content = content.replace(
    /\{\%\s*if\s+page\.url\s*!=\s*["']\/["']\s+and\s+page\.url\s*!=\s*["']\/index\.html["']\s*\%\}([^%]+)\{\%\s*endif\s*\%\}/g,
    (match, content) => {
      return pageData.url &&
        pageData.url !== "/" &&
        pageData.url !== "/index.html"
        ? content
        : "";
    }
  );

  // Replace includes (must be last to avoid recursion issues)
  content = content.replace(/\{\%\s*include\s+head\.html\s*\%\}/g, () => {
    const headContent = fs.readFileSync(
      path.join(BASE_DIR, "_includes/head.html"),
      "utf8"
    );
    return replaceJekyllVars(headContent, pageData);
  });

  content = content.replace(/\{\%\s*include\s+nav\.html\s*\%\}/g, () => {
    const navContent = fs.readFileSync(
      path.join(BASE_DIR, "_includes/nav.html"),
      "utf8"
    );
    return replaceJekyllVars(navContent, pageData);
  });

  content = content.replace(/\{\%\s*include\s+footer\.html\s*\%\}/g, () => {
    const footerContent = fs.readFileSync(
      path.join(BASE_DIR, "_includes/footer.html"),
      "utf8"
    );
    return replaceJekyllVars(footerContent, pageData);
  });

  // Replace remaining page.url references
  content = content.replace(
    /\{\{\s*page\.url\s*\|\s*replace:\s*['"]index\.html['"],\s*['"]['"]\s*\}\}/g,
    pageData.url || "/"
  );

  return content;
}

function extractFrontMatter(content) {
  const frontMatterRegex = /^---\s*\n([\s\S]*?)\n---\s*\n([\s\S]*)$/;
  const match = content.match(frontMatterRegex);

  if (match) {
    const frontMatter = {};
    const yamlContent = match[1];
    const bodyContent = match[2];

    // Simple YAML parsing (basic key-value pairs)
    yamlContent.split("\n").forEach((line) => {
      const colonIndex = line.indexOf(":");
      if (colonIndex > 0) {
        const key = line.substring(0, colonIndex).trim();
        let value = line.substring(colonIndex + 1).trim();
        // Remove quotes if present
        value = value.replace(/^["']|["']$/g, "");
        frontMatter[key] = value;
      }
    });

    return { frontMatter, bodyContent };
  }

  return { frontMatter: {}, bodyContent: content };
}

console.log("🔧 Preparing static HTML files for local preview...");

// Process index.html
const indexPath = path.join(BASE_DIR, "index.html");
if (fs.existsSync(indexPath)) {
  console.log("   Processing index.html...");

  const indexContent = fs.readFileSync(indexPath, "utf8");
  const { frontMatter, bodyContent } = extractFrontMatter(indexContent);

  // Read layout
  const layoutPath = path.join(BASE_DIR, "_layouts/default.html");
  if (fs.existsSync(layoutPath)) {
    let layoutContent = fs.readFileSync(layoutPath, "utf8");

    // Replace content placeholder
    layoutContent = layoutContent.replace(
      /\{\{\s*content\s*\}\}/g,
      bodyContent
    );

    // Replace all Jekyll variables
    layoutContent = replaceJekyllVars(layoutContent, {
      title: frontMatter.title || "Home",
      description: frontMatter.description || SITE_DESCRIPTION,
      og_title:
        frontMatter.og_title || `${SITE_TITLE} - Beyond Simple SOQL Queries`,
      og_description: frontMatter.og_description || SITE_DESCRIPTION,
      og_image: frontMatter.og_image || "01-query-execution.gif",
      url: "/",
      lang: "en"
    });

    // Write static version
    const staticPath = path.join(BASE_DIR, "index-static.html");
    fs.writeFileSync(staticPath, layoutContent, "utf8");
    console.log("   ✅ Created index-static.html");
  }
}

console.log("✅ Static files prepared!");
console.log("");
console.log("📝 To preview:");
console.log("   python3 -m http.server 8000");
console.log("   Then open: http://localhost:8000/index-static.html");
