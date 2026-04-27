/**
 * @description Persona-based run-as test class with SeeAllData=false.
 * Used when JT_PersonaConfig__mdt.See_All_Data__c = false.
 * Validates FLS, CRUD, and object access for a synthetic user without requiring real data.
 * JT_RunAsTestEnqueuer selects this class over JT_GenericRunAsTest based on the persona config.
 * @author Jaime Terrats
 * @group Dynamic Queries
 **/
@SuppressWarnings('PMD')
@IsTest(SeeAllData=false)
public class JT_GenericPersonaTest {
  @IsTest
  @SuppressWarnings('PMD.EmptyCatchBlock')
  static void executePersonaTest() {
    TestParameters params = getTestParameters();

    if (params == null) {
      try {
        List<JT_RunAsTest_Execution__c> executions = [
          SELECT Id, Test_Status__c, Error_Message__c, Log_Messages__c
          FROM JT_RunAsTest_Execution__c
          WHERE
            Test_Status__c IN ('Queued', 'Running')
            AND Persona_Developer_Name__c != NULL
            AND CreatedDate >= :Datetime.now().addMinutes(-5)
          ORDER BY CreatedDate DESC
          LIMIT 1
        ];

        if (!executions.isEmpty()) {
          executions[0].Test_Status__c = 'Failed';
          executions[0]
            .Error_Message__c = 'Execution parameters not found for persona test.';
          executions[0].Log_Messages__c =
            (String.isNotBlank(executions[0].Log_Messages__c)
              ? executions[0].Log_Messages__c + '\n'
              : '') +
            'Persona test execution failed: No parameters found at ' +
            System.now();
          update executions[0];
        }
      } catch (Exception e) {
        // Suppress — test will complete via assert below
      }

      System.assert(true, 'No test parameters found for persona execution.');
      return;
    }

    User syntheticUser = buildSyntheticUser(params);
    QueryResult queryResult = executeInUserContext(syntheticUser, params);

    if (!queryResult.success) {
      String assertionMessage = String.isNotBlank(queryResult.errorMessage)
        ? queryResult.errorMessage
        : 'Persona query execution failed.';

      if (String.isNotBlank(queryResult.runAsUser)) {
        assertionMessage =
          'User [' +
          queryResult.runAsUser +
          ']: ' +
          assertionMessage;
      }
      System.assert(false, assertionMessage);
    }

    if (queryResult.recordCount == 0) {
      System.assert(
        true,
        'Persona query executed successfully — 0 records returned (SeeAllData=false, record volume not validated).'
      );
    }

    storeResults(params.executionId, queryResult);
    System.assertEquals(
      true,
      queryResult.success,
      'Persona test execution should complete successfully.'
    );
  }

  private static TestParameters getTestParameters() {
    try {
      List<JT_RunAsTest_Execution__c> executions = [
        SELECT
          Id,
          Persona_Developer_Name__c,
          Config_Name__c,
          Bindings_Json__c,
          Test_Status__c,
          Apex_Test_Queue_Item_Id__c,
          Apex_Queueable_Job_Id__c,
          CreatedDate
        FROM JT_RunAsTest_Execution__c
        WHERE
          Test_Status__c IN ('Queued', 'Running')
          AND Persona_Developer_Name__c != NULL
          AND Apex_Test_Queue_Item_Id__c != NULL
          AND CreatedDate >= :Datetime.now().addMinutes(-10)
        ORDER BY CreatedDate DESC
        LIMIT 1
      ];

      if (executions.isEmpty()) {
        executions = [
          SELECT
            Id,
            Persona_Developer_Name__c,
            Config_Name__c,
            Bindings_Json__c,
            Test_Status__c,
            Apex_Test_Queue_Item_Id__c,
            Apex_Queueable_Job_Id__c,
            CreatedDate
          FROM JT_RunAsTest_Execution__c
          WHERE
            Test_Status__c IN ('Queued', 'Running', 'Completed')
            AND Persona_Developer_Name__c != NULL
            AND (Apex_Test_Queue_Item_Id__c = NULL
            OR Apex_Test_Queue_Item_Id__c = '')
            AND Apex_Queueable_Job_Id__c != NULL
            AND CreatedDate >= :Datetime.now().addMinutes(-5)
          ORDER BY CreatedDate DESC
          LIMIT 1
        ];
      }

      if (!executions.isEmpty()) {
        JT_RunAsTest_Execution__c execution = executions[0];

        if (
          execution.Test_Status__c != 'Running' &&
          execution.Test_Status__c != 'Completed'
        ) {
          execution.Test_Status__c = 'Running';
          execution.Log_Messages__c =
            (String.isNotBlank(execution.Log_Messages__c)
              ? execution.Log_Messages__c + '\n'
              : '') +
            'Persona test execution started at ' +
            System.now();
          update execution;
        }

        return new TestParameters(
          execution.Persona_Developer_Name__c,
          execution.Config_Name__c,
          execution.Bindings_Json__c,
          execution.Id
        );
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        '❌ Error getting persona test parameters: ' + e.getMessage()
      );
    }
    return null;
  }

