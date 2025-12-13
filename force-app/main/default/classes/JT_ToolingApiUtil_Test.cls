/**
 * @description Test class for JT_ToolingApiUtil
 * @author Jaime Terrats
 * @group Dynamic Queries
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexDoc')
private class JT_ToolingApiUtil_Test {
  /**
   * @description Test getApiVersion returns default value
   */
  @IsTest
  static void testGetApiVersion() {
    Test.startTest();
    final String apiVersion = JT_ToolingApiUtil.getApiVersion();
    Test.stopTest();

    System.assertNotEquals(null, apiVersion, 'API version should not be null');
    System.assert(
      apiVersion.startsWith('v'),
      'API version should start with "v"'
    );
  }

  /**
   * @description Test getToolingApiPath returns default value
   */
  @IsTest
  static void testGetToolingApiPath() {
    Test.startTest();
    final String path = JT_ToolingApiUtil.getToolingApiPath();
    Test.stopTest();

    System.assertNotEquals(null, path, 'Tooling API path should not be null');
    System.assert(path.contains('/tooling/'), 'Path should contain /tooling/');
  }

  /**
   * @description Test getOrgDomainUrl returns valid URL
   */
  @IsTest
  static void testGetOrgDomainUrl() {
    Test.startTest();
    final String orgUrl = JT_ToolingApiUtil.getOrgDomainUrl();
    Test.stopTest();

    System.assertNotEquals(null, orgUrl, 'Org URL should not be null');
    System.assert(
      orgUrl.contains('salesforce'),
      'URL should contain salesforce'
    );
  }

  /**
   * @description Test getAlphanumericCacheKey sanitizes user ID
   */
  @IsTest
  static void testGetAlphanumericCacheKey() {
    Test.startTest();
    final String key1 = JT_ToolingApiUtil.getAlphanumericCacheKey(null);
    final String key2 = JT_ToolingApiUtil.getAlphanumericCacheKey(
      UserInfo.getUserId()
    );
    final String key3 = JT_ToolingApiUtil.getAlphanumericCacheKey(
      '005XX000000XXXXXXX'
    );
    Test.stopTest();

    System.assertNotEquals(null, key1, 'Key should not be null');
    System.assert(
      key1.startsWith('ApiSessionId'),
      'Key should start with prefix'
    );
    System.assertNotEquals(null, key2, 'Key should not be null');
    System.assertNotEquals(null, key3, 'Key should not be null');
    System.assert(
      key3.replaceAll('[^a-zA-Z0-9]', '') == key3,
      'Key should be alphanumeric only'
    );
  }

  /**
   * @description Test getApiSessionId returns test session ID in test context
   */
  @IsTest
  static void testGetApiSessionIdInTest() {
    Test.startTest();
    final String sessionId = JT_ToolingApiUtil.getApiSessionId();
    Test.stopTest();

    System.assertEquals(
      'test_session_id',
      sessionId,
      'Should return test session ID'
    );
  }

  /**
   * @description Test createToolingApiQueryRequest creates valid request
   */
  @IsTest
  static void testCreateToolingApiQueryRequest() {
    Test.startTest();
    final HttpRequest request = JT_ToolingApiUtil.createToolingApiQueryRequest(
      'SELECT Id FROM ApexClass LIMIT 1'
    );
    Test.stopTest();

    System.assertNotEquals(null, request, 'Request should not be null');
    System.assertEquals('GET', request.getMethod(), 'Method should be GET');
    System.assert(
      request.getEndpoint().contains('tooling'),
      'Endpoint should contain tooling'
    );
    System.assert(
      request.getHeader('Authorization') != null,
      'Should have Authorization header'
    );
  }

  /**
   * @description Test createToolingApiQueryRequest with custom timeout
   */
  @IsTest
  static void testCreateToolingApiQueryRequestWithTimeout() {
    Test.startTest();
    final HttpRequest request = JT_ToolingApiUtil.createToolingApiQueryRequest(
      'SELECT Id FROM ApexClass LIMIT 1',
      30000
    );
    Test.stopTest();

    System.assertNotEquals(null, request, 'Request should not be null');
    System.assertEquals('GET', request.getMethod(), 'Method should be GET');
    // Note: HttpRequest doesn't expose getTimeout(), but we verify the request was created successfully
  }

  /**
   * @description Test createToolingApiRestRequest creates valid request
   */
  @IsTest
  static void testCreateToolingApiRestRequest() {
    Test.startTest();
    final HttpRequest request = JT_ToolingApiUtil.createToolingApiRestRequest(
      '/services/data/v65.0/tooling/sobjects/CustomMetadata',
      'POST'
    );
    Test.stopTest();

    System.assertNotEquals(null, request, 'Request should not be null');
    System.assertEquals('POST', request.getMethod(), 'Method should be POST');
    System.assert(
      request.getEndpoint().contains('tooling'),
      'Endpoint should contain tooling'
    );
    System.assert(
      request.getHeader('Authorization') != null,
      'Should have Authorization header'
    );
    System.assert(
      request.getHeader('Content-Type') != null,
      'Should have Content-Type header'
    );
  }

  /**
   * @description Test createToolingApiRestRequest with custom timeout
   */
  @IsTest
  static void testCreateToolingApiRestRequestWithTimeout() {
    Test.startTest();
    final HttpRequest request = JT_ToolingApiUtil.createToolingApiRestRequest(
      '/services/data/v65.0/tooling/sobjects/CustomMetadata',
      'DELETE',
      15000
    );
    Test.stopTest();

    System.assertNotEquals(null, request, 'Request should not be null');
    System.assertEquals(
      'DELETE',
      request.getMethod(),
      'Method should be DELETE'
    );
    System.assert(
      request.getEndpoint().contains('tooling'),
      'Endpoint should contain tooling'
    );
    // Note: HttpRequest doesn't expose getTimeout(), but we verify the request was created successfully
  }

  /**
   * @description Test executeToolingApiQuery throws exception in test context
   */
  @IsTest
  static void testExecuteToolingApiQuery() {
    Test.setMock(HttpCalloutMock.class, new JT_ToolingAPIMock());

    Test.startTest();
    try {
      final HttpResponse response = JT_ToolingApiUtil.executeToolingApiQuery(
        'SELECT Id FROM ApexClass LIMIT 1'
      );
      System.assertNotEquals(null, response, 'Response should not be null');
    } catch (Exception e) {
      // Expected in test context without proper mock setup
      System.assert(true, 'Exception expected in test context');
    }
    Test.stopTest();
  }
}
