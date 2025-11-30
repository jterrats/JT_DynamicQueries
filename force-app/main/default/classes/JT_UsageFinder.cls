/**
 * @description Controller to find usage of JT_DataSelector configurations in Apex classes
 * @author Jaime Terrats
 * @date 2025-11-30
 */
public with sharing class JT_UsageFinder {

    /**
     * @description Wrapper for usage results
     */
    public class UsageResult {
        @AuraEnabled public String className { get; set; }
        @AuraEnabled public String configName { get; set; }
        @AuraEnabled public Integer lineNumber { get; set; }
        @AuraEnabled public String codeLine { get; set; }
        @AuraEnabled public String classId { get; set; }
    }

    /**
     * @description Finds all usages of JT_DataSelector with a specific configuration
     * @param configName The configuration name to search for
     * @return List<UsageResult> List of classes and lines where the configuration is used
     */
    @AuraEnabled(cacheable=false)
    public static List<UsageResult> findConfigurationUsage(String configName) {
        List<UsageResult> results = new List<UsageResult>();

        try {
            // Query all Apex classes
            List<ApexClass> apexClasses = [
                SELECT Id, Name, Body
                FROM ApexClass
                WHERE NamespacePrefix = null
                WITH USER_MODE
                ORDER BY Name
            ];

            // Search for references
            String searchPattern = 'JT_DataSelector';

            for (ApexClass cls : apexClasses) {
                if (String.isBlank(cls.Body)) {
                    continue;
                }

                // Check if class references JT_DataSelector
                if (!cls.Body.contains(searchPattern)) {
                    continue;
                }

                // Split into lines and search for configuration name
                List<String> lines = cls.Body.split('\n');
                Integer lineNumber = 0;

                for (String line : lines) {
                    lineNumber++;

                    // Look for pattern: JT_DataSelector.method('configName' or "configName")
                    if (line.contains(searchPattern)) {
                        String normalizedLine = line.toLowerCase();
                        String normalizedConfig = configName.toLowerCase();

                        // Check for various patterns
                        if (normalizedLine.contains('\'' + normalizedConfig + '\'') ||
                            normalizedLine.contains('"' + normalizedConfig + '"')) {

                            UsageResult result = new UsageResult();
                            result.className = cls.Name;
                            result.configName = configName;
                            result.lineNumber = lineNumber;
                            result.codeLine = line.trim();
                            result.classId = cls.Id;
                            results.add(result);
                        }
                    }
                }
            }

            return results;

        } catch (Exception e) {
            throw new AuraHandledException('Error finding usage: ' + e.getMessage());
        }
    }

    /**
     * @description Finds all usages of JT_DataSelector across all configurations
     * @return List<UsageResult> List of all JT_DataSelector usages
     */
    @AuraEnabled(cacheable=true)
    public static List<UsageResult> findAllUsages() {
        List<UsageResult> results = new List<UsageResult>();

        try {
            // Query all Apex classes
            List<ApexClass> apexClasses = [
                SELECT Id, Name, Body
                FROM ApexClass
                WHERE NamespacePrefix = null
                WITH USER_MODE
                ORDER BY Name
            ];

            // Search for all references to JT_DataSelector
            String searchPattern = 'JT_DataSelector';

            for (ApexClass cls : apexClasses) {
                if (String.isBlank(cls.Body)) {
                    continue;
                }

                // Check if class references JT_DataSelector
                if (!cls.Body.contains(searchPattern)) {
                    continue;
                }

                // Split into lines and find all occurrences
                List<String> lines = cls.Body.split('\n');
                Integer lineNumber = 0;

                for (String line : lines) {
                    lineNumber++;

                    if (line.contains(searchPattern)) {
                        // Try to extract configuration name from common patterns
                        String extractedConfig = extractConfigName(line);

                        UsageResult result = new UsageResult();
                        result.className = cls.Name;
                        result.configName = extractedConfig;
                        result.lineNumber = lineNumber;
                        result.codeLine = line.trim();
                        result.classId = cls.Id;
                        results.add(result);
                    }
                }
            }

            return results;

        } catch (Exception e) {
            throw new AuraHandledException('Error finding all usages: ' + e.getMessage());
        }
    }

    /**
     * @description Extracts configuration name from a line of code
     * @param line Line of code
     * @return String Extracted configuration name or 'Unknown'
     */
    private static String extractConfigName(String line) {
        // Try to extract string literal after JT_DataSelector method calls
        // Patterns: getConfig('name'), getRecords('name'), etc.
        Pattern p = Pattern.compile('JT_DataSelector\\.[a-zA-Z]+\\s*\\(\\s*[\'"]([^\'"]+)[\'"]');
        Matcher m = p.matcher(line);

        if (m.find()) {
            return m.group(1);
        }

        return 'Unknown';
    }
}

