/**
 * @description Test class for JT_QueryBindingUtil
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @date 2025-12-14
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexDoc')
private class JT_QueryBindingUtil_Test {
  /**
   * @description Test addWildcardsForLikeBindings with LIKE clause
   */
  @IsTest
  static void testAddWildcardsForLikeBindings() {
    String query = 'SELECT Id FROM Account WHERE Name LIKE :searchName';
    Map<String, Object> bindings = new Map<String, Object>{ 'searchName' => 'test' };

    Test.startTest();
    JT_QueryBindingUtil.addWildcardsForLikeBindings(query, bindings);
    Test.stopTest();

    System.assertEquals('%test%', bindings.get('searchName'), 'Should add wildcards');
  }

  /**
   * @description Test addWildcardsForLikeBindings with multiple LIKE clauses
   */
  @IsTest
  static void testAddWildcardsForLikeBindingsMultiple() {
    String query = 'SELECT Id FROM Account WHERE Name LIKE :name1 AND Industry LIKE :name2';
    Map<String, Object> bindings = new Map<String, Object>{
      'name1' => 'test1',
      'name2' => 'test2'
    };

    Test.startTest();
    JT_QueryBindingUtil.addWildcardsForLikeBindings(query, bindings);
    Test.stopTest();

    System.assertEquals('%test1%', bindings.get('name1'), 'First binding should have wildcards');
    System.assertEquals('%test2%', bindings.get('name2'), 'Second binding should have wildcards');
  }

  /**
   * @description Test addWildcardsForLikeBindings with case insensitive LIKE
   */
  @IsTest
  static void testAddWildcardsForLikeBindingsCaseInsensitive() {
    String query = 'SELECT Id FROM Account WHERE Name like :searchName';
    Map<String, Object> bindings = new Map<String, Object>{ 'searchName' => 'test' };

    Test.startTest();
    JT_QueryBindingUtil.addWildcardsForLikeBindings(query, bindings);
    Test.stopTest();

    System.assertEquals('%test%', bindings.get('searchName'), 'Should work with lowercase like');
  }

  /**
   * @description Test addWildcardsForLikeBindings does not modify bindings with existing wildcards
   */
  @IsTest
  static void testAddWildcardsForLikeBindingsWithExistingWildcards() {
    String query = 'SELECT Id FROM Account WHERE Name LIKE :searchName';
    Map<String, Object> bindings = new Map<String, Object>{ 'searchName' => '%test%' };

    Test.startTest();
    JT_QueryBindingUtil.addWildcardsForLikeBindings(query, bindings);
    Test.stopTest();

    System.assertEquals('%test%', bindings.get('searchName'), 'Should not modify existing wildcards');
  }

  /**
   * @description Test addWildcardsForLikeBindings does not modify bindings with underscore
   */
  @IsTest
  static void testAddWildcardsForLikeBindingsWithUnderscore() {
    String query = 'SELECT Id FROM Account WHERE Name LIKE :searchName';
    Map<String, Object> bindings = new Map<String, Object>{ 'searchName' => 'test_value' };

    Test.startTest();
    JT_QueryBindingUtil.addWildcardsForLikeBindings(query, bindings);
    Test.stopTest();

    System.assertEquals(
      'test_value',
      bindings.get('searchName'),
      'Should not modify values with underscore'
    );
  }

  /**
   * @description Test addWildcardsForLikeBindings with non-string binding (should not modify)
   */
  @IsTest
  static void testAddWildcardsForLikeBindingsNonString() {
    String query = 'SELECT Id FROM Account WHERE Name LIKE :searchName';
    Map<String, Object> bindings = new Map<String, Object>{ 'searchName' => 123 };

    Test.startTest();
    JT_QueryBindingUtil.addWildcardsForLikeBindings(query, bindings);
    Test.stopTest();

    System.assertEquals(123, bindings.get('searchName'), 'Non-string bindings should not be modified');
  }

  /**
   * @description Test addWildcardsForLikeBindings with null query (should return early)
   */
  @IsTest
  static void testAddWildcardsForLikeBindingsNullQuery() {
    Map<String, Object> bindings = new Map<String, Object>{ 'searchName' => 'test' };

    Test.startTest();
    JT_QueryBindingUtil.addWildcardsForLikeBindings(null, bindings);
    Test.stopTest();

    System.assertEquals('test', bindings.get('searchName'), 'Should not modify bindings');
  }

  /**
   * @description Test addWildcardsForLikeBindings with null bindings (should return early)
   */
  @IsTest
  static void testAddWildcardsForLikeBindingsNullBindings() {
    String query = 'SELECT Id FROM Account WHERE Name LIKE :searchName';

    Test.startTest();
    JT_QueryBindingUtil.addWildcardsForLikeBindings(query, null);
    Test.stopTest();

    // Should complete without error
    System.assert(true, 'Should handle null bindings gracefully');
  }

  /**
   * @description Test addWildcardsForLikeBindings with empty bindings (should return early)
   */
  @IsTest
  static void testAddWildcardsForLikeBindingsEmptyBindings() {
    String query = 'SELECT Id FROM Account WHERE Name LIKE :searchName';
    Map<String, Object> bindings = new Map<String, Object>();

    Test.startTest();
    JT_QueryBindingUtil.addWildcardsForLikeBindings(query, bindings);
    Test.stopTest();

    System.assertEquals(0, bindings.size(), 'Empty bindings should remain empty');
  }

  /**
   * @description Test addWildcardsForLikeBindings with binding not in query (should not modify)
   */
  @IsTest
  static void testAddWildcardsForLikeBindingsBindingNotInQuery() {
    String query = 'SELECT Id FROM Account WHERE Name = :name';
    Map<String, Object> bindings = new Map<String, Object>{ 'name' => 'test' };

    Test.startTest();
    JT_QueryBindingUtil.addWildcardsForLikeBindings(query, bindings);
    Test.stopTest();

    System.assertEquals('test', bindings.get('name'), 'Should not modify non-LIKE bindings');
  }

  /**
   * @description Test processBindings with valid JSON
   */
  @IsTest
  static void testProcessBindingsValid() {
    String query = 'SELECT Id FROM Account WHERE Name LIKE :searchName';
    String bindingsJson = '{"searchName": "test"}';

    Test.startTest();
    Map<String, Object> bindings = JT_QueryBindingUtil.processBindings(query, bindingsJson);
    Test.stopTest();

    System.assertNotEquals(null, bindings, 'Bindings should not be null');
    System.assertEquals('%test%', bindings.get('searchName'), 'Should add wildcards');
  }

  /**
   * @description Test processBindings with null JSON (should return empty map)
   */
  @IsTest
  static void testProcessBindingsNullJson() {
    String query = 'SELECT Id FROM Account WHERE Name LIKE :searchName';

    Test.startTest();
    Map<String, Object> bindings = JT_QueryBindingUtil.processBindings(query, null);
    Test.stopTest();

    System.assertNotEquals(null, bindings, 'Bindings should not be null');
    System.assertEquals(0, bindings.size(), 'Should return empty map');
  }

  /**
   * @description Test processBindings with empty JSON (should return empty map)
   */
  @IsTest
  static void testProcessBindingsEmptyJson() {
    String query = 'SELECT Id FROM Account WHERE Name LIKE :searchName';

    Test.startTest();
    Map<String, Object> bindings = JT_QueryBindingUtil.processBindings(query, '');
    Test.stopTest();

    System.assertNotEquals(null, bindings, 'Bindings should not be null');
    System.assertEquals(0, bindings.size(), 'Should return empty map');
  }

  /**
   * @description Test processBindings with multiple bindings
   */
  @IsTest
  static void testProcessBindingsMultiple() {
    String query = 'SELECT Id FROM Account WHERE Name LIKE :name AND Industry LIKE :industry';
    String bindingsJson = '{"name": "test", "industry": "tech"}';

    Test.startTest();
    Map<String, Object> bindings = JT_QueryBindingUtil.processBindings(query, bindingsJson);
    Test.stopTest();

    System.assertEquals('%test%', bindings.get('name'), 'First binding should have wildcards');
    System.assertEquals('%tech%', bindings.get('industry'), 'Second binding should have wildcards');
  }
}
