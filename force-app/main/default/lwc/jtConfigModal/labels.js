/**
 * @description Custom labels for jtConfigModal i18n support
 * @author Jaime Terrats
 * @date 2025-12-02
 */

const LOCALE = Intl.DateTimeFormat().resolvedOptions().locale || "en-US";
const LANG = LOCALE.split("-")[0];

const LABELS = {
  en: {
    // Validation Messages
    labelRequired: "Label is required",
    labelTooLong: "Label must be 40 characters or less",
    developerNameRequired: "Developer Name is required",
    developerNameTooLong: "Developer Name must be 40 characters or less",
    developerNameInvalidChars: "Only letters, numbers, and underscores allowed",
    developerNameMustStartWithLetter: "Must start with a letter",
    developerNameCannotEndWithUnderscore: "Cannot end with an underscore",
    developerNameNoConsecutiveUnderscores:
      "Cannot contain consecutive underscores"
  },
  es: {
    // Validation Messages
    labelRequired: "La etiqueta es requerida",
    labelTooLong: "La etiqueta debe tener 40 caracteres o menos",
    developerNameRequired: "El nombre de desarrollador es requerido",
    developerNameTooLong:
      "El nombre de desarrollador debe tener 40 caracteres o menos",
    developerNameInvalidChars:
      "Solo se permiten letras, números y guiones bajos",
    developerNameMustStartWithLetter: "Debe comenzar con una letra",
    developerNameCannotEndWithUnderscore: "No puede terminar con guión bajo",
    developerNameNoConsecutiveUnderscores:
      "No puede contener guiones bajos consecutivos"
  }
};

export function getLabels() {
  return LABELS[LANG] || LABELS.en;
}

