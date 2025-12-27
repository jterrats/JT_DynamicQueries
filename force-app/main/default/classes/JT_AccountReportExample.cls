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
   * @description Searches accounts by name pattern
   * @param searchPattern Name pattern to search (e.g., '%Acme%')
   * @return List of matching Account records
   */
  public static List<Account> searchAccountsByName(String searchPattern) {
    // Use the Account_By_Name configuration
    Map<String, Object> bindings = new Map<String, Object>{
      'searchName' => searchPattern
    };

    List<SObject> results = JT_DataSelector.getRecords(
      'Account_By_Name', // Configuration DeveloperName
      true, // Enforce security (USER_MODE)
      bindings
    );

    return (List<Account>) results;
  }

  /**
   * @description Gets accounts by type and industry (demonstrates dynamic inputs)
   * @param accountType Account type (e.g., 'Customer', 'Partner', 'Prospect')
   * @param industry Industry to filter by (e.g., 'Technology', 'Healthcare')
   * @return List of matching Account records
   */
  public static List<Account> getAccountsByTypeAndIndustry(
    String accountType,
    String industry
  ) {
    Map<String, Object> bindings = new Map<String, Object>{
      'accountType' => accountType,
      'industry' => industry
    };

    List<SObject> results = JT_DataSelector.getRecords(
      'Dynamic_Input_Test', // Configuration DeveloperName
      true, // Enforce security
      bindings
    );

    return (List<Account>) results;
  }

  /**
   * @description Gets complete customer 360 view with child relationships
   * @param accountType Type of accounts to retrieve (default: 'Customer')
   * @return List of Account records with Contacts, Opportunities, Cases, and Contracts
   */
  public static List<Account> getCustomer360View(String accountType) {
    Map<String, Object> bindings = new Map<String, Object>{
      'accountType' => accountType
    };

    List<SObject> results = JT_DataSelector.getRecords(
      'Complete_Customer_360_View', // Complex query with child relationships
      true // Enforce security
    );

    return (List<Account>) results;
  }

  /**
   * @description Gets all customers for analysis (demonstrates Complex Query usage)
   * @return List of Customer Account records with full 360 view
   */
  public static List<Account> getAllCustomersForAnalysis() {
    // No bindings needed - uses default 'Customer' type from metadata
    List<SObject> results = JT_DataSelector.getRecords(
      'Complete_Customer_360_View', // Configuration with child relationships
      true // Enforce security
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
      this.annualRevenue = acc.AnnualRevenue != null ? acc.AnnualRevenue : 0;
      this.industry = acc.Industry;
      this.employeeCount = acc.NumberOfEmployees != null
        ? acc.NumberOfEmployees
        : 0;
    }
  }

  /**
   * @description Searches accounts by name pattern (cacheable for LWC)
   * @param searchPattern Name pattern to search
   * @return List of AccountSummary objects
   */
  @AuraEnabled(cacheable=true)
  public static List<AccountSummary> searchAccountsForLWC(
    String searchPattern
  ) {
    Map<String, Object> bindings = new Map<String, Object>{
      'searchName' => searchPattern
    };

    List<SObject> accounts = JT_DataSelector.getRecords(
      'Account_By_Name', // Simple search configuration
      true, // Enforce security
      bindings
    );

    List<AccountSummary> summaries = new List<AccountSummary>();
    for (SObject record : accounts) {
      summaries.add(new AccountSummary((Account) record));
    }

    return summaries;
  }
}
