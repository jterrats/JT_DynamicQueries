/**
 * Setup script for E2E tests
 * Creates test data and assigns permission set to current user
 */

// 1. Assign Permission Set to current user
String userId = UserInfo.getUserId();
String permSetName = 'JT_Dynamic_Queries';

List<PermissionSetAssignment> existingAssignments = [
    SELECT Id
    FROM PermissionSetAssignment
    WHERE PermissionSet.Name = :permSetName
    AND AssigneeId = :userId
    LIMIT 1
];

if (existingAssignments.isEmpty()) {
    PermissionSet ps = [
        SELECT Id, Name
        FROM PermissionSet
        WHERE Name = :permSetName
        LIMIT 1
    ];

    insert new PermissionSetAssignment(
        PermissionSetId = ps.Id,
        AssigneeId = userId
    );
    System.debug('✅ Permission Set assigned to user: ' + UserInfo.getUserName());
} else {
    System.debug('✅ User already has Permission Set: ' + UserInfo.getUserName());
}

// 2. Create test Account for "Test Record" configuration
String testAccountName = 'Test Account';
List<Account> existingAccounts = [
    SELECT Id, Name
    FROM Account
    WHERE Name = :testAccountName
    LIMIT 1
];

if (existingAccounts.isEmpty()) {
    Account testAccount = new Account(
        Name = testAccountName,
        Type = 'Prospect',
        Industry = 'Technology',
        Description = 'Test account for Dynamic Queries E2E tests'
    );
    insert testAccount;
    System.debug('✅ Test Account created: ' + testAccount.Id);
} else {
    System.debug('✅ Test Account already exists: ' + existingAccounts[0].Id);
}

// 3. Create additional test Accounts for pagination and dynamic input testing
List<Account> paginationAccounts = new List<Account>();
String[] industries = new String[]{'Technology', 'Finance', 'Healthcare', 'Manufacturing', 'Retail'};
String[] types = new String[]{'Customer', 'Prospect', 'Partner', 'Customer'};

for (Integer i = 1; i <= 15; i++) {
    paginationAccounts.add(new Account(
        Name = 'Dynamic Test Account ' + i,
        Type = types[Math.mod(i, types.size())],
        Industry = industries[Math.mod(i, industries.size())],
        Phone = '555-010' + String.valueOf(i).leftPad(2, '0'),
        Website = 'www.testaccount' + i + '.com',
        BillingCity = 'San Francisco',
        AnnualRevenue = 100000 * i
    ));
}

// Check if test accounts already exist
Integer existingTestCount = [
    SELECT COUNT()
    FROM Account
    WHERE Name LIKE 'Dynamic Test Account%'
];

if (existingTestCount < 15) {
    // Delete old test accounts if any
    List<Account> oldTestAccounts = [
        SELECT Id
        FROM Account
        WHERE Name LIKE 'Dynamic Test Account%' OR Name LIKE 'Pagination Test Account%'
    ];
    if (!oldTestAccounts.isEmpty()) {
        delete oldTestAccounts;
    }

    // Insert new ones
    insert paginationAccounts;
    System.debug('✅ Created 15 test Accounts with various Types and Industries');
} else {
    System.debug('✅ Test Accounts already exist (' + existingTestCount + ')');
}

// 4. Summary
System.debug('');
System.debug('═══════════════════════════════════════════════════');
System.debug('✅ SETUP COMPLETE - Ready for E2E Tests');
System.debug('═══════════════════════════════════════════════════');
System.debug('User: ' + UserInfo.getUserName());
System.debug('Permission Set: ' + permSetName);
System.debug('Test Accounts Created: ' + (existingAccounts.isEmpty() ? '1' : '0 (already exists)'));
System.debug('Test Accounts (various types): ' + (existingTestCount < 15 ? '15' : existingTestCount + ' (already exist)'));
System.debug('═══════════════════════════════════════════════════');

