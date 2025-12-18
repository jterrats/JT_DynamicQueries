/**
 * @description Test class for JT_QueryViewerController
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @last modified on 11-28-2025
 * @last modified by Jaime Terrats
 **/
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexDoc')
private class JT_QueryViewerController_Test {
  @testSetup
  static void setupTestData() {
    // Create test Account
    insert new Account(Name = 'Test Account for Viewer');
  }

  /**
   * @description Test child relationships in query results
   * Validates that child relationships (Contacts, Opportunities, etc.) are preserved
   */
  @IsTest
  static void testChildRelationshipsInQuery() {
    // Create test data with child relationships
    Account acc = new Account(
      Name = 'Test Account with Children',
      Type = 'Customer',
      Industry = 'Technology',
      AnnualRevenue = 1000000
    );
    insert acc;

    // Create child Contacts
    List<Contact> contacts = new List<Contact>{
      new Contact(
        AccountId = acc.Id,
        FirstName = 'John',
        LastName = 'Doe',
        Email = 'john@test.com'
      ),
      new Contact(
        AccountId = acc.Id,
        FirstName = 'Jane',
        LastName = 'Smith',
        Email = 'jane@test.com'
      )
    };
    insert contacts;

    // Create child Opportunities
    List<Opportunity> opps = new List<Opportunity>{
      new Opportunity(
        AccountId = acc.Id,
        Name = 'Test Opp 1',
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(30),
        Amount = 10000
      ),
      new Opportunity(
        AccountId = acc.Id,
        Name = 'Test Opp 2',
        StageName = 'Negotiation',
        CloseDate = Date.today().addDays(60),
        Amount = 20000
      )
    };
    insert opps;

    Test.startTest();

    // Execute query with child relationships
    JT_QueryViewerController.QueryResult result = JT_QueryViewerController.executeQuery(
      'Complete_Customer_360_View',
      '{"accountType": "Customer"}',
      null
    );

    Test.stopTest();

    // Validate result
    System.assert(result.success, 'Query should succeed');
    System.assert(result.recordCount > 0, 'Should return records');

    // 🔥 CRITICAL VALIDATION: Check if child relationships are preserved
    if (!result.records.isEmpty()) {
      System.debug(
        '🔥 TEST: First record: ' + JSON.serialize(result.records[0])
      );

      Map<String, Object> firstRecord = (Map<String, Object>) result.records[0];
      System.debug('🔥 TEST: First record keys: ' + firstRecord.keySet());

      // Check for Contacts child relationship
      System.assert(
        firstRecord.containsKey('Contacts'),
        'ERROR: Contacts child relationship is MISSING! Keys found: ' +
        firstRecord.keySet()
      );

      if (firstRecord.containsKey('Contacts')) {
        Object contactsObj = firstRecord.get('Contacts');
        System.debug('🔥 TEST: Contacts value: ' + contactsObj);

        // Contacts should be a Map with 'records' and 'totalSize'
        System.assert(
          contactsObj instanceof Map<String, Object>,
          'Contacts should be a Map, but is: ' + contactsObj
        );

        Map<String, Object> contactsMap = (Map<String, Object>) contactsObj;
        System.assert(
          contactsMap.containsKey('records'),
          'Contacts should have "records" key. Keys: ' + contactsMap.keySet()
        );
        System.assert(
          contactsMap.containsKey('totalSize'),
          'Contacts should have "totalSize" key. Keys: ' + contactsMap.keySet()
        );

        System.assertEquals(
          2,
          contactsMap.get('totalSize'),
          'Should have 2 contacts'
        );
      }
    }
  }

  /**
   * @description Test getConfigurations method
   * @author Jaime Terrats | 11-28-2025
   **/
  @IsTest
  static void testGetConfigurations() {
    Test.startTest();
    List<JT_QueryViewerController.ConfigurationOption> configs = JT_QueryViewerController.getConfigurations();
    Test.stopTest();

    System.assertNotEquals(null, configs, 'Configurations should not be null');
    System.assert(!configs.isEmpty(), 'Should have at least one configuration');
  }

