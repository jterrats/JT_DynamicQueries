/**
 * Dynamic Query Framework - Main JavaScript
 * Handles language switching and dynamic content updates
 */

import { content } from "./translations.js";

/**
 * Changes the page language by updating all translatable elements
 * @param {string} lang - Language code (en, es, fr, de, it, ja, pt, zh)
 */
function changeLanguage(lang) {
  const c = content[lang] || content.en;

  // Update title and tagline
  if (c.title) document.querySelector("h1").textContent = c.title;
  if (c.tagline) document.querySelector(".tagline").textContent = c.tagline;

  // Update hero section
  const heroSection = document.querySelector("#hero");
  if (heroSection) {
    if (c.heroTitle) heroSection.querySelector("h2").textContent = c.heroTitle;
    if (c.heroIntro) heroSection.querySelector("p").textContent = c.heroIntro;

    const heroCards = heroSection.querySelectorAll(
      "div[style*='background: white']"
    );
    if (heroCards.length >= 6) {
      if (c.heroCard1Title)
        heroCards[0].querySelector("h3").textContent = c.heroCard1Title;
      if (c.heroCard1Desc)
        heroCards[0].querySelector("p").textContent = c.heroCard1Desc;
      if (c.heroCard2Title)
        heroCards[1].querySelector("h3").textContent = c.heroCard2Title;
      if (c.heroCard2Desc)
        heroCards[1].querySelector("p").textContent = c.heroCard2Desc;
      if (c.heroCard3Title)
        heroCards[2].querySelector("h3").textContent = c.heroCard3Title;
      if (c.heroCard3Desc)
        heroCards[2].querySelector("p").textContent = c.heroCard3Desc;
      if (c.heroCard4Title)
        heroCards[3].querySelector("h3").textContent = c.heroCard4Title;
      if (c.heroCard4Desc)
        heroCards[3].querySelector("p").textContent = c.heroCard4Desc;
      if (c.heroCard5Title)
        heroCards[4].querySelector("h3").textContent = c.heroCard5Title;
      if (c.heroCard5Desc)
        heroCards[4].querySelector("p").textContent = c.heroCard5Desc;
      if (c.heroCard6Title)
        heroCards[5].querySelector("h3").textContent = c.heroCard6Title;
      if (c.heroCard6Desc)
        heroCards[5].querySelector("p").textContent = c.heroCard6Desc;
    }

    if (c.heroFooter) {
      const footerP = heroSection.querySelector("p[style*='margin-top: 2rem']");
      if (footerP) {
        footerP.innerHTML = `<strong>💡 ${c.heroFooter.split(": ")[0]}:</strong> ${c.heroFooter.split(": ")[1]}`;
      }
    }
  }

  // Update section titles
  if (c.testStatus)
    document.querySelector("#test-status h2").textContent = c.testStatus;
  if (c.demos) document.querySelector("#demos h2").textContent = c.demos;
  if (c.features)
    document.querySelector("#features h2").textContent = c.features;
  if (c.quickStart)
    document.querySelector("#installation h2").textContent = c.quickStart;
  if (c.documentation)
    document.querySelector("#docs h2").textContent = c.documentation;

  // Update test status cards
  const statusCards = document.querySelectorAll(".status-item h4");
  const statusTexts = document.querySelectorAll(".status-item p");
  if (statusCards.length >= 4 && statusTexts.length >= 4) {
    if (c.testsPassing) statusTexts[0].textContent = c.testsPassing;
    if (c.accessibility) statusCards[1].textContent = c.accessibility;
    if (c.githubPages) statusCards[2].textContent = c.githubPages;
    if (c.allDocsValid) statusTexts[2].textContent = c.allDocsValid;
    if (c.coverage) statusCards[3].textContent = c.coverage;
    if (c.codeCoverage) statusTexts[3].textContent = c.codeCoverage;
  }

  // Update GIF cards
  const gifCards = document.querySelectorAll(".gif-card-content h4");
  const gifDescs = document.querySelectorAll(".gif-card-content p");

  if (c.queryExecution && gifCards[0])
    gifCards[0].textContent = c.queryExecution;
  if (c.queryExecutionDesc && gifDescs[0])
    gifDescs[0].textContent = c.queryExecutionDesc;

  if (c.multipleViews && gifCards[1]) gifCards[1].textContent = c.multipleViews;
  if (c.multipleViewsDesc && gifDescs[1])
    gifDescs[1].textContent = c.multipleViewsDesc;

  if (c.treeView && gifCards[2]) gifCards[2].textContent = c.treeView;
  if (c.treeViewDesc && gifDescs[2]) gifDescs[2].textContent = c.treeViewDesc;

  if (c.largeDatasets && gifCards[3]) gifCards[3].textContent = c.largeDatasets;
  if (c.largeDatasetsDesc && gifDescs[3])
    gifDescs[3].textContent = c.largeDatasetsDesc;

  if (c.createConfig && gifCards[4]) gifCards[4].textContent = c.createConfig;
  if (c.createConfigDesc && gifDescs[4])
    gifDescs[4].textContent = c.createConfigDesc;

  if (c.runAsUser && gifCards[5]) gifCards[5].textContent = c.runAsUser;
  if (c.runAsUserDesc && gifDescs[5]) gifDescs[5].textContent = c.runAsUserDesc;

  // Update feature cards
  const featureCards = document.querySelectorAll(".feature-card");
  if (featureCards.length >= 6) {
    if (c.feature1Title)
      featureCards[0].querySelector("h4").textContent = c.feature1Title;
    if (c.feature1Desc)
      featureCards[0].querySelector("p").textContent = c.feature1Desc;
    if (c.feature2Title)
      featureCards[1].querySelector("h4").textContent = c.feature2Title;
    if (c.feature2Desc)
      featureCards[1].querySelector("p").textContent = c.feature2Desc;
    if (c.feature3Title)
      featureCards[2].querySelector("h4").textContent = c.feature3Title;
    if (c.feature3Desc)
      featureCards[2].querySelector("p").textContent = c.feature3Desc;
    if (c.feature4Title)
      featureCards[3].querySelector("h4").textContent = c.feature4Title;
    if (c.feature4Desc)
      featureCards[3].querySelector("p").textContent = c.feature4Desc;
    if (c.feature5Title)
      featureCards[4].querySelector("h4").textContent = c.feature5Title;
    if (c.feature5Desc)
      featureCards[4].querySelector("p").textContent = c.feature5Desc;
    if (c.feature6Title)
      featureCards[5].querySelector("h4").textContent = c.feature6Title;
    if (c.feature6Desc)
      featureCards[5].querySelector("p").textContent = c.feature6Desc;
  }

  // Update installation section
  const installationSection = document.querySelector("#installation");
  if (installationSection) {
    // Update intro paragraph
    const installationIntro = installationSection.querySelector(
      "p[style*='font-size: 1.1rem']"
    );
    if (installationIntro && c.deployIntro)
      installationIntro.textContent = c.deployIntro;

    // Update deploy section
    const deployTitle = installationSection.querySelector("h3");
    if (deployTitle && c.deployNow) deployTitle.textContent = c.deployNow;

    const deployButton = installationSection.querySelector(
      "a[href*='githubsfdeploy']"
    );
    if (deployButton && c.deployButton)
      deployButton.textContent = c.deployButton;

    const deploySubtext = installationSection.querySelector(
      "p[style*='color: rgba(255, 255, 255, 0.9)']"
    );
    if (deploySubtext && c.deploySubtext)
      deploySubtext.textContent = c.deploySubtext;

    // Update contributors section
    const contributorsTitle = installationSection.querySelector(
      "div[style*='background: #f8f9fa'] h3"
    );
    if (contributorsTitle && c.forContributors)
      contributorsTitle.textContent = c.forContributors;

    const contributorsDesc = installationSection.querySelector(
      "div[style*='background: #f8f9fa'] > p"
    );
    if (contributorsDesc && c.forContributorsDesc)
      contributorsDesc.textContent = c.forContributorsDesc;

    // Update prerequisites and installation in contributors section
    const contributorH4s = installationSection.querySelectorAll(
      "div[style*='background: #f8f9fa'] h4"
    );
    if (contributorH4s.length >= 2) {
      if (c.contributorPrerequisites)
        contributorH4s[0].textContent = c.contributorPrerequisites;
      if (c.contributorInstallation)
        contributorH4s[1].textContent = c.contributorInstallation;
    }

    // Update prerequisites list
    const prereqList = installationSection.querySelectorAll("ul li");
    if (prereqList.length >= 3) {
      if (c.prereq1) prereqList[0].textContent = c.prereq1;
      if (c.prereq2) prereqList[1].textContent = c.prereq2;
      if (c.prereq3) prereqList[2].textContent = c.prereq3;
    }
  }

  // Update CTA
  if (c.ready) document.querySelector(".cta-section h2").textContent = c.ready;
  if (c.readyDesc)
    document.querySelector(".cta-section p").textContent = c.readyDesc;

  const ctaButtons = document.querySelectorAll(".cta-button");
  if (ctaButtons.length >= 2) {
    if (c.viewGitHub) ctaButtons[0].textContent = c.viewGitHub;
    if (c.readDocs) ctaButtons[1].textContent = c.readDocs;
  }

  // Update footer
  const footerPs = document.querySelectorAll("footer p");
  if (footerPs.length >= 2) {
    if (c.footerText) {
      footerPs[0].innerHTML = `${c.footerText} <a href="https://github.com/jterrats" style="color: #667eea; text-decoration: none">Jaime Terrats</a>`;
    }
    if (c.license) footerPs[1].textContent = c.license;
  }

  // Save preference
  localStorage.setItem("preferred-language", lang);
}

// Make changeLanguage available globally for inline onchange handler
window.changeLanguage = changeLanguage;

// Load saved language preference on page load
window.addEventListener("DOMContentLoaded", () => {
  const savedLang = localStorage.getItem("preferred-language") || "en";
  document.getElementById("language").value = savedLang;
  if (savedLang !== "en") {
    changeLanguage(savedLang);
  }
});
