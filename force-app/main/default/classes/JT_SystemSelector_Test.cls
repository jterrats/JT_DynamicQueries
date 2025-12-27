/**
 * @description Test class for JT_SystemSelector
 * @author Jaime Terrats
 * @date 2025-12-13
 * @group Dynamic Queries
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexDoc')
private class JT_SystemSelector_Test {
  /**
   * @description Test getOrganizationInfo method
   */
  @IsTest
  static void testGetOrganizationInfo() {
    Test.startTest();
    Organization org = JT_SystemSelector.getOrganizationInfo();
    Test.stopTest();

    System.assertNotEquals(null, org, 'Organization should not be null');
    System.assertNotEquals(
      null,
      org.OrganizationType,
      'Should have organization type'
    );
  }

  /**
   * @description Test getOrganizationType method
   */
  @IsTest
  static void testGetOrganizationType() {
    Test.startTest();
    Organization org = JT_SystemSelector.getOrganizationType();
    Test.stopTest();

    System.assertNotEquals(null, org, 'Organization should not be null');
    System.assertNotEquals(
      null,
      org.OrganizationType,
      'Organization type should not be null'
    );
  }

  /**
   * @description Test getToolingApiTestQuery method
   */
  @IsTest
  static void testGetToolingApiTestQuery() {
    Test.startTest();
    String query = JT_SystemSelector.getToolingApiTestQuery();
    Test.stopTest();

    System.assertNotEquals(null, query, 'Query should not be null');
    System.assert(query.contains('SELECT'), 'Should be a SELECT query');
    System.assert(query.contains('ApexClass'), 'Should query ApexClass');
  }

  /**
   * @description Test getActiveFlowsQuery method
   */
  @IsTest
  static void testGetActiveFlowsQuery() {
    Test.startTest();
    String query = JT_SystemSelector.getActiveFlowsQuery();
    Test.stopTest();

    System.assertNotEquals(null, query, 'Query should not be null');
    System.assert(query.contains('SELECT'), 'Should be a SELECT query');
    System.assert(query.contains('Flow'), 'Should query Flow');
    System.assert(query.contains('Status'), 'Should filter by Status');
  }

  /**
   * @description Test getApexClassForTestQuery method
   */
  @IsTest
  static void testGetApexClassForTestQuery() {
    Test.startTest();
    List<ApexClass> apexClasses = JT_SystemSelector.getApexClassForTestQuery();
    Test.stopTest();

    System.assertNotEquals(
      null,
      apexClasses,
      'ApexClasses list should not be null'
    );
    // May be empty depending on org, but should not throw error
  }

  /**
   * @description Test getApexClassByName with valid class name
   */
  @IsTest
  static void testGetApexClassByNameValid() {
    Test.startTest();
    ApexClass apexClass = JT_SystemSelector.getApexClassByName(
      'JT_SystemSelector'
    );
    Test.stopTest();

    System.assertNotEquals(null, apexClass, 'ApexClass should not be null');
    System.assertEquals(
      'JT_SystemSelector',
      apexClass.Name,
      'Should return correct class'
    );
  }

  /**
   * @description Test getApexClassByName with non-existent class
   */
  @IsTest
  static void testGetApexClassByNameNonExistent() {
    Test.startTest();
    ApexClass apexClass = JT_SystemSelector.getApexClassByName(
      'NonExistentClass12345'
    );
    Test.stopTest();

    System.assertEquals(
      null,
      apexClass,
      'Should return null for non-existent class'
    );
  }

  /**
   * @description Test getApexClassByName with null input
   */
  @IsTest
  static void testGetApexClassByNameNull() {
    Test.startTest();
    ApexClass apexClass = JT_SystemSelector.getApexClassByName(null);
    Test.stopTest();

    System.assertEquals(null, apexClass, 'Should return null for null input');
  }

  /**
   * @description Test getUserById with valid user ID
   */
  @IsTest
  static void testGetUserByIdValid() {
    Test.startTest();
    User user = JT_SystemSelector.getUserById(UserInfo.getUserId());
    Test.stopTest();

    System.assertNotEquals(null, user, 'User should not be null');
    System.assertEquals(
      UserInfo.getUserId(),
      user.Id,
      'Should return correct user'
    );
  }

  /**
   * @description Test getUserById with non-existent user ID
   */
  @IsTest
  static void testGetUserByIdNonExistent() {
    Test.startTest();
    try {
      JT_SystemSelector.getUserById('005000000000000AAA');
      System.assert(false, 'Should have thrown exception');
    } catch (Exception e) {
      System.assert(true, 'Exception thrown as expected');
    }
    Test.stopTest();
  }

  /**
   * @description Test getAllActiveUsers method
   */
  @IsTest
  static void testGetAllActiveUsers() {
    Test.startTest();
    List<User> users = JT_SystemSelector.getAllActiveUsers();
    Test.stopTest();

    System.assertNotEquals(null, users, 'Users list should not be null');
    System.assert(users.size() > 0, 'Should return at least one active user');
  }

  /**
   * @description Test getUserProfile method
   */
  @IsTest
  static void testGetUserProfile() {
    Test.startTest();
    Profile profile = JT_SystemSelector.getUserProfile();
    Test.stopTest();

    System.assertNotEquals(null, profile, 'Profile should not be null');
    System.assertEquals(
      UserInfo.getProfileId(),
      profile.Id,
      'Should return current user profile'
    );
  }

  /**
   * @description Test getPermissionSetAssignments method
   */
  @IsTest
  static void testGetPermissionSetAssignments() {
    Test.startTest();
    List<PermissionSetAssignment> assignments = JT_SystemSelector.getPermissionSetAssignments(
      UserInfo.getUserId()
    );
    Test.stopTest();

    System.assertNotEquals(
      null,
      assignments,
      'Assignments list should not be null'
    );
  }

  /**
   * @description Test hasElevatedPermissions method
   */
  @IsTest
  static void testHasElevatedPermissions() {
    Test.startTest();
    Boolean hasElevated = JT_SystemSelector.hasElevatedPermissions(
      UserInfo.getUserId()
    );
    Test.stopTest();

    System.assertNotEquals(null, hasElevated, 'Should return boolean value');
  }

  /**
   * @description Test getSystemSettings method
   */
  @IsTest
  static void testGetSystemSettings() {
    Test.startTest();
    JT_SystemSettings__mdt settings = JT_SystemSelector.getSystemSettings(
      'Default'
    );
    Test.stopTest();

    System.assertNotEquals(null, settings, 'Settings should not be null');
  }

  /**
   * @description Test getFlowMetadataQuery method
   */
  @IsTest
  static void testGetFlowMetadataQuery() {
    Test.startTest();
    String query = JT_SystemSelector.getFlowMetadataQuery('301000000000000AAA');
    Test.stopTest();

    System.assertNotEquals(null, query, 'Query should not be null');
    System.assert(query.contains('SELECT'), 'Should be a SELECT query');
    System.assert(query.contains('Flow'), 'Should query Flow');
  }

  /**
   * @description Test getApexClassesForUsageSearch method
   */
  @IsTest
  static void testGetApexClassesForUsageSearch() {
    Test.startTest();
    List<ApexClass> classes = JT_SystemSelector.getApexClassesForUsageSearch();
    Test.stopTest();

    System.assertNotEquals(null, classes, 'Classes list should not be null');
  }

  /**
   * @description Test getCurrentUser method
   */
  @IsTest
  static void testGetCurrentUser() {
    Test.startTest();
    User currentUser = JT_SystemSelector.getCurrentUser();
    Test.stopTest();

    System.assertNotEquals(
      null,
      currentUser,
      'Current user should not be null'
    );
    System.assertEquals(
      UserInfo.getUserId(),
      currentUser.Id,
      'Should return current user'
    );
  }

  /**
   * @description Test getOrganizationInfoWithName method
   */
  @IsTest
  static void testGetOrganizationInfoWithName() {
    Test.startTest();
    Organization org = JT_SystemSelector.getOrganizationInfoWithName();
    Test.stopTest();

    System.assertNotEquals(null, org, 'Organization should not be null');
    System.assertNotEquals(null, org.Name, 'Should have organization name');
  }

  /**
   * @description Test getExecutionById with valid ID
   */
  @IsTest
  static void testGetExecutionById() {
    // Create test execution
    JT_RunAsTest_Execution__c testExecution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Running',
      Config_Name__c = 'Test_Record',
      User_To_Impersonate__c = UserInfo.getUserId(),
      Initiated_By__c = UserInfo.getUserId()
    );
    insert testExecution;

    Test.startTest();
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getExecutionById(
      testExecution.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, execution, 'Execution should not be null');
    System.assertEquals(
      testExecution.Id,
      execution.Id,
      'Should return correct execution'
    );
  }

  /**
   * @description Test getExecutionById with non-existent ID
   */
  @IsTest
  static void testGetExecutionByIdNonExistent() {
    String fakeId = 'a0X' + '0'.repeat(15);

    Test.startTest();
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getExecutionById(
      fakeId
    );
    Test.stopTest();

    System.assertEquals(
      null,
      execution,
      'Should return null for non-existent ID'
    );
  }

  /**
   * @description Test getExecutionWithAllFields with valid ID
   */
  @IsTest
  static void testGetExecutionWithAllFields() {
    // Create test execution
    JT_RunAsTest_Execution__c testExecution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Running',
      Config_Name__c = 'Test_Record',
      User_To_Impersonate__c = UserInfo.getUserId(),
      Initiated_By__c = UserInfo.getUserId(),
      Bindings_Json__c = '{"name": "Test"}'
    );
    insert testExecution;

    Test.startTest();
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getExecutionWithAllFields(
      testExecution.Id
    );
    Test.stopTest();

    System.assertNotEquals(null, execution, 'Execution should not be null');
    System.assertEquals(
      testExecution.Id,
      execution.Id,
      'Should return correct execution'
    );
    System.assertNotEquals(
      null,
      execution.Test_Status__c,
      'Should have Test_Status__c'
    );
  }

  /**
   * @description Test getTestExecution helper method
   */
  @IsTest
  static void testGetTestExecution() {
    // Create test execution
    JT_RunAsTest_Execution__c testExecution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Running',
      Config_Name__c = 'Test_Record',
      User_To_Impersonate__c = UserInfo.getUserId(),
      Initiated_By__c = UserInfo.getUserId()
    );
    insert testExecution;

    Test.startTest();
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getTestExecution();
    Test.stopTest();

    System.assertNotEquals(null, execution, 'Execution should not be null');
    System.assertEquals(
      testExecution.Id,
      execution.Id,
      'Should return test execution'
    );
  }

  /**
   * @description Test getTestExecutionWithAllFields helper method
   */
  @IsTest
  static void testGetTestExecutionWithAllFields() {
    // Create test execution
    JT_RunAsTest_Execution__c testExecution = new JT_RunAsTest_Execution__c(
      Test_Status__c = 'Running',
      Config_Name__c = 'Test_Record',
      User_To_Impersonate__c = UserInfo.getUserId(),
      Initiated_By__c = UserInfo.getUserId(),
      Bindings_Json__c = '{"name": "Test"}'
    );
    insert testExecution;

    Test.startTest();
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getTestExecutionWithAllFields();
    Test.stopTest();

    System.assertNotEquals(null, execution, 'Execution should not be null');
    System.assertEquals(
      testExecution.Id,
      execution.Id,
      'Should return test execution'
    );
    System.assertNotEquals(
      null,
      execution.Test_Status__c,
      'Should have Test_Status__c'
    );
  }

  /**
   * @description Test getTestExecution with no executions
   */
  @IsTest
  static void testGetTestExecutionNoExecutions() {
    Test.startTest();
    JT_RunAsTest_Execution__c execution = JT_SystemSelector.getTestExecution();
    Test.stopTest();

    // Should return null if no executions exist
    System.assertEquals(
      null,
      execution,
      'Should return null when no executions exist'
    );
  }
}
