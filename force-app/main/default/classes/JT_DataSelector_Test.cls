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
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class JT_DataSelector_Test {

/**
* @description this test setup creates a mock account record and
user with limited access
* @author Jaime Terrats | 06-18-2025
**/
@testSetup
  static void setupTestData() {
    insert new Account(
      Name = 'Test Account'
    );

    final Profile leastPrivilege = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce'];
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
  @isTest
  static void testGetRecordsUserAccessMode() {
    Test.startTest();
    List<SObject> results = JT_DataSelector.getRecords(
      'Test_Record', true
    );
    Test.stopTest();

    System.assertNotEquals(0,
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
  @isTest
  static void testGetRecordsSystemAccessMode() {
    Test.startTest();
    List<SObject> results = JT_DataSelector.getRecords(
      'Test_Record', false
    );
    Test.stopTest();

    System.assertNotEquals(0,
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
  @isTest
  static void testGetRecordsOverloadBindingsSA() {
    Test.startTest();
    List<SObject> results = JT_DataSelector.getRecords(
      'Test_Record', false, new Map<String,Object>{'name' => 'Test Account'}
    );
    Test.stopTest();

    System.assertNotEquals(0,
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
   @isTest
  static void testGetRecordsOverloadBindingsUAM() {
    Test.startTest();
    List<SObject> results = JT_DataSelector.getRecords(
      'Test_Record', true, new Map<String,Object>{'name' => 'Test Account'}
    );
    Test.stopTest();

    System.assertNotEquals(0,
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
  @isTest
  static void testException() {
    User testUser = [SELECT Id FROM User WHERE Name = 'John Doe'];
    System.runAs(testUser) {
      Test.startTest();
        try {
            JT_DataSelector.getRecords(
              'Test_Record', true, new Map<String,Object>{'name' => 'Test Account'}
            );
        }
        catch (Exception e) {
            System.Assert.isTrue(e instanceof AuraHandledException);
        }
      Test.stopTest();
    }
  }
}