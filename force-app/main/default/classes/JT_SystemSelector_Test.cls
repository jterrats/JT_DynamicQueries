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
    System.assertNotEquals(null, org.OrganizationType, 'Should have organization type');
  }

  /**
   * @description Test getOrganizationType method
   */
  @IsTest
  static void testGetOrganizationType() {
    Test.startTest();
    String orgType = JT_SystemSelector.getOrganizationType();
    Test.stopTest();

    System.assertNotEquals(null, orgType, 'Organization type should not be null');
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
   * @description Test getFlowByIdQuery method
   */
  @IsTest
  static void testGetFlowByIdQuery() {
    String testFlowId = '301000000000000AAA';

    Test.startTest();
    String query = JT_SystemSelector.getFlowByIdQuery(testFlowId);
    Test.stopTest();

    System.assertNotEquals(null, query, 'Query should not be null');
    System.assert(query.contains('SELECT'), 'Should be a SELECT query');
    System.assert(query.contains('Flow'), 'Should query Flow');
    System.assert(query.contains(testFlowId), 'Should include flow ID in WHERE clause');
  }

  /**
   * @description Test getApexClassForTestQuery method
   */
  @IsTest
  static void testGetApexClassForTestQuery() {
    Test.startTest();
    String query = JT_SystemSelector.getApexClassForTestQuery();
    Test.stopTest();

    System.assertNotEquals(null, query, 'Query should not be null');
    System.assert(query.contains('SELECT'), 'Should be a SELECT query');
    System.assert(query.contains('ApexClass'), 'Should query ApexClass');
    System.assert(query.contains('JT_GenericRunAsTest'), 'Should filter by JT_GenericRunAsTest');
  }

  /**
   * @description Test getActiveFlows method
   */
  @IsTest
  static void testGetActiveFlows() {
    Test.startTest();
    List<Flow> flows = JT_SystemSelector.getActiveFlows();
    Test.stopTest();

    System.assertNotEquals(null, flows, 'Flows list should not be null');
    // May be empty depending on org, but should not throw error
  }

  /**
   * @description Test getFlowById method
   */
  @IsTest
  static void testGetFlowById() {
    // Use a fake flow ID - method should handle gracefully
    String fakeFlowId = '301000000000000AAA';

    Test.startTest();
    Flow flow = JT_SystemSelector.getFlowById(fakeFlowId);
    Test.stopTest();

    // May be null if flow doesn't exist, but should not throw error
    System.assert(true, 'Method should execute without error');
  }
}

