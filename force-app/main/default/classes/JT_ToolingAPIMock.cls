/**
 * @description HTTP Callout Mock for Tooling API testing
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @last modified on 11-29-2025
 * @last modified by Jaime Terrats
 **/
@IsTest
public class JT_ToolingAPIMock implements HttpCalloutMock {
  private Integer statusCode;
  private String responseBody;
  private Boolean throwException;

  /**
   * @description Constructor with success response
   * @param statusCode HTTP status code
   * @param responseBody Response body
   **/
  public JT_ToolingAPIMock(Integer statusCode, String responseBody) {
    this.statusCode = statusCode;
    this.responseBody = responseBody;
    this.throwException = false;
  }

  /**
   * @description Constructor for exception scenario
   **/
  public JT_ToolingAPIMock() {
    this.throwException = true;
  }

  /**
   * @description Responds to HTTP callout
   * @param request HTTP request
   * @return HTTPResponse
   **/
  public HTTPResponse respond(HTTPRequest request) {
    if (throwException) {
      throw new CalloutException('Mock HTTP exception');
    }

    HTTPResponse response = new HTTPResponse();
    response.setStatusCode(statusCode);
    response.setBody(responseBody);
    response.setHeader('Content-Type', 'application/json');
    return response;
  }

  /**
   * @description Creates success response for metadata creation
   * @return JT_ToolingAPIMock
   **/
  public static JT_ToolingAPIMock createMetadataSuccess() {
    String responseBody = '{"id": "0afXXXXXXXXXXXX", "success": true}';
    return new JT_ToolingAPIMock(201, responseBody);
  }

  /**
   * @description Creates error response for metadata creation
   * @return JT_ToolingAPIMock
   **/
  public static JT_ToolingAPIMock createMetadataError() {
    String responseBody = '{"message": "Metadata API error", "errorCode": "INVALID_METADATA"}';
    return new JT_ToolingAPIMock(400, responseBody);
  }
}
