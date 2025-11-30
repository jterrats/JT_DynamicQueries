import { LightningElement } from 'lwc';
import { getDocumentation } from './docsContent';

export default class JtProjectDocs extends LightningElement {
    docs = getDocumentation();

    get sections() {
        return [
            { id: 'overview', title: this.docs.overview.title, icon: 'standard:document', ariaLabel: `Navigate to ${this.docs.overview.title} section` },
            { id: 'features', title: this.docs.features.title, icon: 'standard:endorsement', ariaLabel: `Navigate to ${this.docs.features.title} section` },
            { id: 'usage', title: this.docs.usage.title, icon: 'standard:instruction', ariaLabel: `Navigate to ${this.docs.usage.title} section` },
            { id: 'configuration', title: this.docs.configuration.title, icon: 'standard:settings', ariaLabel: `Navigate to ${this.docs.configuration.title} section` },
            { id: 'runAs', title: this.docs.runAs.title, icon: 'standard:user', ariaLabel: `Navigate to ${this.docs.runAs.title} section` },
            { id: 'metadata', title: this.docs.metadata.title, icon: 'standard:record', ariaLabel: `Navigate to ${this.docs.metadata.title} section` },
            { id: 'security', title: this.docs.security.title, icon: 'standard:shield', ariaLabel: `Navigate to ${this.docs.security.title} section` },
            { id: 'troubleshooting', title: this.docs.troubleshooting.title, icon: 'standard:question_feed', ariaLabel: `Navigate to ${this.docs.troubleshooting.title} section` },
            { id: 'api', title: this.docs.api.title, icon: 'standard:code_set', ariaLabel: `Navigate to ${this.docs.api.title} section` }
        ];
    }

    scrollToSection(event) {
        event.preventDefault();
        const sectionId = event.currentTarget.dataset.section;
        const section = this.template.querySelector(`[data-section="${sectionId}"]`);
        if (section) {
            section.scrollIntoView({ behavior: 'smooth', block: 'start' });

            // Set focus to section heading for screen readers
            const heading = section.querySelector('h2');
            if (heading) {
                heading.focus();
            }
        }
    }
}

