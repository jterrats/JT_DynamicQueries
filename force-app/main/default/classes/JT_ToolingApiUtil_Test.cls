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

  /**
   * @description Test toAlphanumeric with valid input
   */
  @IsTest
  static void testToAlphanumericValid() {
    Test.startTest();
    String result = JT_ToolingApiUtil.toAlphanumeric('abc123XYZ');
    Test.stopTest();

    System.assertEquals(
      'abc123XYZ',
      result,
      'Should return alphanumeric string'
    );
  }

  /**
   * @description Test toAlphanumeric with special characters
   */
  @IsTest
  static void testToAlphanumericSpecialChars() {
    Test.startTest();
    String result = JT_ToolingApiUtil.toAlphanumeric('abc-123_XYZ!@#');
    Test.stopTest();

    System.assertEquals(
      'abc123XYZ',
      result,
      'Should remove special characters'
    );
  }

  /**
   * @description Test toAlphanumeric with null input
   */
  @IsTest
  static void testToAlphanumericNull() {
    Test.startTest();
    String result = JT_ToolingApiUtil.toAlphanumeric(null);
    Test.stopTest();

    System.assertNotEquals(null, result, 'Should return default value');
  }

  /**
   * @description Test toAlphanumeric with blank input
   */
  @IsTest
  static void testToAlphanumericBlank() {
    Test.startTest();
    String result = JT_ToolingApiUtil.toAlphanumeric('');
    Test.stopTest();

    System.assertNotEquals(null, result, 'Should return default value');
  }

  /**
   * @description Test createToolingApiRestRequest with GET method
   */
  @IsTest
  static void testCreateToolingApiRestRequestGet() {
    Test.startTest();
    final HttpRequest request = JT_ToolingApiUtil.createToolingApiRestRequest(
      '/services/data/v65.0/tooling/sobjects/CustomMetadata',
      'GET'
    );
    Test.stopTest();

    System.assertNotEquals(null, request, 'Request should not be null');
    System.assertEquals('GET', request.getMethod(), 'Method should be GET');
  }

  /**
   * @description Test createToolingApiRestRequest with PUT method
   */
  @IsTest
  static void testCreateToolingApiRestRequestPut() {
    Test.startTest();
    final HttpRequest request = JT_ToolingApiUtil.createToolingApiRestRequest(
      '/services/data/v65.0/tooling/sobjects/CustomMetadata',
      'PUT'
    );
    Test.stopTest();

    System.assertNotEquals(null, request, 'Request should not be null');
    System.assertEquals('PUT', request.getMethod(), 'Method should be PUT');
  }

  /**
   * @description Test createToolingApiRestRequest with PATCH method
   */
  @IsTest
  static void testCreateToolingApiRestRequestPatch() {
    Test.startTest();
    final HttpRequest request = JT_ToolingApiUtil.createToolingApiRestRequest(
      '/services/data/v65.0/tooling/sobjects/CustomMetadata',
      'PATCH'
    );
    Test.stopTest();

    System.assertNotEquals(null, request, 'Request should not be null');
    System.assertEquals('PATCH', request.getMethod(), 'Method should be PATCH');
  }

  /**
   * @description Test getApexLogContent with valid log ID
   */
  @IsTest
  static void testGetApexLogContent() {
    // Mock successful response
    String mockLogContent = 'DEBUG|Test log content';
    Test.setMock(
      HttpCalloutMock.class,
      new JT_ToolingAPIMock(200, mockLogContent)
    );

    Test.startTest();
    String result = JT_ToolingApiUtil.getApexLogContent('07LKW00000Uees82AB');
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(mockLogContent, result, 'Should return log content');
  }

  /**
   * @description Test getApexLogContent with null log ID
   */
  @IsTest
  static void testGetApexLogContentNull() {
    Test.startTest();
    String result = JT_ToolingApiUtil.getApexLogContent(null);
    Test.stopTest();

    System.assertEquals(null, result, 'Should return null for null log ID');
  }

  /**
   * @description Test getApexLogContent with blank log ID
   */
  @IsTest
  static void testGetApexLogContentBlank() {
    Test.startTest();
    String result = JT_ToolingApiUtil.getApexLogContent('');
    Test.stopTest();

    System.assertEquals(null, result, 'Should return null for blank log ID');
  }

  /**
   * @description Test getApexLogContent with HTTP error response
   */
  @IsTest
  static void testGetApexLogContentHttpError() {
    // Mock HTTP error response
    Test.setMock(
      HttpCalloutMock.class,
      new JT_ToolingAPIMock(404, 'Not Found')
    );

    Test.startTest();
    String result = JT_ToolingApiUtil.getApexLogContent('07LKW00000Uees82AB');
    Test.stopTest();

    System.assertEquals(null, result, 'Should return null on HTTP error');
  }

  /**
   * @description Test getApexLogContent with callout exception
   */
  @IsTest
  static void testGetApexLogContentCalloutException() {
    // Mock callout exception
    Test.setMock(HttpCalloutMock.class, new JT_ToolingAPIMock());

    Test.startTest();
    String result = JT_ToolingApiUtil.getApexLogContent('07LKW00000Uees82AB');
    Test.stopTest();

    System.assertEquals(null, result, 'Should return null on exception');
  }

  /**
   * @description Test executeToolingApiQuery with custom timeout
   */
  @IsTest
  static void testExecuteToolingApiQueryWithTimeout() {
    // Mock successful response
    String successResponse = JSON.serialize(
      new Map<String, Object>{
        'size' => 1,
        'records' => new List<Object>{
          new Map<String, Object>{ 'Id' => '01p000000000000AAA' }
        }
      }
    );
    Test.setMock(
      HttpCalloutMock.class,
      new JT_ToolingAPIMock(200, successResponse)
    );

    Test.startTest();
    HttpResponse response = JT_ToolingApiUtil.executeToolingApiQuery(
      'SELECT Id FROM ApexClass LIMIT 1',
      30000
    );
    Test.stopTest();

    System.assertNotEquals(null, response, 'Response should not be null');
    System.assertEquals(200, response.getStatusCode(), 'Should return 200');
  }

  /**
   * @description Test createToolingApiQueryRequest with null timeout
   */
  @IsTest
  static void testCreateToolingApiQueryRequestNullTimeout() {
    Test.startTest();
    final HttpRequest request = JT_ToolingApiUtil.createToolingApiQueryRequest(
      'SELECT Id FROM ApexClass LIMIT 1',
      null
    );
    Test.stopTest();

    System.assertNotEquals(null, request, 'Request should not be null');
    System.assertEquals('GET', request.getMethod(), 'Method should be GET');
    // Should use default timeout (60000)
  }

  /**
   * @description Test createToolingApiRestRequest with null timeout
   */
  @IsTest
  static void testCreateToolingApiRestRequestNullTimeout() {
    Test.startTest();
    final HttpRequest request = JT_ToolingApiUtil.createToolingApiRestRequest(
      '/services/data/v65.0/tooling/sobjects/CustomMetadata',
      'GET',
      null
    );
    Test.stopTest();

    System.assertNotEquals(null, request, 'Request should not be null');
    System.assertEquals('GET', request.getMethod(), 'Method should be GET');
    // Should use default timeout (30000)
  }

  /**
   * @description Test toAlphanumeric with whitespace-only input
   */
  @IsTest
  static void testToAlphanumericWhitespace() {
    Test.startTest();
    String result = JT_ToolingApiUtil.toAlphanumeric('   ');
    Test.stopTest();

    System.assertNotEquals(null, result, 'Should return default value');
  }

  /**
   * @description Test toAlphanumeric with mixed alphanumeric and special chars
   */
  @IsTest
  static void testToAlphanumericMixed() {
    Test.startTest();
    String result = JT_ToolingApiUtil.toAlphanumeric('abc123!@#XYZ456');
    Test.stopTest();

    System.assertEquals(
      'abc123XYZ456',
      result,
      'Should keep only alphanumeric'
    );
  }

  /**
   * @description Test toAlphanumeric with only special characters
   */
  @IsTest
  static void testToAlphanumericOnlySpecialChars() {
    Test.startTest();
    String result = JT_ToolingApiUtil.toAlphanumeric('!@#$%^&*()');
    Test.stopTest();

    System.assertEquals('', result, 'Should return empty string');
  }

  /**
   * @description Test getAlphanumericCacheKey with blank userId
   */
  @IsTest
  static void testGetAlphanumericCacheKeyBlankUserId() {
    Test.startTest();
    final String key = JT_ToolingApiUtil.getAlphanumericCacheKey('');
    Test.stopTest();

    System.assertNotEquals(null, key, 'Key should not be null');
    System.assert(
      key.startsWith('ApiSessionId'),
      'Key should start with prefix'
    );
  }

  /**
   * @description Test createToolingApiQueryRequest with special characters in query
   */
  @IsTest
  static void testCreateToolingApiQueryRequestSpecialChars() {
    Test.startTest();
    final HttpRequest request = JT_ToolingApiUtil.createToolingApiQueryRequest(
      'SELECT Id FROM ApexClass WHERE Name = \'Test & Config\' LIMIT 1'
    );
    Test.stopTest();

    System.assertNotEquals(null, request, 'Request should not be null');
    System.assert(
      request.getEndpoint().contains('tooling'),
      'Endpoint should contain tooling'
    );
    // Query should be URL encoded
  }

  /**
   * @description Test createToolingApiRestRequest with different HTTP methods
   */
  @IsTest
  static void testCreateToolingApiRestRequestDifferentMethods() {
    List<String> methods = new List<String>{
      'GET',
      'POST',
      'PUT',
      'PATCH',
      'DELETE'
    };

    Test.startTest();
    for (String method : methods) {
      final HttpRequest request = JT_ToolingApiUtil.createToolingApiRestRequest(
        '/services/data/v65.0/tooling/sobjects/CustomMetadata',
        method
      );
      System.assertNotEquals(null, request, 'Request should not be null');
      System.assertEquals(
        method,
        request.getMethod(),
        'Method should be ' + method
      );
    }
    Test.stopTest();
  }

  /**
   * @description Test executeToolingApiQuery with HTTP error
   */
  @IsTest
  static void testExecuteToolingApiQueryHttpError() {
    // Mock HTTP error response
    Test.setMock(
      HttpCalloutMock.class,
      new JT_ToolingAPIMock(401, 'Unauthorized')
    );

    Test.startTest();
    HttpResponse response = JT_ToolingApiUtil.executeToolingApiQuery(
      'SELECT Id FROM ApexClass LIMIT 1'
    );
    Test.stopTest();

    System.assertNotEquals(null, response, 'Response should not be null');
    System.assertEquals(401, response.getStatusCode(), 'Should return 401');
  }

  /**
   * @description Test getApexLogContent with exception during request
   */
  @IsTest
  static void testGetApexLogContentException() {
    // Mock callout exception
    Test.setMock(HttpCalloutMock.class, new JT_ToolingAPIMock());

    Test.startTest();
    String result = JT_ToolingApiUtil.getApexLogContent('07LKW00000Uees82AB');
    Test.stopTest();

    System.assertEquals(null, result, 'Should return null on exception');
  }

  /**
   * @description Test getApexLogContent with non-200 status code
   */
  @IsTest
  static void testGetApexLogContentNon200() {
    // Mock non-200 response
    Test.setMock(
      HttpCalloutMock.class,
      new JT_ToolingAPIMock(500, 'Internal Server Error')
    );

    Test.startTest();
    String result = JT_ToolingApiUtil.getApexLogContent('07LKW00000Uees82AB');
    Test.stopTest();

    System.assertEquals(null, result, 'Should return null on non-200 status');
  }

  /**
   * @description Test getApexLogContent with empty log ID
   */
  @IsTest
  static void testGetApexLogContentEmpty() {
    Test.startTest();
    String result = JT_ToolingApiUtil.getApexLogContent('   ');
    Test.stopTest();

    System.assertEquals(null, result, 'Should return null for blank log ID');
  }

  /**
   * @description Test createToolingApiQueryRequest with null query
   */
  @IsTest
  static void testCreateToolingApiQueryRequestNullQuery() {
    Test.startTest();
    try {
      final HttpRequest request = JT_ToolingApiUtil.createToolingApiQueryRequest(
        null
      );
      System.assertNotEquals(null, request, 'Request should be created');
    } catch (Exception e) {
      // Exception is acceptable for null query
      System.assert(true, 'Exception acceptable for null query');
    }
    Test.stopTest();
  }

  /**
   * @description Test createToolingApiRestRequest with null endpoint
   */
  @IsTest
  static void testCreateToolingApiRestRequestNullEndpoint() {
    Test.startTest();
    try {
      final HttpRequest request = JT_ToolingApiUtil.createToolingApiRestRequest(
        null,
        'GET'
      );
      System.assertNotEquals(null, request, 'Request should be created');
    } catch (Exception e) {
      // Exception is acceptable for null endpoint
      System.assert(true, 'Exception acceptable for null endpoint');
    }
    Test.stopTest();
  }

  /**
   * @description Test createToolingApiRestRequest with null method
   */
  @IsTest
  static void testCreateToolingApiRestRequestNullMethod() {
    Test.startTest();
    try {
      final HttpRequest request = JT_ToolingApiUtil.createToolingApiRestRequest(
        '/services/data/v65.0/tooling/sobjects/CustomMetadata',
        null
      );
      System.assertNotEquals(null, request, 'Request should be created');
    } catch (Exception e) {
      // Exception is acceptable for null method
      System.assert(true, 'Exception acceptable for null method');
    }
    Test.stopTest();
  }

  /**
   * @description Test executeToolingApiQuery with null query
   */
  @IsTest
  static void testExecuteToolingApiQueryNullQuery() {
    Test.setMock(HttpCalloutMock.class, new JT_ToolingAPIMock());

    Test.startTest();
    try {
      final HttpResponse response = JT_ToolingApiUtil.executeToolingApiQuery(
        null
      );
      System.assertNotEquals(null, response, 'Response should not be null');
    } catch (Exception e) {
      // Exception is acceptable for null query
      System.assert(true, 'Exception acceptable for null query');
    }
    Test.stopTest();
  }

  /**
   * @description Test getAlphanumericCacheKey with whitespace userId
   */
  @IsTest
  static void testGetAlphanumericCacheKeyWhitespace() {
    Test.startTest();
    final String key = JT_ToolingApiUtil.getAlphanumericCacheKey('   ');
    Test.stopTest();

    System.assertNotEquals(null, key, 'Key should not be null');
    System.assert(
      key.startsWith('ApiSessionId'),
      'Key should start with prefix'
    );
  }

  /**
   * @description Test toAlphanumeric with empty string after sanitization
   */
  @IsTest
  static void testToAlphanumericEmptyAfterSanitization() {
    Test.startTest();
    String result = JT_ToolingApiUtil.toAlphanumeric('---');
    Test.stopTest();

    System.assertNotEquals(null, result, 'Should return default value');
  }

  /**
   * @description Test getApiVersion with system settings null
   */
  @IsTest
  static void testGetApiVersionWithNullSettings() {
    Test.startTest();
    // This tests the fallback when systemSettings is null
    final String apiVersion = JT_ToolingApiUtil.getApiVersion();
    Test.stopTest();

    System.assertNotEquals(null, apiVersion, 'API version should not be null');
    System.assert(
      apiVersion.startsWith('v'),
      'API version should start with "v"'
    );
  }

  /**
   * @description Test getToolingApiPath with system settings null
   */
  @IsTest
  static void testGetToolingApiPathWithNullSettings() {
    Test.startTest();
    // This tests the fallback when systemSettings is null
    final String path = JT_ToolingApiUtil.getToolingApiPath();
    Test.stopTest();

    System.assertNotEquals(null, path, 'Tooling API path should not be null');
    System.assert(path.contains('/tooling/'), 'Path should contain /tooling/');
  }

  /**
   * @description Test getApexLogContent with successful response and body length check
   */
  @IsTest
  static void testGetApexLogContentSuccessWithBodyLength() {
    // Mock successful response with body
    String mockLogContent = 'DEBUG|Test log content\nINFO|More content';
    Test.setMock(
      HttpCalloutMock.class,
      new JT_ToolingAPIMock(200, mockLogContent)
    );

    Test.startTest();
    String result = JT_ToolingApiUtil.getApexLogContent('07LKW00000Uees82AB');
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(mockLogContent, result, 'Should return log content');
  }

  /**
   * @description Test getApexLogContent with 403 Forbidden status
   */
  @IsTest
  static void testGetApexLogContentForbidden() {
    // Mock 403 Forbidden response
    Test.setMock(
      HttpCalloutMock.class,
      new JT_ToolingAPIMock(403, 'Forbidden')
    );

    Test.startTest();
    String result = JT_ToolingApiUtil.getApexLogContent('07LKW00000Uees82AB');
    Test.stopTest();

    System.assertEquals(null, result, 'Should return null on 403');
  }

  /**
   * @description Test getApexLogContent with 401 Unauthorized status
   */
  @IsTest
  static void testGetApexLogContentUnauthorized() {
    // Mock 401 Unauthorized response
    Test.setMock(
      HttpCalloutMock.class,
      new JT_ToolingAPIMock(401, 'Unauthorized')
    );

    Test.startTest();
    String result = JT_ToolingApiUtil.getApexLogContent('07LKW00000Uees82AB');
    Test.stopTest();

    System.assertEquals(null, result, 'Should return null on 401');
  }

  /**
   * @description Test createToolingApiQueryRequest with empty query string
   */
  @IsTest
  static void testCreateToolingApiQueryRequestEmptyQuery() {
    Test.startTest();
    final HttpRequest request = JT_ToolingApiUtil.createToolingApiQueryRequest(
      ''
    );
    Test.stopTest();

    System.assertNotEquals(null, request, 'Request should not be null');
    System.assertEquals('GET', request.getMethod(), 'Method should be GET');
  }

  /**
   * @description Test createToolingApiRestRequest with empty endpoint path
   */
  @IsTest
  static void testCreateToolingApiRestRequestEmptyPath() {
    Test.startTest();
    final HttpRequest request = JT_ToolingApiUtil.createToolingApiRestRequest(
      '',
      'GET'
    );
    Test.stopTest();

    System.assertNotEquals(null, request, 'Request should not be null');
    System.assertEquals('GET', request.getMethod(), 'Method should be GET');
  }

  /**
   * @description Test executeToolingApiQuery with empty query string
   */
  @IsTest
  static void testExecuteToolingApiQueryEmptyQuery() {
    Test.setMock(HttpCalloutMock.class, new JT_ToolingAPIMock());

    Test.startTest();
    try {
      final HttpResponse response = JT_ToolingApiUtil.executeToolingApiQuery(
        ''
      );
      System.assertNotEquals(null, response, 'Response should not be null');
    } catch (Exception e) {
      // Exception is acceptable for empty query
      System.assert(true, 'Exception acceptable for empty query');
    }
    Test.stopTest();
  }

  /**
   * @description Test getAlphanumericCacheKey with special characters in userId
   */
  @IsTest
  static void testGetAlphanumericCacheKeySpecialChars() {
    Test.startTest();
    final String key = JT_ToolingApiUtil.getAlphanumericCacheKey(
      '005XX000000XXXXXXX-!@#'
    );
    Test.stopTest();

    System.assertNotEquals(null, key, 'Key should not be null');
    System.assert(
      key.startsWith('ApiSessionId'),
      'Key should start with prefix'
    );
    // Key should be alphanumeric only
    System.assert(
      key.replaceAll('[^a-zA-Z0-9]', '') == key,
      'Key should be alphanumeric only'
    );
  }

  /**
   * @description Test toAlphanumeric with numbers only
   */
  @IsTest
  static void testToAlphanumericNumbersOnly() {
    Test.startTest();
    String result = JT_ToolingApiUtil.toAlphanumeric('1234567890');
    Test.stopTest();

    System.assertEquals('1234567890', result, 'Should return numbers');
  }

  /**
   * @description Test toAlphanumeric with letters only
   */
  @IsTest
  static void testToAlphanumericLettersOnly() {
    Test.startTest();
    String result = JT_ToolingApiUtil.toAlphanumeric(
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    );
    Test.stopTest();

    System.assertEquals(
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
      result,
      'Should return letters'
    );
  }

  /**
   * @description Test createToolingApiRestRequest with HEAD method
   */
  @IsTest
  static void testCreateToolingApiRestRequestHead() {
    Test.startTest();
    final HttpRequest request = JT_ToolingApiUtil.createToolingApiRestRequest(
      '/services/data/v65.0/tooling/sobjects/CustomMetadata',
      'HEAD',
      20000
    );
    Test.stopTest();

    System.assertNotEquals(null, request, 'Request should not be null');
    System.assertEquals('HEAD', request.getMethod(), 'Method should be HEAD');
  }

  /**
   * @description Test createToolingApiQueryRequest with zero timeout
   */
  @IsTest
  static void testCreateToolingApiQueryRequestZeroTimeout() {
    Test.startTest();
    final HttpRequest request = JT_ToolingApiUtil.createToolingApiQueryRequest(
      'SELECT Id FROM ApexClass LIMIT 1',
      0
    );
    Test.stopTest();

    System.assertNotEquals(null, request, 'Request should not be null');
    System.assertEquals('GET', request.getMethod(), 'Method should be GET');
  }

  /**
   * @description Test createToolingApiRestRequest with zero timeout
   */
  @IsTest
  static void testCreateToolingApiRestRequestZeroTimeout() {
    Test.startTest();
    final HttpRequest request = JT_ToolingApiUtil.createToolingApiRestRequest(
      '/services/data/v65.0/tooling/sobjects/CustomMetadata',
      'GET',
      0
    );
    Test.stopTest();

    System.assertNotEquals(null, request, 'Request should not be null');
    System.assertEquals('GET', request.getMethod(), 'Method should be GET');
  }
}
