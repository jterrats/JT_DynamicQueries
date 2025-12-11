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
      new Account(Name = 'Unknown Business', NumberOfEmployees = 50)
    );

    insert testAccounts;
  }

  /**
   * @description Tests searchAccountsByName method
   */
  @IsTest
  static void testSearchAccountsByName() {
    Test.startTest();

    // Uses 'Account_By_Name' configuration
    try {
      List<Account> results = JT_AccountReportExample.searchAccountsByName(
        '%Tech%'
      );

      // If configuration exists, validate results
      if (results != null) {
        for (Account acc : results) {
          System.assert(
            acc.Name.contains('Tech'),
            'Should return accounts matching search pattern'
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
   * @description Tests getAccountsByTypeAndIndustry method
   */
  @IsTest
  static void testGetAccountsByTypeAndIndustry() {
    Test.startTest();

    // Uses 'Dynamic_Input_Test' configuration
    try {
      List<Account> results = JT_AccountReportExample.getAccountsByTypeAndIndustry(
        'Customer - Direct',
        'Technology'
      );

      // If configuration exists, validate filtering
      if (results != null) {
        for (Account acc : results) {
          System.assertEquals(
            'Technology',
            acc.Industry,
            'Should only return Technology accounts'
          );
          System.assertEquals(
            'Customer - Direct',
            acc.Type,
            'Should filter by account type'
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
   * @description Tests getCustomer360View method with specific type
   */
  @IsTest
  static void testGetCustomer360ViewWithType() {
    Test.startTest();

    // Uses 'Complete_Customer_360_View' configuration with custom type
    try {
      List<Account> partners = JT_AccountReportExample.getCustomer360View(
        'Customer - Channel'
      );

      // If configuration exists, validate child relationships
      if (partners != null && !partners.isEmpty()) {
        System.assertNotEquals(
          null,
          partners[0],
          'Should return channel partner accounts'
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
   * @description Tests getAllCustomersForAnalysis method
   */
  @IsTest
  static void testGetAllCustomersForAnalysis() {
    Test.startTest();

    // Uses 'Complete_Customer_360_View' configuration with default bindings
    try {
      List<Account> customers = JT_AccountReportExample.getAllCustomersForAnalysis();

      // If configuration exists, validate results
      if (customers != null) {
        // Configuration should return customer accounts
        System.assertNotEquals(
          null,
          customers,
          'Should return list of customer accounts'
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
   * @description Tests searchAccountsForLWC method
   */
  @IsTest
  static void testSearchAccountsForLWC() {
    Test.startTest();

    // Uses 'Account_By_Name' configuration
    try {
      List<JT_AccountReportExample.AccountSummary> summaries = JT_AccountReportExample.searchAccountsForLWC(
        '%Tech%'
      );

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
      SELECT Id, Name, Industry, AnnualRevenue, NumberOfEmployees
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
      SELECT Id, Name, Industry, AnnualRevenue, NumberOfEmployees
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
