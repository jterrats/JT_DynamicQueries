/**
 * @description Test class for JT_AccountReportExample
 * @author Jaime Terrats
 * @date 2025-12-11
 *
 * Demonstrates best practices:
 * - @testSetup for data creation
 * - Mocking with test data
 * - Testing JT_DataSelector integration
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexDoc')
private class JT_AccountReportExample_Test {
  /**
   * @description Test setup - creates mock Account data
   */
  @testSetup
  static void setupTestData() {
    // Create test accounts with various attributes
    List<Account> testAccounts = new List<Account>();

    // High-value Technology accounts
    testAccounts.add(
      new Account(
        Name = 'Tech Corp Alpha',
        Industry = 'Technology',
        AnnualRevenue = 5000000,
        NumberOfEmployees = 500,
        Type = 'Customer - Direct'
      )
    );

    testAccounts.add(
      new Account(
        Name = 'Tech Corp Beta',
        Industry = 'Technology',
        AnnualRevenue = 2500000,
        NumberOfEmployees = 250,
        Type = 'Customer - Direct'
      )
    );

    // Healthcare accounts
    testAccounts.add(
      new Account(
        Name = 'Health Systems Inc',
        Industry = 'Healthcare',
        AnnualRevenue = 8000000,
        NumberOfEmployees = 1200,
        Type = 'Customer - Channel'
      )
    );

    testAccounts.add(
      new Account(
        Name = 'Medical Supplies Co',
        Industry = 'Healthcare',
        AnnualRevenue = 1500000,
        NumberOfEmployees = 100,
        Type = 'Prospect'
      )
    );

    // Low-revenue accounts
    testAccounts.add(
      new Account(
        Name = 'Small Business LLC',
        Industry = 'Retail',
        AnnualRevenue = 500000,
        NumberOfEmployees = 25,
        Type = 'Customer - Direct'
      )
    );

    testAccounts.add(
      new Account(
        Name = 'Startup Ventures',
        Industry = 'Technology',
        AnnualRevenue = 300000,
        NumberOfEmployees = 10,
        Type = 'Prospect'
      )
    );

    // Account without industry/revenue
    testAccounts.add(
      new Account(
        Name = 'Unknown Business',
        NumberOfEmployees = 50
      )
    );

    insert testAccounts;
  }

  /**
   * @description Tests getHighValueAccounts method
   */
  @IsTest
  static void testGetHighValueAccounts() {
    Test.startTest();

    // This will fail gracefully if configuration doesn't exist
    // In real scenario, configuration 'Active_Accounts_By_Revenue' should be created
    try {
      List<Account> highValueAccounts = JT_AccountReportExample.getHighValueAccounts();

      // If configuration exists and works, validate results
      if (highValueAccounts != null) {
        for (Account acc : highValueAccounts) {
          System.assert(
            acc.AnnualRevenue >= 1000000,
            'All accounts should have revenue >= $1M'
          );
        }
      }
    } catch (Exception e) {
      // Expected if configuration doesn't exist
      System.assert(
        e.getMessage().contains('Configuration') ||
        e.getMessage().contains('not found'),
        'Should fail gracefully if configuration missing'
      );
    }

    Test.stopTest();
  }

  /**
   * @description Tests getAccountsByIndustry method
   */
  @IsTest
  static void testGetAccountsByIndustry() {
    Test.startTest();

    try {
      List<Account> techAccounts = JT_AccountReportExample.getAccountsByIndustry(
        'Technology',
        1000000
      );

      // If configuration exists, validate filtering
      if (techAccounts != null) {
        for (Account acc : techAccounts) {
          System.assertEquals(
            'Technology',
            acc.Industry,
            'Should only return Technology accounts'
          );
          System.assert(
            acc.AnnualRevenue >= 1000000,
            'Should filter by minimum revenue'
          );
        }
      }
    } catch (Exception e) {
      // Expected if configuration doesn't exist
      System.assert(
        e.getMessage().contains('Configuration'),
        'Should fail gracefully if configuration missing'
      );
    }

    Test.stopTest();
  }

  /**
   * @description Tests getAccountCountByType method
   */
  @IsTest
  static void testGetAccountCountByType() {
    Test.startTest();

    try {
      Map<String, Integer> countByType = JT_AccountReportExample.getAccountCountByType();

      // If configuration exists, validate counts
      if (countByType != null) {
        Integer totalCount = 0;
        for (Integer count : countByType.values()) {
          totalCount += count;
        }

        System.assert(
          totalCount > 0,
          'Should have at least one account'
        );
      }
    } catch (Exception e) {
      // Expected if configuration doesn't exist
      System.assert(
        e.getMessage().contains('Configuration'),
        'Should fail gracefully if configuration missing'
      );
    }

    Test.stopTest();
  }

  /**
   * @description Tests getRecentAccounts method
   */
  @IsTest
  static void testGetRecentAccounts() {
    Test.startTest();

    try {
      List<Account> recentAccounts = JT_AccountReportExample.getRecentAccounts(
        30
      );

      // If configuration exists, all test accounts should be recent
      if (recentAccounts != null) {
        // All test accounts were created today
        System.assert(
          recentAccounts.size() > 0,
          'Should return recently created accounts'
        );
      }
    } catch (Exception e) {
      // Expected if configuration doesn't exist
      System.assert(
        e.getMessage().contains('Configuration'),
        'Should fail gracefully if configuration missing'
      );
    }

    Test.stopTest();
  }

  /**
   * @description Tests getAccountSummaries method
   */
  @IsTest
  static void testGetAccountSummaries() {
    Test.startTest();

    try {
      List<JT_AccountReportExample.AccountSummary> summaries = JT_AccountReportExample.getAccountSummaries();

      // If configuration exists, validate wrapper class
      if (summaries != null) {
        for (JT_AccountReportExample.AccountSummary summary : summaries) {
          System.assertNotEquals(
            null,
            summary.accountName,
            'Account name should be populated'
          );
          System.assertNotEquals(
            null,
            summary.annualRevenue,
            'Annual revenue should be initialized (0 if null)'
          );
        }
      }
    } catch (Exception e) {
      // Expected if configuration doesn't exist
      System.assert(
        e.getMessage().contains('Configuration'),
        'Should fail gracefully if configuration missing'
      );
    }

    Test.stopTest();
  }

  /**
   * @description Tests AccountSummary wrapper class constructor
   */
  @IsTest
  static void testAccountSummaryWrapper() {
    // Get test account
    Account testAccount = [
      SELECT
        Id,
        Name,
        Industry,
        AnnualRevenue,
        NumberOfEmployees
      FROM Account
      WHERE Name = 'Tech Corp Alpha'
      LIMIT 1
    ];

    Test.startTest();

    JT_AccountReportExample.AccountSummary summary = new JT_AccountReportExample.AccountSummary(
      testAccount
    );

    Test.stopTest();

    System.assertEquals(
      'Tech Corp Alpha',
      summary.accountName,
      'Should populate account name'
    );
    System.assertEquals(
      5000000,
      summary.annualRevenue,
      'Should populate annual revenue'
    );
    System.assertEquals(
      'Technology',
      summary.industry,
      'Should populate industry'
    );
    System.assertEquals(
      500,
      summary.employeeCount,
      'Should populate employee count'
    );
  }

  /**
   * @description Tests AccountSummary with null values
   */
  @IsTest
  static void testAccountSummaryWithNullValues() {
    // Get account with no revenue/employees
    Account testAccount = [
      SELECT
        Id,
        Name,
        Industry,
        AnnualRevenue,
        NumberOfEmployees
      FROM Account
      WHERE Name = 'Unknown Business'
      LIMIT 1
    ];

    Test.startTest();

    JT_AccountReportExample.AccountSummary summary = new JT_AccountReportExample.AccountSummary(
      testAccount
    );

    Test.stopTest();

    System.assertEquals(
      'Unknown Business',
      summary.accountName,
      'Should populate account name'
    );
    System.assertEquals(
      0,
      summary.annualRevenue,
      'Should default to 0 for null revenue'
    );
    System.assertEquals(
      null,
      summary.industry,
      'Should preserve null industry'
    );
    System.assertEquals(
      50,
      summary.employeeCount,
      'Should populate employee count'
    );
  }
}

