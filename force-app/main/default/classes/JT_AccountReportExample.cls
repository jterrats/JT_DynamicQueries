/**
 * @description Example class demonstrating JT_DataSelector usage
 * @author Jaime Terrats
 * @date 2025-12-11
 *
 * This class serves as a practical example of how to use Dynamic Queries
 * in your Apex code. It demonstrates:
 * - Retrieving data using configuration names
 * - Processing results with business logic
 * - Using bind variables for dynamic filtering
 *
 * This class will be detected by "Where is this used?" feature.
 */
public with sharing class JT_AccountReportExample {
  /**
   * @description Generates a report of high-value accounts
   * @return List of Account records with Annual Revenue > $1M
   */
  public static List<Account> getHighValueAccounts() {
    // Use the JT_DataSelector configuration
    Map<String, Object> bindings = new Map<String, Object>{
      'minRevenue' => 1000000
    };

    List<SObject> results = JT_DataSelector.getRecords(
      'Active_Accounts_By_Revenue', // Configuration DeveloperName
      true, // Enforce security (USER_MODE)
      bindings
    );

    return (List<Account>) results;
  }

  /**
   * @description Gets accounts by industry with revenue filtering
   * @param industry Industry to filter by (e.g., 'Technology', 'Healthcare')
   * @param minRevenue Minimum annual revenue threshold
   * @return List of matching Account records
   */
  public static List<Account> getAccountsByIndustry(
    String industry,
    Decimal minRevenue
  ) {
    Map<String, Object> bindings = new Map<String, Object>{
      'industry' => industry,
      'minRevenue' => minRevenue
    };

    List<SObject> results = JT_DataSelector.getRecords(
      'Accounts_By_Industry', // Configuration DeveloperName
      true, // Enforce security
      bindings
    );

    return (List<Account>) results;
  }

  /**
   * @description Counts total accounts by type
   * @return Map of Account Type to Count
   */
  public static Map<String, Integer> getAccountCountByType() {
    // This uses a configuration without bind variables
    List<SObject> allAccounts = JT_DataSelector.getRecords(
      'All_Active_Accounts', // Simple configuration
      true // Enforce security
    );

    Map<String, Integer> countByType = new Map<String, Integer>();

    for (SObject record : allAccounts) {
      Account acc = (Account) record;
      String accountType = String.isNotBlank(acc.Type) ? acc.Type : 'Unknown';

      if (!countByType.containsKey(accountType)) {
        countByType.put(accountType, 0);
      }

      countByType.put(accountType, countByType.get(accountType) + 1);
    }

    return countByType;
  }

  /**
   * @description Gets recently created accounts
   * @param daysBack Number of days to look back
   * @return List of recently created Account records
   */
  public static List<Account> getRecentAccounts(Integer daysBack) {
    Date startDate = Date.today().addDays(-daysBack);

    Map<String, Object> bindings = new Map<String, Object>{
      'startDate' => startDate
    };

    List<SObject> results = JT_DataSelector.getRecords(
      'Recent_Accounts', // Configuration DeveloperName
      true, // Enforce security
      bindings
    );

    return (List<Account>) results;
  }

  /**
   * @description Wrapper class for account summary data
   */
  public class AccountSummary {
    @AuraEnabled
    public String accountName { get; set; }
    @AuraEnabled
    public Decimal annualRevenue { get; set; }
    @AuraEnabled
    public String industry { get; set; }
    @AuraEnabled
    public Integer employeeCount { get; set; }

    public AccountSummary(Account acc) {
      this.accountName = acc.Name;
      this.annualRevenue = acc.AnnualRevenue != null
        ? acc.AnnualRevenue
        : 0;
      this.industry = acc.Industry;
      this.employeeCount = acc.NumberOfEmployees != null
        ? acc.NumberOfEmployees
        : 0;
    }
  }

  /**
   * @description Gets account summary data for reporting
   * @return List of AccountSummary objects
   */
  @AuraEnabled(cacheable=true)
  public static List<AccountSummary> getAccountSummaries() {
    List<SObject> accounts = JT_DataSelector.getRecords(
      'Account_Summary', // Configuration for summary data
      true // Enforce security
    );

    List<AccountSummary> summaries = new List<AccountSummary>();
    for (SObject record : accounts) {
      summaries.add(new AccountSummary((Account) record));
    }

    return summaries;
  }
}