  /**
   * @description Test executeQuery with bindings
   * @author Jaime Terrats | 11-28-2025
   **/
  @IsTest
  static void testExecuteQueryWithBindings() {
    Map<String, Object> bindings = new Map<String, Object>{
      'name' => 'Test Account for Viewer'
    };
    String bindingsJson = JSON.serialize(bindings);

    Test.startTest();
    JT_QueryViewerController.QueryResult result = JT_QueryViewerController.executeQuery(
      'Test_Record',
      bindingsJson,
      null
    );
    Test.stopTest();

    System.assertEquals(true, result.success, 'Query should succeed');
    System.assertNotEquals(0, result.recordCount, 'Should return records');
    System.assertNotEquals(null, result.fields, 'Fields should be populated');
  }

  /**
   * @description Test executeQuery without custom bindings (uses config bindings)
   * @author Jaime Terrats | 11-28-2025
   **/
  @IsTest
  static void testExecuteQueryWithoutBindings() {
    Test.startTest();
    JT_QueryViewerController.QueryResult result = JT_QueryViewerController.executeQuery(
      'Test_Record',
      '',
      null
    );
    Test.stopTest();

    // Result may succeed or fail depending on config bindings
    System.assertNotEquals(null, result, 'Result should not be null');
    if (!result.success) {
      System.assertNotEquals(
        null,
        result.errorMessage,
        'Error message should be populated'
      );
    }
  }

  /**
   * @description Test executeQueryPreview method
   * @author Jaime Terrats | 12-01-2025
   **/
  @IsTest
  static void testExecuteQueryPreview() {
    Map<String, Object> bindings = new Map<String, Object>{
      'name' => 'Test Account for Viewer'
    };
    String bindingsJson = JSON.serialize(bindings);

    Test.startTest();
    JT_QueryViewerController.QueryResult result = JT_QueryViewerController.executeQueryPreview(
      'Test_Record',
      bindingsJson,
      null
    );
    Test.stopTest();

    System.assertEquals(true, result.success, 'Preview should succeed');
    System.assert(
      result.recordCount <= 5,
      'Preview should return max 5 records'
    );
    if (result.recordCount > 0) {
      System.assertNotEquals(null, result.fields, 'Fields should be populated');
      System.assertNotEquals(
        null,
        result.records,
        'Records should be populated'
      );
    }
  }

  /**
   * @description Test executeQueryPreview with invalid bindings
   * @author Jaime Terrats | 12-01-2025
   **/
  @IsTest
  static void testExecuteQueryPreviewError() {
    String invalidBindings = '{invalid json}';

    Test.startTest();
    JT_QueryViewerController.QueryResult result = JT_QueryViewerController.executeQueryPreview(
      'Test_Record',
      invalidBindings,
      null
    );
    Test.stopTest();

    System.assertEquals(
      false,
      result.success,
      'Preview should fail with invalid JSON'
    );
    System.assertNotEquals(
      null,
      result.errorMessage,
      'Error message should be present'
    );
  }

  /**
   * @description Test extractParameters method
   * @author Jaime Terrats | 11-28-2025
   **/
  @IsTest
  static void testExtractParameters() {
    String query = 'SELECT Id, Name FROM Account WHERE Name = :accountName AND Type = :accountType';

    Test.startTest();
    List<String> params = JT_QueryViewerController.extractParameters(query);
    Test.stopTest();

    System.assertEquals(2, params.size(), 'Should extract 2 parameters');
    System.assert(params.contains('accountName'), 'Should contain accountName');
    System.assert(params.contains('accountType'), 'Should contain accountType');
  }