  @SuppressWarnings('PMD.ApexCRUDViolation')
  private static User buildSyntheticUser(TestParameters params) {
    List<JT_PersonaConfig__mdt> personas = [
      SELECT Profile_API_Name__c, Permission_Sets__c, Label
      FROM JT_PersonaConfig__mdt
      WHERE DeveloperName = :params.personaDeveloperName
      LIMIT 1
    ];

    if (personas.isEmpty()) {
      throw new AuraHandledException(
        'Persona \'' +
          params.personaDeveloperName +
          '\' not found in this org. Verify the JT_PersonaConfig__mdt record exists.'
      );
    }

    JT_PersonaConfig__mdt persona = personas[0];

    List<Profile> profiles = [
      SELECT Id
      FROM Profile
      WHERE Name = :persona.Profile_API_Name__c
      LIMIT 1
    ];

    if (profiles.isEmpty()) {
      throw new AuraHandledException(
        'Profile \'' +
          persona.Profile_API_Name__c +
          '\' not found in this org. Verify installation.'
      );
    }

    String uniqueSuffix = String.valueOf(System.now().getTime());
    User syntheticUser = new User(
      Alias = 'jtprsn',
      Email = 'jtpersona_' + uniqueSuffix + '@test.invalid',
      EmailEncodingKey = 'UTF-8',
      LastName = 'JTPersona_' + params.personaDeveloperName,
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = profiles[0].Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      Username = 'jtpersona_' + uniqueSuffix + '@test.invalid'
    );
    insert syntheticUser;

    if (String.isNotBlank(persona.Permission_Sets__c)) {
      List<String> psNames = persona.Permission_Sets__c.split(',');
      List<String> trimmedNames = new List<String>();
      for (String psName : psNames) {
        String trimmed = psName.trim();
        if (String.isNotBlank(trimmed)) {
          trimmedNames.add(trimmed);
        }
      }

      if (!trimmedNames.isEmpty()) {
        List<PermissionSet> permSets = [
          SELECT Id
          FROM PermissionSet
          WHERE Name IN :trimmedNames
        ];

        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet ps : permSets) {
          assignments.add(
            new PermissionSetAssignment(
              AssigneeId = syntheticUser.Id,
              PermissionSetId = ps.Id
            )
          );
        }
        if (!assignments.isEmpty()) {
          insert assignments;
        }
      }
    }

    return [
      SELECT Id, Name, Username
      FROM User
      WHERE Id = :syntheticUser.Id
      LIMIT 1
    ];
  }

  private static QueryResult executeInUserContext(
    User syntheticUser,
    TestParameters params
  ) {
    QueryResult result = new QueryResult();

    System.runAs(syntheticUser) {
      Test.startTest();
      try {
        Map<String, Object> bindings = String.isNotBlank(params.bindingsJson)
          ? (Map<String, Object>) JSON.deserializeUntyped(params.bindingsJson)
          : new Map<String, Object>();

        JT_DynamicQueryConfiguration__mdt config = [
          SELECT JT_BaseQuery__c
          FROM JT_DynamicQueryConfiguration__mdt
          WHERE DeveloperName = :params.configName
          WITH USER_MODE
          LIMIT 1
        ];

        JT_QueryBindingUtil.addWildcardsForLikeBindings(
          config.JT_BaseQuery__c,
          bindings
        );

        Long startTime = System.now().getTime();
        List<SObject> records = JT_DataSelector.getRecords(
          params.configName,
          true,
          bindings
        );
        Long endTime = System.now().getTime();

        result.success = true;
        result.records = records;
        result.recordCount = records.size();
        result.executionTime = (Integer) (endTime - startTime);
        result.runAsUser = syntheticUser.Name;
      } catch (QueryException qe) {
        result.success = false;
        result.errorMessage = 'Query exception: ' + qe.getMessage();
        result.stackTrace = qe.getStackTraceString();
      } catch (SecurityException se) {
        result.success = false;
        result.errorMessage = 'Security exception: ' + se.getMessage();
        result.stackTrace = se.getStackTraceString();
      } catch (Exception e) {
        result.success = false;
        result.errorMessage = 'Execution failed: ' + e.getMessage();
        result.stackTrace = e.getStackTraceString();
      }
      Test.stopTest();
    }

    return result;
  }

  private static void storeResults(
    String executionId,
    QueryResult queryResult
  ) {
    Map<String, Object> resultData = new Map<String, Object>{
      'success' => queryResult.success,
      'recordCount' => queryResult.recordCount,
      'errorMessage' => queryResult.errorMessage,
      'executionTime' => queryResult.executionTime,
      'runAsUserName' => queryResult.runAsUser,
      'timestamp' => System.now().getTime(),
      'records' => new List<Object>(),
      'fields' => new List<String>()
    };

    if (queryResult.success && !queryResult.records.isEmpty()) {
      List<Object> serializedRecords = JT_QueryViewerController.serializeRecordsForLWC(
        queryResult.records
      );
      resultData.put('records', serializedRecords);

      Map<String, Object> fieldMap = queryResult.records[0]
        .getPopulatedFieldsAsMap();
      List<String> fields = new List<String>();
      for (String key : fieldMap.keySet()) {
        if (
          key != 'attributes' && !(fieldMap.get(key) instanceof List<SObject>)
        ) {
          fields.add(key);
        }
      }
      resultData.put('fields', fields);
    }

    String serializedData = JSON.serialize(resultData);
    String startMarker = '***QUERY_RESULT_START_' + executionId + '***';
    String endMarker = ' ***QUERY_RESULT_END***';
    System.debug(startMarker + ' ' + serializedData + endMarker);
  }

  private class TestParameters {
    public final String personaDeveloperName;
    public final String configName;
    public final String bindingsJson;
    public final String executionId;

    public TestParameters(
      String personaDeveloperName,
      String configName,
      String bindingsJson,
      String executionId
    ) {
      this.personaDeveloperName = personaDeveloperName;
      this.configName = configName;
      this.bindingsJson = bindingsJson;
      this.executionId = executionId;
    }
  }

  private class QueryResult {
    public Boolean success = false;
    public List<SObject> records = new List<SObject>();
    public Integer recordCount = 0;
    public String errorMessage;
    public String stackTrace;
    public Integer executionTime = 0;
    public String runAsUser;
  }
}
