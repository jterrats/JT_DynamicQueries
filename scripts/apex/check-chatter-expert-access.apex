// Script to check what access Chatter Expert has to Account
// Run this to understand why Run As User is showing 7 records

// 1. Get the Chatter Expert user
List<User> chatterUsers = [
  SELECT Id, Name, Username, Profile.Name, IsActive
  FROM User
  WHERE Profile.Name = 'Chatter Expert'
  AND IsActive = true
  LIMIT 1
];

if (chatterUsers.isEmpty()) {
  System.debug('❌ No active Chatter Expert user found');
  return;
}

User chatterUser = chatterUsers[0];
System.debug('✅ Found Chatter Expert user: ' + chatterUser.Name + ' (' + chatterUser.Username + ')');

// 2. Check Profile access to Account
List<ObjectPermissions> accountPerms = [
  SELECT PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete,
         PermissionsViewAllRecords, PermissionsModifyAllRecords
  FROM ObjectPermissions
  WHERE ParentId IN (
    SELECT PermissionSetId
    FROM PermissionSetAssignment
    WHERE AssigneeId = :chatterUser.Id
  )
  AND SObjectType = 'Account'
];

System.debug('📊 Account Permissions for Chatter Expert:');
for (ObjectPermissions perm : accountPerms) {
  System.debug('  - Read: ' + perm.PermissionsRead);
  System.debug('  - Create: ' + perm.PermissionsCreate);
  System.debug('  - Edit: ' + perm.PermissionsEdit);
  System.debug('  - Delete: ' + perm.PermissionsDelete);
  System.debug('  - View All: ' + perm.PermissionsViewAllRecords);
  System.debug('  - Modify All: ' + perm.PermissionsModifyAllRecords);
}

// 3. Run as the user and try to query Accounts
System.runAs(chatterUser) {
  Test.startTest();
  try {
    List<Account> accounts = [SELECT Id, Name FROM Account WITH USER_MODE LIMIT 10];
    System.debug('✅ Chatter Expert can access ' + accounts.size() + ' Account records:');
    for (Account acc : accounts) {
      System.debug('  - ' + acc.Name);
    }
  } catch (Exception e) {
    System.debug('❌ Chatter Expert cannot query Accounts: ' + e.getMessage());
  }
  Test.stopTest();
}

// 4. Check if they own any accounts
List<Account> ownedAccounts = [
  SELECT Id, Name, OwnerId
  FROM Account
  WHERE OwnerId = :chatterUser.Id
  LIMIT 10
];
System.debug('🏠 Accounts owned by Chatter Expert: ' + ownedAccounts.size());

System.debug('='.repeat(80));
System.debug('SUMMARY:');
System.debug('1. Does Profile have Read access? Check ObjectPermissions above');
System.debug('2. How many records accessible via System.runAs? Check count above');
System.debug('3. Are they the owner of any records? ' + ownedAccounts.size() + ' records');
System.debug('');
System.debug('If System.runAs shows 7 records, then Chatter Expert legitimately has access.');
System.debug('This could be due to:');
System.debug('- Profile having Account read permission');
System.debug('- Sharing rules giving access');
System.debug('- Account ownership');
System.debug('- Role hierarchy');
System.debug('='.repeat(80));

