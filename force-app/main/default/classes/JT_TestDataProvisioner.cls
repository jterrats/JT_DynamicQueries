/**
 * @description Utility class to provision test data for Dynamic Query Framework configurations
 * @author Jaime Terrats
 * @date 2025-12-19
 *
 * This class creates test Account records that match the criteria defined in
 * the Dynamic Query Configuration custom metadata types.
 */
public inherited sharing class JT_TestDataProvisioner {
  /**
   * @description Helper method to add account only if it doesn't exist
   * @param accountsToInsert List to add account to
   * @param account Account to add
   * @param existingNames Set of existing account names
   * @param skipDuplicates Whether to skip duplicates
   */
  private static void addAccountIfNotExists(
    List<Account> accountsToInsert,
    Account account,
    Set<String> existingNames,
    Boolean skipDuplicates
  ) {
    if (!skipDuplicates || !existingNames.contains(account.Name)) {
      accountsToInsert.add(account);
    }
  }

  /**
   * @description Provisions test data for all query configurations
   * @return Integer Number of accounts created
   */
  public static Integer provisionAllTestData() {
    return provisionAllTestData(true);
  }

  /**
   * @description Provisions test data for all query configurations
   * @param skipDuplicates If true, skips accounts that already exist
   * @return Integer Number of accounts created
   */
  public static Integer provisionAllTestData(Boolean skipDuplicates) {
    List<Account> accountsToInsert = new List<Account>();

    // Get existing account names to avoid duplicates
    Set<String> existingNames = new Set<String>();
    if (skipDuplicates) {
      List<Account> existingAccounts = [
        SELECT Name
        FROM Account
        WITH USER_MODE
        LIMIT 1000
      ];
      for (Account acc : existingAccounts) {
        existingNames.add(acc.Name);
      }
    }

    // 1. Complex Mixed Operators Test
    // WHERE Industry IN :industries (Technology, Healthcare)
    // AND Type != :excludedType (Competitor)
    // AND AnnualRevenue >= :minRevenue (100000)
    // AND AnnualRevenue <= :maxRevenue (100000000)
    // AND (Name LIKE :namePattern OR Industry LIKE :industryPattern) (%Acme%, %Tech%)
    // AND NumberOfEmployees >= :minEmployees (10)
    // AND NumberOfEmployees <= :maxEmployees (100)
    // AND BillingCountry NOT IN :excludedCountries (Test Country)
    addAccountIfNotExists(
      accountsToInsert,
      new Account(
        Name = 'Acme Technology Solutions',
        Industry = 'Technology',
        Type = 'Customer - Direct',
        AnnualRevenue = 5000000,
        NumberOfEmployees = 50,
        BillingCountry = 'United States',
        BillingCity = 'San Francisco',
        BillingState = 'CA'
      ),
      existingNames,
      skipDuplicates
    );
    addAccountIfNotExists(
      accountsToInsert,
      new Account(
        Name = 'Acme Healthcare Systems',
        Industry = 'Healthcare',
        Type = 'Customer - Channel',
        AnnualRevenue = 15000000,
        NumberOfEmployees = 75,
        BillingCountry = 'United States',
        BillingCity = 'Boston',
        BillingState = 'MA'
      ),
      existingNames,
      skipDuplicates
    );
    addAccountIfNotExists(
      accountsToInsert,
      new Account(
        Name = 'Tech Innovations Inc',
        Industry = 'Technology',
        Type = 'Prospect',
        AnnualRevenue = 2500000,
        NumberOfEmployees = 25,
        BillingCountry = 'Canada',
        BillingCity = 'Toronto',
        BillingState = 'ON'
      ),
      existingNames,
      skipDuplicates
    );

    // 2. Complete Customer 360 View
    // WHERE Type =: accountType (Customer)
    addAccountIfNotExists(
      accountsToInsert,
      new Account(
        Name = 'Customer 360 Test Account',
        Type = 'Customer',
        Industry = 'Technology',
        AnnualRevenue = 10000000,
        NumberOfEmployees = 200,
        BillingCountry = 'United States',
        BillingCity = 'New York',
        BillingState = 'NY'
      ),
      existingNames,
      skipDuplicates
    );

    // 3. NOT Operators Test
    // WHERE Industry NOT IN :excludedIndustries
    // AND Type != :excludedType
    // AND AnnualRevenue NOT IN :excludedRevenues
    // AND Name NOT LIKE :excludedPattern
    // AND BillingCountry <> :excludedCountry
    addAccountIfNotExists(
      accountsToInsert,
      new Account(
        Name = 'Valid Account for NOT Test',
        Industry = 'Manufacturing',
        Type = 'Customer - Direct',
        AnnualRevenue = 3000000,
        NumberOfEmployees = 150,
        BillingCountry = 'United States',
        BillingCity = 'Chicago',
        BillingState = 'IL'
      ),
      existingNames,
      skipDuplicates
    );

    // 4. Multiple IN Operators Test
    // WHERE Id IN :accountIds
    // AND Industry IN :validIndustries
    // AND Type IN :accountTypes
    // AND BillingState IN :validStates
    // AND Name NOT IN :excludedNames
    addAccountIfNotExists(
      accountsToInsert,
      new Account(
        Name = 'IN Operators Test Account',
        Industry = 'Technology',
        Type = 'Customer - Direct',
        AnnualRevenue = 5000000,
        NumberOfEmployees = 100,
        BillingCountry = 'United States',
        BillingCity = 'Seattle',
        BillingState = 'WA'
      ),
      existingNames,
      skipDuplicates
    );
    addAccountIfNotExists(
      accountsToInsert,
      new Account(
        Name = 'Another IN Test Account',
        Industry = 'Healthcare',
        Type = 'Customer - Channel',
        AnnualRevenue = 8000000,
        NumberOfEmployees = 200,
        BillingCountry = 'United States',
        BillingCity = 'Los Angeles',
        BillingState = 'CA'
      ),
      existingNames,
      skipDuplicates
    );

    // 5. All Comparison Operators
    // WHERE AnnualRevenue = :exactRevenue
    // OR AnnualRevenue != :notEqualRevenue
    // OR AnnualRevenue < :lessThanRevenue
    // OR AnnualRevenue <= :lessThanOrEqual
    // OR AnnualRevenue > :greaterThanRevenue
    // OR AnnualRevenue >= :greaterThanOrEqual
    // OR CreatedDate = :exactDate
    // OR NumberOfEmployees <> :notEqualEmployees
    addAccountIfNotExists(
      accountsToInsert,
      new Account(
        Name = 'Comparison Operators Test 1',
        Industry = 'Technology',
        Type = 'Customer - Direct',
        AnnualRevenue = 1000000,
        NumberOfEmployees = 50,
        BillingCountry = 'United States',
        BillingCity = 'Austin',
        BillingState = 'TX'
      ),
      existingNames,
      skipDuplicates
    );
    addAccountIfNotExists(
      accountsToInsert,
      new Account(
        Name = 'Comparison Operators Test 2',
        Industry = 'Healthcare',
        Type = 'Prospect',
        AnnualRevenue = 5000000,
        NumberOfEmployees = 100,
        BillingCountry = 'United States',
        BillingCity = 'Denver',
        BillingState = 'CO'
      ),
      existingNames,
      skipDuplicates
    );

    // 6. Account By Name (Simple)
    // WHERE Name LIKE :searchName
    addAccountIfNotExists(
      accountsToInsert,
      new Account(
        Name = 'Test Account for Name Search',
        Industry = 'Technology',
        Type = 'Customer - Direct',
        AnnualRevenue = 2000000,
        NumberOfEmployees = 75,
        BillingCountry = 'United States',
        BillingCity = 'Portland',
        BillingState = 'OR',
        Phone = '555-0100',
        Website = 'https://testaccount.com'
      ),
      existingNames,
      skipDuplicates
    );

    // 7. LIKE Patterns Mixed
    // WHERE (Name LIKE :startsWith OR Name LIKE :endsWith)
    // AND Website LIKE :websitePattern
    // AND Phone LIKE :phonePattern
    // AND Description LIKE :descriptionKeyword
    addAccountIfNotExists(
      accountsToInsert,
      new Account(
        Name = 'StartsWith Test Company',
        Industry = 'Technology',
        Type = 'Customer - Direct',
        AnnualRevenue = 3000000,
        NumberOfEmployees = 80,
        BillingCountry = 'United States',
        BillingCity = 'Miami',
        BillingState = 'FL',
        Website = 'https://startswith.com',
        Phone = '555-1234',
        Description = 'This is a test company with specific keywords'
      ),
      existingNames,
      skipDuplicates
    );
    addAccountIfNotExists(
      accountsToInsert,
      new Account(
        Name = 'Company EndsWith Test',
        Industry = 'Healthcare',
        Type = 'Prospect',
        AnnualRevenue = 4000000,
        NumberOfEmployees = 90,
        BillingCountry = 'United States',
        BillingCity = 'Phoenix',
        BillingState = 'AZ',
        Website = 'https://endswith.org',
        Phone = '555-5678',
        Description = 'Another test company with keywords'
      ),
      existingNames,
      skipDuplicates
    );

    // 8. Dynamic Input Test
    // WHERE Type =: accountType AND Industry =: industry
    addAccountIfNotExists(
      accountsToInsert,
      new Account(
        Name = 'Dynamic Input Test Account',
        Type = 'Customer',
        Industry = 'Technology',
        AnnualRevenue = 6000000,
        NumberOfEmployees = 120,
        BillingCountry = 'United States',
        BillingCity = 'Atlanta',
        BillingState = 'GA'
      ),
      existingNames,
      skipDuplicates
    );

    // 9. Test Record
    // WHERE Name =: name (Test Account)
    addAccountIfNotExists(
      accountsToInsert,
      new Account(
        Name = 'Test Account',
        Industry = 'Technology',
        Type = 'Customer - Direct',
        AnnualRevenue = 1000000,
        NumberOfEmployees = 50,
        BillingCountry = 'United States',
        BillingCity = 'Dallas',
        BillingState = 'TX'
      ),
      existingNames,
      skipDuplicates
    );

    // Insert all accounts (handle duplicates gracefully)
    if (!accountsToInsert.isEmpty()) {
      Database.SaveResult[] results = Database.insert(accountsToInsert, false);
      Integer successCount = 0;
      for (Database.SaveResult result : results) {
        if (result.isSuccess()) {
          successCount++;
        } else {
          for (Database.Error error : result.getErrors()) {
            if (error.getStatusCode() != StatusCode.DUPLICATES_DETECTED) {
              System.debug(LoggingLevel.WARN, 'Error inserting account: ' + error.getMessage());
            }
          }
        }
      }
      return successCount;
    }
    return 0;
  }

  /**
   * @description Provisions test data specifically for Complex Mixed Operators query
   * @return List<Account> Created accounts
   */
  public static List<Account> provisionComplexMixedOperatorsData() {
    List<Account> accounts = new List<Account>();

    // Accounts that match: Industry IN (Technology, Healthcare)
    // Type != Competitor
    // AnnualRevenue >= 100000 AND <= 100000000
    // NumberOfEmployees >= 10 AND <= 100
    // BillingCountry NOT IN (Test Country)
    // Name LIKE %Acme% OR Industry LIKE %Tech%

    accounts.add(
      new Account(
        Name = 'Acme Technology Corp',
        Industry = 'Technology',
        Type = 'Customer - Direct',
        AnnualRevenue = 5000000,
        NumberOfEmployees = 50,
        BillingCountry = 'United States',
        BillingCity = 'San Francisco',
        BillingState = 'CA'
      )
    );

    accounts.add(
      new Account(
        Name = 'Acme Healthcare Systems',
        Industry = 'Healthcare',
        Type = 'Customer - Channel',
        AnnualRevenue = 15000000,
        NumberOfEmployees = 75,
        BillingCountry = 'United States',
        BillingCity = 'Boston',
        BillingState = 'MA'
      )
    );

    accounts.add(
      new Account(
        Name = 'Tech Innovations Inc',
        Industry = 'Technology',
        Type = 'Prospect',
        AnnualRevenue = 2500000,
        NumberOfEmployees = 25,
        BillingCountry = 'Canada',
        BillingCity = 'Toronto',
        BillingState = 'ON'
      )
    );

    accounts.add(
      new Account(
        Name = 'Healthcare Tech Solutions',
        Industry = 'Healthcare',
        Type = 'Customer - Direct',
        AnnualRevenue = 8000000,
        NumberOfEmployees = 60,
        BillingCountry = 'United States',
        BillingCity = 'Seattle',
        BillingState = 'WA'
      )
    );

    if (!accounts.isEmpty()) {
      Database.SaveResult[] results = Database.insert(accounts, false);
      List<Account> successfulAccounts = new List<Account>();
      for (Integer i = 0; i < results.size(); i++) {
        if (results[i].isSuccess()) {
          successfulAccounts.add(accounts[i]);
        }
      }
      return successfulAccounts;
    }
    return accounts;
  }

  /**
   * @description Cleans up test data (optional - use with caution)
   * @param accountNames List of account names to delete
   */
  @SuppressWarnings('PMD.ApexCRUDViolation')
  public static void cleanupTestData(List<String> accountNames) {
    List<Account> accountsToDelete = [
      SELECT Id
      FROM Account
      WHERE Name IN :accountNames
      WITH USER_MODE
    ];
    delete accountsToDelete;
  }
}

