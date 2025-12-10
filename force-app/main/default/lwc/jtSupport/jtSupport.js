import { LightningElement } from "lwc";

// Import Custom Labels from Salesforce Translation Workbench
import title from "@salesforce/label/c.JT_jtSupport_title";
import welcomeTitle from "@salesforce/label/c.JT_jtSupport_welcomeTitle";
import welcomeMessage from "@salesforce/label/c.JT_jtSupport_welcomeMessage";
import githubIntegration from "@salesforce/label/c.JT_jtSupport_githubIntegration";
import githubDescription from "@salesforce/label/c.JT_jtSupport_githubDescription";
import githubRepo from "@salesforce/label/c.JT_jtSupport_githubRepo";
import reportBug from "@salesforce/label/c.JT_jtSupport_reportBug";
import reportBugDescription from "@salesforce/label/c.JT_jtSupport_reportBugDescription";
import reportBugButton from "@salesforce/label/c.JT_jtSupport_reportBugButton";
import viewIssues from "@salesforce/label/c.JT_jtSupport_viewIssues";
import viewIssuesDescription from "@salesforce/label/c.JT_jtSupport_viewIssuesDescription";
import viewIssuesButton from "@salesforce/label/c.JT_jtSupport_viewIssuesButton";
import featureRequest from "@salesforce/label/c.JT_jtSupport_featureRequest";
import featureRequestDescription from "@salesforce/label/c.JT_jtSupport_featureRequestDescription";
import featureRequestButton from "@salesforce/label/c.JT_jtSupport_featureRequestButton";
import additionalResources from "@salesforce/label/c.JT_jtSupport_additionalResources";
import documentation from "@salesforce/label/c.JT_jtSupport_documentation";
import documentationDescription from "@salesforce/label/c.JT_jtSupport_documentationDescription";
import tutorials from "@salesforce/label/c.JT_jtSupport_tutorials";
import tutorialsDescription from "@salesforce/label/c.JT_jtSupport_tutorialsDescription";
import community from "@salesforce/label/c.JT_jtSupport_community";
import communityDescription from "@salesforce/label/c.JT_jtSupport_communityDescription";
import directContact from "@salesforce/label/c.JT_jtSupport_directContact";
import contactEmail from "@salesforce/label/c.JT_jtSupport_contactEmail";
import responseTime from "@salesforce/label/c.JT_jtSupport_responseTime";

export default class JtSupport extends LightningElement {
  // Custom Labels (imported from Translation Workbench)
  labels = {
    title,
    welcomeTitle,
    welcomeMessage,
    githubIntegration,
    githubDescription,
    githubRepo,
    reportBug,
    reportBugDescription,
    reportBugButton,
    viewIssues,
    viewIssuesDescription,
    viewIssuesButton,
    featureRequest,
    featureRequestDescription,
    featureRequestButton,
    additionalResources,
    documentation,
    documentationDescription,
    tutorials,
    tutorialsDescription,
    community,
    communityDescription,
    directContact,
    contactEmail,
    responseTime
  };

  // GitHub repository URL
  githubIssuesUrl = "https://github.com/jterrats/JT_DynamicQueries/issues";
  githubNewIssueUrl =
    "https://github.com/jterrats/JT_DynamicQueries/issues/new";
  githubRepoUrl = "https://github.com/jterrats/JT_DynamicQueries";

  handleNavigateToIssues() {
    window.open(this.githubIssuesUrl, "_blank", "noopener,noreferrer");
  }

  handleNavigateToNewIssue() {
    window.open(this.githubNewIssueUrl, "_blank", "noopener,noreferrer");
  }

  handleNavigateToRepo() {
    window.open(this.githubRepoUrl, "_blank", "noopener,noreferrer");
  }
}