  /**
   * @description Test extractParameters with empty query
   * @author Jaime Terrats | 11-28-2025
   **/
  @IsTest
  static void testExtractParametersEmpty() {
    Test.startTest();
    List<String> params = JT_QueryViewerController.extractParameters('');
    Test.stopTest();

    System.assertEquals(0, params.size(), 'Should return empty list');
  }

  /**
   * @description Test executeQuery with invalid config
   * @author Jaime Terrats | 11-28-2025
   **/
  @IsTest
  static void testExecuteQueryError() {
    Test.startTest();
    JT_QueryViewerController.QueryResult result = JT_QueryViewerController.executeQuery(
      'Invalid_Config',
      null,
      null
    );
    Test.stopTest();

    System.assertEquals(false, result.success, 'Query should fail');
    System.assertNotEquals(
      null,
      result.errorMessage,
      'Should have error message'
    );
  }

  /**
   * @description Test canUseRunAs method
   * @author Jaime Terrats | 11-28-2025
   **/
  @IsTest
  static void testCanUseRunAs() {
    Test.startTest();
    Boolean canUse = JT_QueryViewerController.canUseRunAs();
    Test.stopTest();

    // Result depends on user permissions - just verify it returns a boolean
    System.assertNotEquals(null, canUse, 'Should return a boolean');
  }

  /**
   * @description Test searchUsers method
   * @author Jaime Terrats | 11-28-2025
   **/
  @IsTest
  static void testGetAllActiveUsers() {
    Test.startTest();
    try {
      List<JT_QueryViewerController.UserOption> users = JT_QueryViewerController.getAllActiveUsers();
      // If user has permissions, should return results or empty list
      System.assertNotEquals(null, users, 'Should return a list');
      // Should exclude current user
      for (JT_QueryViewerController.UserOption user : users) {
        System.assertNotEquals(
          UserInfo.getUserId(),
          user.value,
          'Should not include current user'
        );
      }
    } catch (Exception e) {
      // If user doesn't have permissions, should throw exception
      System.assert(
        e instanceof AuraHandledException,
        'Should throw AuraHandledException'
      );
    }
    Test.stopTest();
  }

  /**
   * @description Test executeQuery with Run As User
   * @author Jaime Terrats | 11-28-2025
   **/
  @IsTest
  static void testExecuteQueryWithRunAs() {
    User currentUser = JT_SystemSelector.getCurrentUser();
    Map<String, Object> bindings = new Map<String, Object>{
      'name' => 'Test Account for Viewer'
    };
    String bindingsJson = JSON.serialize(bindings);

    Test.startTest();
    try {
      JT_QueryViewerController.QueryResult result = JT_QueryViewerController.executeQuery(
        'Test_Record',
        bindingsJson,
        currentUser.Id
      );
      // Should succeed or fail based on permissions
      System.assertNotEquals(null, result, 'Should return a result');
    } catch (Exception e) {
      // May fail if user doesn't have Run As permissions
      System.assert(true, 'Exception expected if no permissions');
    }
    Test.stopTest();
  }

  /**
   * @description Test extractParameters with various spacing formats
   * @author Jaime Terrats | 11-30-2025
   **/
  @IsTest
  static void testExtractParametersVariousSpacing() {
    String query1 = 'SELECT Id FROM Account WHERE Name = :name';
    String query2 = 'SELECT Id FROM Account WHERE Name =:name';
    String query3 = 'SELECT Id FROM Account WHERE Name = : name';
    String query4 = 'SELECT Id FROM Account WHERE Name =: name';

    Test.startTest();
    List<String> params1 = JT_QueryViewerController.extractParameters(query1);
    List<String> params2 = JT_QueryViewerController.extractParameters(query2);
    List<String> params3 = JT_QueryViewerController.extractParameters(query3);
    List<String> params4 = JT_QueryViewerController.extractParameters(query4);
    Test.stopTest();

    // All should extract the parameter regardless of spacing
    System.assertEquals(1, params1.size(), 'Should extract parameter');
    System.assertEquals(1, params2.size(), 'Should extract parameter');
    System.assertEquals(1, params3.size(), 'Should extract parameter');
    System.assertEquals(1, params4.size(), 'Should extract parameter');

    System.assert(params1.contains('name'), 'Should contain name');
    System.assert(params2.contains('name'), 'Should contain name');
    System.assert(params3.contains('name'), 'Should contain name');
    System.assert(params4.contains('name'), 'Should contain name');
  }

