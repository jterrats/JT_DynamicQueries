/**
 * @description Custom labels for Audit History i18n support
 * @author Jaime Terrats
 * @date 2025-11-30
 */

const LOCALE = Intl.DateTimeFormat().resolvedOptions().locale || 'en-US';
const LANG = LOCALE.split('-')[0];

const LABELS = {
    'en': {
        title: 'Production Editing Audit History',
        refresh: 'Refresh',
        infoMessage: 'This log tracks all changes to the "Allow Production Editing" setting. Each entry shows who enabled or disabled metadata editing in production environments.',
        dateTime: 'Date/Time',
        action: 'Action',
        changedBy: 'Changed By',
        username: 'Username',
        orgType: 'Org Type',
        ipAddress: 'IP Address',
        showing: 'Showing',
        mostRecent: 'most recent change(s)',
        noLogsTitle: 'No audit logs yet',
        noLogsMessage: 'Changes to production editing settings will appear here',
        errorLoading: 'Error loading audit logs',
        enabled: 'Enabled',
        disabled: 'Disabled'
    },
    'es': {
        title: 'Historial de Auditoría de Edición en Producción',
        refresh: 'Actualizar',
        infoMessage: 'Este registro rastrea todos los cambios en la configuración "Permitir Edición en Producción". Cada entrada muestra quién habilitó o deshabilitó la edición de metadatos en entornos de producción.',
        dateTime: 'Fecha/Hora',
        action: 'Acción',
        changedBy: 'Modificado Por',
        username: 'Nombre de Usuario',
        orgType: 'Tipo de Org',
        ipAddress: 'Dirección IP',
        showing: 'Mostrando',
        mostRecent: 'cambio(s) más reciente(s)',
        noLogsTitle: 'Aún no hay registros de auditoría',
        noLogsMessage: 'Los cambios en la configuración de edición en producción aparecerán aquí',
        errorLoading: 'Error al cargar registros de auditoría',
        enabled: 'Habilitado',
        disabled: 'Deshabilitado'
    },
    'fr': {
        title: 'Historique d\'Audit d\'Édition de Production',
        refresh: 'Actualiser',
        infoMessage: 'Ce journal suit tous les changements du paramètre "Autoriser l\'édition de production". Chaque entrée montre qui a activé ou désactivé l\'édition de métadonnées dans les environnements de production.',
        dateTime: 'Date/Heure',
        action: 'Action',
        changedBy: 'Modifié Par',
        username: 'Nom d\'utilisateur',
        orgType: 'Type d\'Org',
        ipAddress: 'Adresse IP',
        showing: 'Affichage',
        mostRecent: 'changement(s) le(s) plus récent(s)',
        noLogsTitle: 'Aucun journal d\'audit pour le moment',
        noLogsMessage: 'Les modifications des paramètres d\'édition de production apparaîtront ici',
        errorLoading: 'Erreur lors du chargement des journaux d\'audit',
        enabled: 'Activé',
        disabled: 'Désactivé'
    },
    'de': {
        title: 'Prüfprotokoll für Produktionsbearbeitung',
        refresh: 'Aktualisieren',
        infoMessage: 'Dieses Protokoll verfolgt alle Änderungen an der Einstellung "Produktionsbearbeitung zulassen". Jeder Eintrag zeigt, wer die Metadatenbearbeitung in Produktionsumgebungen aktiviert oder deaktiviert hat.',
        dateTime: 'Datum/Uhrzeit',
        action: 'Aktion',
        changedBy: 'Geändert Von',
        username: 'Benutzername',
        orgType: 'Org-Typ',
        ipAddress: 'IP-Adresse',
        showing: 'Anzeige',
        mostRecent: 'neueste Änderung(en)',
        noLogsTitle: 'Noch keine Prüfprotokolle',
        noLogsMessage: 'Änderungen an den Einstellungen für die Produktionsbearbeitung werden hier angezeigt',
        errorLoading: 'Fehler beim Laden der Prüfprotokolle',
        enabled: 'Aktiviert',
        disabled: 'Deaktiviert'
    }
};

export function getLabels() {
    return LABELS[LANG] || LABELS['en'];
}

export function getLabel(key) {
    const labels = getLabels();
    return labels[key] || LABELS['en'][key] || key;
}

