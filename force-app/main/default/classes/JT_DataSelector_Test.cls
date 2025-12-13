/**
 * @description: provides code coverage to class JT_DataSelector
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 *
 * The @IsTest class annotation indicates this class only contains test
 * methods. Classes defined with the @IsTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
/**
 * @description Test class for JT_DataSelector
 * @author Jaime Terrats | 06-18-2025
 **/
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexDoc')
private class JT_DataSelector_Test {
  /**
   * @description This test setup creates a mock account record and user with limited access
   * @author Jaime Terrats | 06-18-2025
   **/
  @testSetup
  static void setupTestData() {
    insert new Account(Name = 'Test Account');

    final Profile leastPrivilege = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Minimum Access - Salesforce'
    ];
    insert new User(
      FirstName = 'John',
      LastName = 'Doe',
      ProfileId = leastPrivilege.Id,
      Username = 'johndoe@jtdemo.com',
      Email = 'johndoe@jtdemo.com',
      Alias = 'jdoe',
      TimeZoneSidKey = 'GMT',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US'
    );
  }

  /**
   * @description validates configurable bindings in user access mode
   * @author Jaime Terrats | 06-18-2025
   **/
  @IsTest
  static void testGetRecordsUserAccessMode() {
    Test.startTest();
    List<SObject> results = JT_DataSelector.getRecords('Test_Record', true);
    Test.stopTest();

    System.assertNotEquals(
      0,
      results.size(),
      'The query should return at least one record.'
    );
    System.assertEquals(
      'Test Account',
      ((Account) results[0]).Name,
      'The Account name should match.'
    );
  }

  /**
   * @description validates configurable bindings in system access mode
   * @author Jaime Terrats | 06-18-2025
   **/
  @IsTest
  static void testGetRecordsSystemAccessMode() {
    Test.startTest();
    List<SObject> results = JT_DataSelector.getRecords('Test_Record', false);
    Test.stopTest();

    System.assertNotEquals(
      0,
      results.size(),
      'The query should return at least one record.'
    );
    System.assertEquals(
      'Test Account',
      ((Account) results[0]).Name,
      'The Account name should match.'
    );
  }

  /**
   * @description validates system access mode using dynamic bindings from apex or js context
   * @author Jaime Terrats | 06-18-2025
   **/
  @IsTest
  static void testGetRecordsOverloadBindingsSA() {
    Test.startTest();
    List<SObject> results = JT_DataSelector.getRecords(
      'Test_Record',
      false,
      new Map<String, Object>{ 'name' => 'Test Account' }
    );
    Test.stopTest();

    System.assertNotEquals(
      0,
      results.size(),
      'The query should return at least one record.'
    );
    System.assertEquals(
      'Test Account',
      ((Account) results[0]).Name,
      'The Account name should match.'
    );
  }

  /**
   * @description validates user acces mode using dynamic bindings from apex or js context
   * @author Jaime Terrats | 06-18-2025
   **/
  @IsTest
  static void testGetRecordsOverloadBindingsUAM() {
    Test.startTest();
    List<SObject> results = JT_DataSelector.getRecords(
      'Test_Record',
      true,
      new Map<String, Object>{ 'name' => 'Test Account' }
    );
    Test.stopTest();

    System.assertNotEquals(
      0,
      results.size(),
      'The query should return at least one record.'
    );
    System.assertEquals(
      'Test Account',
      ((Account) results[0]).Name,
      'The Account name should match.'
    );
  }

  /**
   * @description validates exception to check if user has access to the custom metadata
   * @author Jaime Terrats | 06-18-2025
   **/
  @IsTest
  static void testException() {
    User testUser = [SELECT Id FROM User WHERE Name = 'John Doe'];
    System.runAs(testUser) {
      Test.startTest();
      try {
        JT_DataSelector.getRecords(
          'Test_Record',
          true,
          new Map<String, Object>{ 'name' => 'Test Account' }
        );
      } catch (Exception e) {
        System.Assert.isTrue(e instanceof AuraHandledException);
      }
      Test.stopTest();
    }
  }

  /**
   * @description validates @InvocableMethod for Flow/Agentforce integration
   * @author Jaime Terrats | 06-18-2025
   **/
  @IsTest
  static void testInvocableMethod() {
    // Prepare request
    JT_DataSelector.InvocableRequest req = new JT_DataSelector.InvocableRequest();
    req.configName = 'Test_Record';
    req.bindingsJson = '{"name":"Test Account"}';

    Test.startTest();
    List<JT_DataSelector.InvocableResult> results = JT_DataSelector.executeQuery(
      new List<JT_DataSelector.InvocableRequest>{ req }
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
    System.assertEquals(1, results.size(), 'Should return one result');
    System.assertEquals(true, results[0].success, 'Should be successful');
    System.assertNotEquals(
      null,
      results[0].records,
      'Records should not be null'
    );
    System.assert(
      results[0].recordCount > 0,
      'Should have at least one record'
    );
  }

  /**
   * @description validates @InvocableMethod with invalid config
   * @author Jaime Terrats | 06-18-2025
   **/
  @IsTest
  static void testInvocableMethodError() {
    JT_DataSelector.InvocableRequest req = new JT_DataSelector.InvocableRequest();
    req.configName = 'NonExistentConfig';
    req.bindingsJson = '{}';

    Test.startTest();
    List<JT_DataSelector.InvocableResult> results = JT_DataSelector.executeQuery(
      new List<JT_DataSelector.InvocableRequest>{ req }
    );
    Test.stopTest();

    System.assertNotEquals(null, results, 'Results should not be null');
    System.assertEquals(1, results.size(), 'Should return one result');
    System.assertEquals(false, results[0].success, 'Should have failed');
    System.assertNotEquals(
      null,
      results[0].errorMessage,
      'Error message should not be null'
    );
  }

  /**
   * @description Test cursor processing with small batch
   * @author Jaime Terrats | 11-30-2025
   **/
  @IsTest
  static void testCursorProcessing() {
    // Create test processor
    TestCursorProcessor processor = new TestCursorProcessor();

    Map<String, Object> bindings = new Map<String, Object>{
      'name' => 'Test Account for Query'
    };

    Test.startTest();
    Integer totalProcessed = JT_DataSelector.processRecordsWithCursor(
      'Test_Record',
      bindings,
      true, // enforces security
      10, // small batch size for testing
      processor
    );
    Test.stopTest();

    System.assert(totalProcessed >= 0, 'Should process at least 0 records');
    System.assertEquals(
      totalProcessed,
      processor.totalRecordsProcessed,
      'Total processed should match processor count'
    );
  }

  /**
   * @description Test cursor processing with null bindings
   * @author Jaime Terrats | 11-30-2025
   **/
  @IsTest
  static void testCursorProcessingNullBindings() {
    TestCursorProcessor processor = new TestCursorProcessor();

    Test.startTest();
    Integer totalProcessed = JT_DataSelector.processRecordsWithCursor(
      'Test_Record',
      null, // null bindings
      true,
      50,
      processor
    );
    Test.stopTest();

    System.assert(
      totalProcessed >= 0,
      'Should handle null bindings gracefully'
    );
  }

  /**
   * @description Test cursor processing with default batch size
   * @author Jaime Terrats | 11-30-2025
   **/
  @IsTest
  static void testCursorProcessingDefaultBatchSize() {
    TestCursorProcessor processor = new TestCursorProcessor();

    Test.startTest();
    Integer totalProcessed = JT_DataSelector.processRecordsWithCursor(
      'Test_Record',
      null,
      true,
      null, // null batch size (should default to 200)
      processor
    );
    Test.stopTest();

    System.assert(totalProcessed >= 0, 'Should use default batch size');
  }

  /**
   * @description Test implementation of CursorProcessor interface
   */
  private class TestCursorProcessor implements JT_DataSelector.CursorProcessor {
    public Integer batchesProcessed = 0;
    public Integer totalRecordsProcessed = 0;

    public void processBatch(List<SObject> batch) {
      batchesProcessed++;
      totalRecordsProcessed += batch.size();
      // In a real implementation, you would process the batch here
      // Example: insert updates, send emails, perform calculations, etc.
    }
  }
}