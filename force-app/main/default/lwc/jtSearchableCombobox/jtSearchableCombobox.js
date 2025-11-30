import { LightningElement, api, track } from 'lwc';

export default class JtSearchableCombobox extends LightningElement {
    @api label = '';
    @api placeholder = 'Type to search...';
    @api required = false;
    @api disabled = false;
    @api value = '';
    @api variant = 'standard'; // 'standard' or 'label-hidden'

    @track searchTerm = '';
    @track isOpen = false;
    @track highlightedIndex = -1;

    _options = [];

    @api
    get options() {
        return this._options;
    }

    set options(value) {
        this._options = value || [];
    }

    get filteredOptions() {
        if (!this.searchTerm) {
            return this._options;
        }

        const term = this.searchTerm.toLowerCase();
        return this._options.filter(opt =>
            opt.label.toLowerCase().includes(term) ||
            (opt.value && opt.value.toLowerCase().includes(term))
        );
    }

    get hasOptions() {
        return this.filteredOptions && this.filteredOptions.length > 0;
    }

    get selectedLabel() {
        if (!this.value) return '';
        const selected = this._options.find(opt => opt.value === this.value);
        return selected ? selected.label : '';
    }

    get showClearButton() {
        return this.value && !this.disabled;
    }

    get dropdownClass() {
        return `slds-dropdown slds-dropdown_length-5 slds-dropdown_fluid ${this.isOpen ? 'slds-is-open' : ''}`;
    }

    get comboboxClass() {
        return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${this.isOpen ? 'slds-is-open' : ''}`;
    }

    handleInputFocus(event) {
        this.isOpen = true;

        // Clear validation state when input receives focus
        if (this.required && event.target) {
            event.target.setCustomValidity('');
        }
    }

    handleInputChange(event) {
        this.searchTerm = event.target.value;
        this.isOpen = true;
        this.highlightedIndex = 0;

        // Clear validation state when user types
        if (this.required && event.target) {
            event.target.setCustomValidity('');
        }
    }

    handleInputKeyDown(event) {
        if (!this.isOpen) {
            if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
                this.isOpen = true;
                event.preventDefault();
                return;
            }
        }

        const options = this.filteredOptions;

        switch(event.key) {
            case 'ArrowDown':
                event.preventDefault();
                this.highlightedIndex = Math.min(this.highlightedIndex + 1, options.length - 1);
                this.scrollToHighlighted();
                break;
            case 'ArrowUp':
                event.preventDefault();
                this.highlightedIndex = Math.max(this.highlightedIndex - 1, 0);
                this.scrollToHighlighted();
                break;
            case 'Enter':
                event.preventDefault();
                if (this.highlightedIndex >= 0 && options[this.highlightedIndex]) {
                    this.selectOption(options[this.highlightedIndex]);
                }
                break;
            case 'Escape':
                this.isOpen = false;
                break;
        }
    }

    scrollToHighlighted() {
        setTimeout(() => {
            const highlighted = this.template.querySelector('.slds-has-focus');
            if (highlighted) {
                highlighted.scrollIntoView({ block: 'nearest' });
            }
        }, 0);
    }

    handleOptionClick(event) {
        const value = event.currentTarget.dataset.value;
        const option = this._options.find(opt => opt.value === value);
        if (option) {
            this.selectOption(option);
        }
    }

    selectOption(option) {
        this.value = option.value;
        this.searchTerm = option.label;
        this.isOpen = false;

        // Dispatch change event
        this.dispatchEvent(new CustomEvent('change', {
            detail: { value: option.value }
        }));
    }

    handleClear() {
        this.value = '';
        this.searchTerm = '';
        this.isOpen = false;

        // Dispatch change event
        this.dispatchEvent(new CustomEvent('change', {
            detail: { value: '' }
        }));

        // Focus back on input
        const input = this.template.querySelector('input');
        if (input) {
            input.focus();
        }
    }

    handleBlur() {
        // Delay to allow click on option
        setTimeout(() => {
            this.isOpen = false;

            // If no value selected, clear search term
            if (!this.value) {
                this.searchTerm = '';
            } else {
                // Restore selected label if user didn't select anything
                this.searchTerm = this.selectedLabel;
            }
        }, 200);
    }

    getOptionClass(index) {
        return `slds-listbox__item ${index === this.highlightedIndex ? 'slds-has-focus' : ''}`;
    }
}

