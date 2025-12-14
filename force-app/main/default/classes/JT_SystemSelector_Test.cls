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
}
