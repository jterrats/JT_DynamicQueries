// Script to check recent error logs for metadata deletion
// First, describe the object to see available fields
Schema.DescribeSObjectResult describeResult = JT_ErrorLog__c.SObjectType.getDescribe();
Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

System.debug('=== AVAILABLE FIELDS IN JT_ErrorLog__c ===');
for (String fieldName : fieldMap.keySet()) {
  Schema.SObjectField field = fieldMap.get(fieldName);
  Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
  System.debug('Field: ' + fieldName + ' (Type: ' + fieldDescribe.getType() + ')');
}

// Build dynamic query with available fields
String query = 'SELECT Id';
if (fieldMap.containsKey('JT_ErrorType__c')) query += ', JT_ErrorType__c';
if (fieldMap.containsKey('JT_ErrorMessage__c')) query += ', JT_ErrorMessage__c';
if (fieldMap.containsKey('JT_Context__c')) query += ', JT_Context__c';
if (fieldMap.containsKey('JT_AdditionalDetails__c')) query += ', JT_AdditionalDetails__c';
if (fieldMap.containsKey('JT_Severity__c')) query += ', JT_Severity__c';
if (fieldMap.containsKey('JT_Timestamp__c')) query += ', JT_Timestamp__c';
if (fieldMap.containsKey('JT_OrgType__c')) query += ', JT_OrgType__c';
query += ' FROM JT_ErrorLog__c';
query += ' WHERE CreatedDate = TODAY';
query += ' ORDER BY CreatedDate DESC';
query += ' LIMIT 5';

System.debug('\n=== QUERY: ' + query + ' ===\n');

List<SObject> errorLogs = Database.query(query);

System.debug('=== RECENT ERROR LOGS ===');
System.debug('Total logs found: ' + errorLogs.size());

for (SObject log : errorLogs) {
  System.debug('\n--- Error Log ID: ' + log.Id + ' ---');
  if (fieldMap.containsKey('JT_ErrorType__c')) {
    System.debug('Error Type: ' + log.get('JT_ErrorType__c'));
  }
  if (fieldMap.containsKey('JT_ErrorMessage__c')) {
    System.debug('Error Message: ' + log.get('JT_ErrorMessage__c'));
  }
  if (fieldMap.containsKey('JT_Context__c')) {
    System.debug('Context: ' + log.get('JT_Context__c'));
  }
  if (fieldMap.containsKey('JT_Severity__c')) {
    System.debug('Severity: ' + log.get('JT_Severity__c'));
  }
  if (fieldMap.containsKey('JT_Timestamp__c')) {
    System.debug('Timestamp: ' + log.get('JT_Timestamp__c'));
  }
  if (fieldMap.containsKey('JT_OrgType__c')) {
    System.debug('Org Type: ' + log.get('JT_OrgType__c'));
  }

  if (fieldMap.containsKey('JT_AdditionalDetails__c')) {
    Object additionalDetails = log.get('JT_AdditionalDetails__c');
    if (additionalDetails != null && String.isNotBlank(String.valueOf(additionalDetails))) {
      String detailsStr = String.valueOf(additionalDetails);
      System.debug('\n📋 Additional Details (JSON):');
      System.debug(detailsStr);

      // Try to parse JSON for better readability
      try {
        Map<String, Object> details = (Map<String, Object>) JSON.deserializeUntyped(detailsStr);
        System.debug('\n📋 Parsed Additional Details:');
        for (String key : details.keySet()) {
          System.debug('  ' + key + ': ' + details.get(key));
        }
      } catch (Exception e) {
        System.debug('Could not parse JSON: ' + e.getMessage());
      }
    }
  }
}
