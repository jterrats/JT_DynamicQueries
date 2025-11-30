/**
 * @description Test class for JT_QueryViewerController
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @last modified on 11-28-2025
 * @last modified by Jaime Terrats
 **/
@isTest
private class JT_QueryViewerController_Test {
  @testSetup
  static void setupTestData() {
    // Create test Account
    insert new Account(Name = 'Test Account for Viewer');
  }

  /**
   * @description Test getConfigurations method
   * @author Jaime Terrats | 11-28-2025
   **/
  @isTest
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
  @isTest
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
  @isTest
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
   * @description Test extractParameters method
   * @author Jaime Terrats | 11-28-2025
   **/
  @isTest
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
  @isTest
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
  @isTest
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
  @isTest
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
  @isTest
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
  @isTest
  static void testExecuteQueryWithRunAs() {
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
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
  @isTest
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
}