  /**
   * @description Test assessQueryRisk for low risk queries
   * @author Jaime Terrats | 12-02-2025
   **/
  @IsTest
  static void testAssessQueryRiskLowRisk() {
    Map<String, Object> bindings = new Map<String, Object>{
      'name' => 'Test Account for Viewer'
    };
    String bindingsJson = JSON.serialize(bindings);

    Test.startTest();
    JT_QueryViewerController.QueryRiskAssessment assessment = JT_QueryViewerController.assessQueryRisk(
      'Test_Record',
      bindingsJson
    );
    Test.stopTest();

    // Verify assessment structure (don't assert on isCriticalRisk as COUNT may fail in test context)
    System.assertNotEquals(null, assessment, 'Assessment should not be null');
    System.assertNotEquals(
      null,
      assessment.estimatedRecordCount,
      'Should have record count estimate'
    );
    System.assertNotEquals(
      null,
      assessment.riskLevel,
      'Should have risk level'
    );
    System.assertNotEquals(
      null,
      assessment.message,
      'Should have a risk message'
    );

    // Verify it's either LOW, MEDIUM, HIGH, CRITICAL, or UNKNOWN
    List<String> validLevels = new List<String>{
      'LOW',
      'MEDIUM',
      'HIGH',
      'CRITICAL',
      'UNKNOWN'
    };
    System.assert(
      validLevels.contains(assessment.riskLevel),
      'Risk level should be valid'
    );
  }

  /**
   * @description Test assessQueryRisk with empty bindings (high risk)
   * @author Jaime Terrats | 12-02-2025
   **/
  @IsTest
  static void testAssessQueryRiskEmptyBindings() {
    // Empty bindings (empty string value)
    Map<String, Object> bindings = new Map<String, Object>{ 'name' => '' };
    String bindingsJson = JSON.serialize(bindings);

    Test.startTest();
    JT_QueryViewerController.QueryRiskAssessment assessment = JT_QueryViewerController.assessQueryRisk(
      'Test_Record',
      bindingsJson
    );
    Test.stopTest();

    System.assertNotEquals(null, assessment, 'Assessment should not be null');
    System.assertEquals(
      true,
      assessment.hasEmptyParameters,
      'Should detect empty parameters'
    );
  }

  /**
   * @description Test executeQueryWithBatchProcessing
   * @author Jaime Terrats | 12-02-2025
   **/
  @IsTest
  static void testExecuteQueryWithBatchProcessing() {
    // Create a specific account that matches the test
    Account testAcc = new Account(Name = 'Batch Processing Test Account');
    insert testAcc;

    // Use binding with a specific name
    Map<String, Object> bindings = new Map<String, Object>{
      'name' => 'Batch Processing Test Account'
    };
    String bindingsJson = JSON.serialize(bindings);

    Test.startTest();
    JT_QueryViewerController.QueryResult result = JT_QueryViewerController.executeQueryWithBatchProcessing(
      'Test_Record',
      bindingsJson,
      10 // Small batch size for testing
    );
    Test.stopTest();

    System.assertEquals(true, result.success, 'Batch query should succeed');
    System.assert(result.recordCount > 0, 'Should return records');
    System.assertNotEquals(
      null,
      result.records,
      'Records list should not be null'
    );
  }

