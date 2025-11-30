import { LightningElement } from "lwc";
import { getLabels } from "./labels";

export default class JtSupport extends LightningElement {
  labels = getLabels();

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

