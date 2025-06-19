/**
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

@testSetup
  static void setupTestData() {
    insert new Account(
      Name = 'Test Account'
    );
  }

  @isTest
  static void testGetRecords() {
    Test.startTest();
    List<SObject> results = JT_DataSelector.getRecords(
      'Test_Record'
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
}