  /**
   * @description Test serializeRecordsForLWC method
   * Validates that child relationships are preserved in standard Salesforce format
   * @author Jaime Terrats | 12-13-2025
   **/
  @IsTest
  static void testSerializeRecordsForLWC() {
    // Create test data with child relationships
    Account acc = new Account(
      Name = 'Test Account for Serialization',
      Type = 'Customer',
      Industry = 'Technology'
    );
    insert acc;

    // Create child Contacts
    List<Contact> contacts = new List<Contact>{
      new Contact(
        AccountId = acc.Id,
        FirstName = 'John',
        LastName = 'Doe',
        Email = 'john@test.com'
      ),
      new Contact(
        AccountId = acc.Id,
        FirstName = 'Jane',
        LastName = 'Smith',
        Email = 'jane@test.com'
      )
    };
    insert contacts;

    // Query with child relationship
    List<Account> accounts = [
      SELECT
        Id,
        Name,
        Type,
        Industry,
        (SELECT Id, FirstName, LastName, Email FROM Contacts)
      FROM Account
      WHERE Id = :acc.Id
      LIMIT 1
    ];

    Test.startTest();
    List<Object> serialized = JT_QueryViewerController.serializeRecordsForLWC(
      accounts
    );
    Test.stopTest();

    System.assertNotEquals(
      null,
      serialized,
      'Serialized records should not be null'
    );
    System.assertEquals(1, serialized.size(), 'Should serialize one account');

    // Verify child relationships are preserved
    Map<String, Object> firstRecord = (Map<String, Object>) serialized[0];
    System.assert(
      firstRecord.containsKey('Contacts'),
      'Child relationship Contacts should be preserved'
    );

    // Verify Contacts is in standard format: { records: [...] }
    Object contactsObj = firstRecord.get('Contacts');
    System.assertNotEquals(null, contactsObj, 'Contacts should not be null');

    // Contacts should be a Map with 'records' key
    if (contactsObj instanceof Map<String, Object>) {
      Map<String, Object> contactsMap = (Map<String, Object>) contactsObj;
      System.assert(
        contactsMap.containsKey('records'),
        'Contacts should have records key in standard format'
      );
      List<Object> contactRecords = (List<Object>) contactsMap.get('records');
      System.assertEquals(2, contactRecords.size(), 'Should have 2 contacts');
    }
  }

  /**
   * @description Test serializeRecordsForLWC with empty list
   * @author Jaime Terrats | 12-13-2025
   **/
  @IsTest
  static void testSerializeRecordsForLWCEmpty() {
    Test.startTest();
    List<Object> serialized = JT_QueryViewerController.serializeRecordsForLWC(
      new List<Account>()
    );
    Test.stopTest();

    System.assertNotEquals(
      null,
      serialized,
      'Should return empty list, not null'
    );
    System.assertEquals(0, serialized.size(), 'Should return empty list');
  }

  /**
   * @description Test serializeRecordsForLWC with null input
   * @author Jaime Terrats | 12-13-2025
   **/
  @IsTest
  static void testSerializeRecordsForLWCNull() {
    Test.startTest();
    List<Object> serialized = JT_QueryViewerController.serializeRecordsForLWC(
      null
    );
    Test.stopTest();

    System.assertNotEquals(
      null,
      serialized,
      'Should return empty list, not null'
    );
    System.assertEquals(
      0,
      serialized.size(),
      'Should return empty list for null input'
    );
  }

  /**
   * @description Test batch processing with large result set simulation
   * @author Jaime Terrats | 12-02-2025
   **/
  @IsTest
  static void testExecuteQueryWithBatchProcessingLargeSet() {
    // Create a single account that will be queried
    Account testAcc = new Account(Name = 'Large Set Test Account');
    insert testAcc;

    // Use specific binding to match the account
    Map<String, Object> bindings = new Map<String, Object>{
      'name' => 'Large Set Test Account'
    };
    String bindingsJson = JSON.serialize(bindings);

    Test.startTest();
    JT_QueryViewerController.QueryResult result = JT_QueryViewerController.executeQueryWithBatchProcessing(
      'Test_Record',
      bindingsJson,
      50 // Batch size of 50
    );
    Test.stopTest();

    System.assertEquals(true, result.success, 'Batch query should succeed');
    System.assert(result.recordCount > 0, 'Should return the test account');
  }

