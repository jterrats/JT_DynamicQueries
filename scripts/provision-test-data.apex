// Script to provision test data for Dynamic Query Framework configurations
// Execute this in Developer Console > Debug > Open Execute Anonymous Window
// Or via: sf apex run --file scripts/provision-test-data.apex

// Provision all test data (skips duplicates)
Integer accountsCreated = JT_TestDataProvisioner.provisionAllTestData(true);
System.debug('✅ Created ' + accountsCreated + ' test accounts');

// Verify Complex Mixed Operators data specifically (skips duplicates)
List<Account> complexAccounts = JT_TestDataProvisioner.provisionComplexMixedOperatorsData();
System.debug('✅ Created ' + complexAccounts.size() + ' accounts for Complex Mixed Operators query');

System.debug('✅ Test data provisioning complete!');
System.debug('You can now test the queries in the Dynamic Query Framework UI.');

