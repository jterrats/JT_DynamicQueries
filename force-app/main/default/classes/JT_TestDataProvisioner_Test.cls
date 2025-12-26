/**
 * @description Test class for JT_TestDataProvisioner
 * @author Jaime Terrats
 * @date 2025-12-19
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexDoc')
private class JT_TestDataProvisioner_Test {
  @IsTest
  static void testProvisionAllTestData() {
    Test.startTest();
    Integer count = JT_TestDataProvisioner.provisionAllTestData();
    Test.stopTest();

    System.assert(count > 0, 'Should create at least one account');

    // Verify some accounts were created
    List<Account> accounts = [
      SELECT Id, Name
      FROM Account
      WITH USER_MODE
      LIMIT 100
    ];
    System.assert(
      accounts.size() >= count,
      'Should have created the expected number of accounts'
    );
  }

  @IsTest
  static void testProvisionComplexMixedOperatorsData() {
    Test.startTest();
    List<Account> accounts = JT_TestDataProvisioner.provisionComplexMixedOperatorsData();
    Test.stopTest();

    System.assertNotEquals(0, accounts.size(), 'Should create accounts');
    System.assertEquals(
      4,
      accounts.size(),
      'Should create exactly 4 accounts for Complex Mixed Operators'
    );

    // Verify accounts match the query criteria
    for (Account acc : accounts) {
      System.assert(
        acc.Industry == 'Technology' || acc.Industry == 'Healthcare',
        'Industry should be Technology or Healthcare'
      );
      System.assertNotEquals(
        'Competitor',
        acc.Type,
        'Type should not be Competitor'
      );
      System.assert(
        acc.AnnualRevenue >= 100000,
        'AnnualRevenue should be >= 100000'
      );
      System.assert(
        acc.AnnualRevenue <= 100000000,
        'AnnualRevenue should be <= 100000000'
      );
      System.assert(
        acc.NumberOfEmployees >= 10,
        'NumberOfEmployees should be >= 10'
      );
      System.assert(
        acc.NumberOfEmployees <= 100,
        'NumberOfEmployees should be <= 100'
      );
      System.assertNotEquals(
        'Test Country',
        acc.BillingCountry,
        'BillingCountry should not be Test Country'
      );
    }
  }

  @IsTest
  static void testCleanupTestData() {
    // Create test accounts first
    List<Account> testAccounts = new List<Account>{
      new Account(Name = 'Test Account 1'),
      new Account(Name = 'Test Account 2')
    };
    insert testAccounts;

    Test.startTest();
    JT_TestDataProvisioner.cleanupTestData(
      new List<String>{ 'Test Account 1', 'Test Account 2' }
    );
    Test.stopTest();

    List<Account> remainingAccounts = [
      SELECT Id
      FROM Account
      WHERE Name IN ('Test Account 1', 'Test Account 2')
      WITH USER_MODE
    ];
    System.assertEquals(
      0,
      remainingAccounts.size(),
      'Test accounts should be deleted'
    );
  }
}