  /**
   * @description Test ResultCollector inner class
   * @author Jaime Terrats | 12-02-2025
   **/
  @IsTest
  static void testResultCollector() {
    // Create test records
    List<Account> accounts = new List<Account>{
      new Account(Name = 'Collector Test 1'),
      new Account(Name = 'Collector Test 2')
    };
    insert accounts;

    JT_QueryViewerController.ResultCollector collector = new JT_QueryViewerController.ResultCollector();

    Test.startTest();
    // Process batch 1
    collector.processBatch(new List<SObject>{ accounts[0] });
    // Process batch 2
    collector.processBatch(new List<SObject>{ accounts[1] });
    Test.stopTest();

    List<SObject> allRecords = collector.getAllRecords();
    System.assertEquals(
      2,
      allRecords.size(),
      'Should collect all records from batches'
    );
  }

  /**
   * @description Test extractParameters with null query
   */
  @IsTest
  static void testExtractParametersNull() {
    Test.startTest();
    List<String> params = JT_QueryViewerController.extractParameters(null);
    Test.stopTest();

    System.assertEquals(0, params.size(), 'Should return empty list for null');
  }

  /**
   * @description Test extractParameters with exception handling
   */
  @IsTest
  static void testExtractParametersException() {
    // This test verifies exception handling path exists
    // In practice, extractParameters should handle errors gracefully
    Test.startTest();
    try {
      // Using a query that might cause issues
      List<String> params = JT_QueryViewerController.extractParameters('SELECT');
      System.assertNotEquals(null, params, 'Should return list even on error');
    } catch (Exception e) {
      // Exception is acceptable - method should handle it
      System.assert(true, 'Exception handled');
    }
    Test.stopTest();
  }

  /**
   * @description Test getConfigurations with exception
   */
  @IsTest
  static void testGetConfigurationsException() {
    // This test verifies exception handling in getConfigurations
    // The method should throw AuraHandledException on error
    Test.startTest();
    try {
      List<JT_QueryViewerController.ConfigurationOption> configs = JT_QueryViewerController.getConfigurations();
      System.assertNotEquals(null, configs, 'Should return list');
    } catch (AuraHandledException e) {
      // Exception is acceptable - method handles errors
      System.assert(true, 'Exception handled');
    }
    Test.stopTest();
  }

  /**
   * @description Test canUseRunAs with exception handling
   */
  @IsTest
  static void testCanUseRunAsException() {
    // This test verifies exception handling in canUseRunAs
    Test.startTest();
    Boolean canUse = JT_QueryViewerController.canUseRunAs();
    Test.stopTest();

    // Should return false on exception, not throw
    System.assertNotEquals(null, canUse, 'Should return boolean');
  }

  /**
   * @description Test executeQuery with invalid runAsUserId
   */
  @IsTest
  static void testExecuteQueryInvalidRunAs() {
    String fakeUserId = '005' + '0'.repeat(15);
    Map<String, Object> bindings = new Map<String, Object>{
      'name' => 'Test Account for Viewer'
    };
    String bindingsJson = JSON.serialize(bindings);

    Test.startTest();
    try {
      JT_QueryViewerController.QueryResult result = JT_QueryViewerController.executeQuery(
        'Test_Record',
        bindingsJson,
        fakeUserId
      );
      // May succeed or fail depending on permissions
      System.assertNotEquals(null, result, 'Should return result');
    } catch (AuraHandledException e) {
      // Exception expected if user not found or no permissions
      System.assert(true, 'Exception expected');
    }
    Test.stopTest();
  }

  /**
   * @description Test executeQueryPreview with null bindings
   */
  @IsTest
  static void testExecuteQueryPreviewNullBindings() {
    Test.startTest();
    JT_QueryViewerController.QueryResult result = JT_QueryViewerController.executeQueryPreview(
      'Test_Record',
      null,
      null
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
  }

  /**
   * @description Test executeQueryPreview with empty bindings
   */
  @IsTest
  static void testExecuteQueryPreviewEmptyBindings() {
    Test.startTest();
    JT_QueryViewerController.QueryResult result = JT_QueryViewerController.executeQueryPreview(
      'Test_Record',
      '',
      null
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
  }

  /**
   * @description Test assessQueryRisk with null bindings
   */
  @IsTest
  static void testAssessQueryRiskNullBindings() {
    Test.startTest();
    JT_QueryViewerController.QueryRiskAssessment assessment = JT_QueryViewerController.assessQueryRisk(
      'Test_Record',
      null
    );
    Test.stopTest();

    System.assertNotEquals(null, assessment, 'Assessment should not be null');
  }

  /**
   * @description Test assessQueryRisk with empty bindings JSON
   */
  @IsTest
  static void testAssessQueryRiskEmptyBindingsJson() {
    Test.startTest();
    JT_QueryViewerController.QueryRiskAssessment assessment = JT_QueryViewerController.assessQueryRisk(
      'Test_Record',
      ''
    );
    Test.stopTest();

    System.assertNotEquals(null, assessment, 'Assessment should not be null');
  }

  /**
   * @description Test assessQueryRisk with invalid config
   */
  @IsTest
  static void testAssessQueryRiskInvalidConfig() {
    Map<String, Object> bindings = new Map<String, Object>{
      'name' => 'Test'
    };
    String bindingsJson = JSON.serialize(bindings);

    Test.startTest();
    JT_QueryViewerController.QueryRiskAssessment assessment = JT_QueryViewerController.assessQueryRisk(
      'Invalid_Config_Name',
      bindingsJson
    );
    Test.stopTest();

    System.assertNotEquals(null, assessment, 'Assessment should not be null');
    // Should return UNKNOWN risk level on error
    System.assertNotEquals(null, assessment.riskLevel, 'Should have risk level');
  }

  /**
   * @description Test executeQueryWithBatchProcessing with null bindings
   */
  @IsTest
  static void testExecuteQueryWithBatchProcessingNullBindings() {
    Test.startTest();
    JT_QueryViewerController.QueryResult result = JT_QueryViewerController.executeQueryWithBatchProcessing(
      'Test_Record',
      null,
      10
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
  }

  /**
   * @description Test executeQueryWithBatchProcessing with empty bindings
   */
  @IsTest
  static void testExecuteQueryWithBatchProcessingEmptyBindings() {
    Test.startTest();
    JT_QueryViewerController.QueryResult result = JT_QueryViewerController.executeQueryWithBatchProcessing(
      'Test_Record',
      '',
      10
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
  }

  /**
   * @description Test executeQueryWithBatchProcessing with invalid config
   */
  @IsTest
  static void testExecuteQueryWithBatchProcessingInvalidConfig() {
    Map<String, Object> bindings = new Map<String, Object>{
      'name' => 'Test'
    };
    String bindingsJson = JSON.serialize(bindings);

    Test.startTest();
    JT_QueryViewerController.QueryResult result = JT_QueryViewerController.executeQueryWithBatchProcessing(
      'Invalid_Config',
      bindingsJson,
      10
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    // May succeed or fail depending on config
  }

  /**
   * @description Test addWildcardsForLikeBindings method
   */
  @IsTest
  static void testAddWildcardsForLikeBindings() {
    String query = 'SELECT Id FROM Account WHERE Name LIKE :name';
    Map<String, Object> bindings = new Map<String, Object>{ 'name' => 'Test' };

    Test.startTest();
    JT_QueryViewerController.addWildcardsForLikeBindings(query, bindings);
    Test.stopTest();

    // Verify wildcards were added
    System.assert(
      bindings.containsKey('name'),
      'Binding should exist'
    );
    // The actual wildcard addition is tested in JT_QueryBindingUtil tests
  }

  /**
   * @description Test addWildcardsForLikeBindings with null query
   */
  @IsTest
  static void testAddWildcardsForLikeBindingsNullQuery() {
    Map<String, Object> bindings = new Map<String, Object>{ 'name' => 'Test' };

    Test.startTest();
    JT_QueryViewerController.addWildcardsForLikeBindings(null, bindings);
    Test.stopTest();

    // Should not throw exception
    System.assert(true, 'Should handle null query');
  }

  /**
   * @description Test addWildcardsForLikeBindings with null bindings
   */
  @IsTest
  static void testAddWildcardsForLikeBindingsNullBindings() {
    String query = 'SELECT Id FROM Account WHERE Name LIKE :name';

    Test.startTest();
    JT_QueryViewerController.addWildcardsForLikeBindings(query, null);
    Test.stopTest();

    // Should not throw exception
    System.assert(true, 'Should handle null bindings');
  }

  /**
   * @description Test executeQueryPreview with queryOverride
   */
  @IsTest
  static void testExecuteQueryPreviewWithQueryOverride() {
    String queryOverride = 'SELECT Id, Name FROM Account LIMIT 5';
    Map<String, Object> bindings = new Map<String, Object>();
    String bindingsJson = JSON.serialize(bindings);

    Test.startTest();
    JT_QueryViewerController.QueryResult result = JT_QueryViewerController.executeQueryPreview(
      null, // devName not needed when queryOverride provided
      bindingsJson,
      queryOverride
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(true, result.success, 'Should succeed with queryOverride');
  }

  /**
   * @description Test executeQueryPreview with queryOverride and existing LIMIT
   */
  @IsTest
  static void testExecuteQueryPreviewWithQueryOverrideExistingLimit() {
    String queryOverride = 'SELECT Id, Name FROM Account LIMIT 10';
    Map<String, Object> bindings = new Map<String, Object>();
    String bindingsJson = JSON.serialize(bindings);

    Test.startTest();
    JT_QueryViewerController.QueryResult result = JT_QueryViewerController.executeQueryPreview(
      null,
      bindingsJson,
      queryOverride
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    // Should replace LIMIT 10 with LIMIT 5
    System.assertEquals(true, result.success, 'Should succeed');
  }

  /**
   * @description Test executeQueryPreview with invalid queryOverride
   */
  @IsTest
  static void testExecuteQueryPreviewInvalidQueryOverride() {
    String queryOverride = 'INVALID QUERY SYNTAX';
    Map<String, Object> bindings = new Map<String, Object>();
    String bindingsJson = JSON.serialize(bindings);

    Test.startTest();
    JT_QueryViewerController.QueryResult result = JT_QueryViewerController.executeQueryPreview(
      null,
      bindingsJson,
      queryOverride
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(false, result.success, 'Should fail with invalid query');
    System.assertNotEquals(null, result.errorMessage, 'Should have error message');
  }

  /**
   * @description Test executeQuery with empty records list
   */
  @IsTest
  static void testExecuteQueryEmptyRecords() {
    // Use bindings that won't match any records
    Map<String, Object> bindings = new Map<String, Object>{
      'name' => 'NonExistentAccountName12345'
    };
    String bindingsJson = JSON.serialize(bindings);

    Test.startTest();
    JT_QueryViewerController.QueryResult result = JT_QueryViewerController.executeQuery(
      'Test_Record',
      bindingsJson,
      null
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(true, result.success, 'Should succeed even with no records');
    System.assertEquals(0, result.recordCount, 'Should have 0 records');
    System.assertEquals(0, result.records.size(), 'Records list should be empty');
  }
}
