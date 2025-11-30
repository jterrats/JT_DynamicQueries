/**
 * @description Generic pre-compiled test class for Run As testing - Functional approach
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @last modified on 11-29-2025
 * @last modified by Jaime Terrats
**/
@isTest
@SuppressWarnings('PMD.AvoidDebugStatements,PMD.ApexDoc')
public class JT_GenericRunAsTest {

    // Functional composition of test execution
    @isTest
    static void executeRunAsTest() {
        // Get parameters functionally from cache/custom setting
        TestParameters params = getTestParameters();

        if (params == null) {
            System.assert(true, 'No test parameters found - skipping');
            return;
        }

        // Execute with functional composition (simplified for Apex limitations)
        User targetUser = validateUser(params);
        QueryResult queryResult = executeInUserContext(targetUser, params);
        TestResult result = storeResults(params.userId, queryResult);

        System.assertEquals(true, result != null, 'Test execution should complete');
    }

    /**
    * @description Gets test parameters functionally
    * @author Jaime Terrats | 11-29-2025
    * @return TestParameters
    **/
    private static TestParameters getTestParameters() {
        try {
            Object cached = Cache.Org.get('RunAsTest_Params');
            if (cached != null) {
                Map<String, Object> paramsMap = (Map<String, Object>) cached;
                return new TestParameters(
                    (String) paramsMap.get('userId'),
                    (String) paramsMap.get('configName'),
                    (String) paramsMap.get('bindingsJson')
                );
            }
        } catch (Exception e) {
            // Log error (use LoggingLevel.ERROR for production monitoring)
            System.debug(LoggingLevel.ERROR, 'Error getting test parameters: ' + e.getMessage());
        }
        return null;
    }

    /**
    * @description Validates user (pure function)
    * @author Jaime Terrats | 11-29-2025
    * @param params Test parameters
    * @return User
    **/
    private static User validateUser(TestParameters params) {
        return [SELECT Id, Name, Username FROM User WHERE Id = :params.userId LIMIT 1];
    }

    /**
    * @description Executes query in user context (functional with System.runAs)
    * @author Jaime Terrats | 11-29-2025
    * @param user User to run as
    * @param params Test parameters
    * @return QueryResult
    **/
    private static QueryResult executeInUserContext(User user, TestParameters params) {
        QueryResult result = new QueryResult();

        System.runAs(user) {
            Test.startTest();
            try {
                // Functional transformation of bindings
                Map<String, Object> bindings = String.isNotBlank(params.bindingsJson)
                    ? (Map<String, Object>) JSON.deserializeUntyped(params.bindingsJson)
                    : new Map<String, Object>();

                Long startTime = System.now().getTime();

                // Execute query
                List<SObject> records = JT_DataSelector.getRecords(
                    params.configName,
                    true,
                    bindings
                );

                Long endTime = System.now().getTime();

                // Build result functionally
                result.success = true;
                result.records = records;
                result.recordCount = records.size();
                result.executionTime = (Integer)(endTime - startTime);
                result.runAsUser = user.Name;

            } catch (Exception e) {
                result.success = false;
                result.errorMessage = e.getMessage();
                result.stackTrace = e.getStackTraceString();
            }
            Test.stopTest();
        }

        return result;
    }

    /**
    * @description Stores results functionally in cache as parseable JSON
    * @author Jaime Terrats | 11-29-2025
    * @param userId User ID
    * @param queryResult Query result
    * @return TestResult
    **/
    private static TestResult storeResults(String userId, QueryResult queryResult) {
        try {
            // Build parseable result structure for LWC
            Map<String, Object> resultData = new Map<String, Object>{
                'success' => queryResult.success,
                'recordCount' => queryResult.recordCount,
                'errorMessage' => queryResult.errorMessage,
                'executionTime' => queryResult.executionTime,
                'runAsUser' => queryResult.runAsUser,
                'timestamp' => System.now().getTime()
            };

            // Serialize records with field information for LWC
            if (queryResult.success && !queryResult.records.isEmpty()) {
                resultData.put('records', serializeRecordsForLWC(queryResult.records));
                resultData.put('fields', extractFieldNames(queryResult.records[0]));
            } else {
                resultData.put('records', new List<Object>());
                resultData.put('fields', new List<String>());
            }

            // Store as JSON string for easy parsing
            Cache.Org.put('RunAsTestResult_' + userId, JSON.serialize(resultData), 300);

            // Also store assertion result
            String assertMessage = queryResult.success
                ? 'SUCCESS: Found ' + queryResult.recordCount + ' record(s) as ' + queryResult.runAsUser
                : 'FAILURE: ' + queryResult.errorMessage;

            Cache.Org.put('RunAsTestAssert_' + userId, assertMessage, 300);

            return new TestResult(true, 'Results stored successfully');
        } catch (Exception e) {
            return new TestResult(false, 'Failed to store results: ' + e.getMessage());
        }
    }

    /**
    * @description Serializes records in LWC-friendly format
    * @author Jaime Terrats | 11-29-2025
    * @param records List of SObject records
    * @return List<Map<String, Object>> Serialized records
    **/
    private static List<Map<String, Object>> serializeRecordsForLWC(List<SObject> records) {
        List<Map<String, Object>> serializedRecords = new List<Map<String, Object>>();

        for (SObject record : records) {
            Map<String, Object> recordMap = new Map<String, Object>();
            Map<String, Object> populatedFields = record.getPopulatedFieldsAsMap();

            for (String fieldName : populatedFields.keySet()) {
                Object fieldValue = populatedFields.get(fieldName);

                // Handle relationship fields
                if (fieldValue instanceof SObject) {
                    SObject relatedRecord = (SObject) fieldValue;
                    recordMap.put(fieldName, flattenSObject(relatedRecord));
                } else {
                    recordMap.put(fieldName, fieldValue);
                }
            }

            serializedRecords.add(recordMap);
        }

        return serializedRecords;
    }

    /**
    * @description Flattens SObject relationships for JSON serialization
    * @author Jaime Terrats | 11-29-2025
    * @param obj SObject to flatten
    * @return Map<String, Object> Flattened object
    **/
    private static Map<String, Object> flattenSObject(SObject obj) {
        Map<String, Object> flatMap = new Map<String, Object>();
        Map<String, Object> fields = obj.getPopulatedFieldsAsMap();

        for (String fieldName : fields.keySet()) {
            flatMap.put(fieldName, fields.get(fieldName));
        }

        return flatMap;
    }

    /**
    * @description Extracts field names from record
    * @author Jaime Terrats | 11-29-2025
    * @param record SObject record
    * @return List<String> Field names
    **/
    private static List<String> extractFieldNames(SObject record) {
        Map<String, Object> fieldMap = record.getPopulatedFieldsAsMap();
        List<String> fields = new List<String>(fieldMap.keySet());
        fields.sort();
        return fields;
    }

    /**
    * @description Test parameters (immutable data class)
    * @author Jaime Terrats | 11-29-2025
    **/
    private class TestParameters {
        public final String userId;
        public final String configName;
        public final String bindingsJson;

        public TestParameters(String userId, String configName, String bindingsJson) {
            this.userId = userId;
            this.configName = configName;
            this.bindingsJson = bindingsJson;
        }
    }

    /**
    * @description Query result wrapper containing execution results
    * @author Jaime Terrats | 11-29-2025
    **/
    private class QueryResult {
        /** Success flag */
        public Boolean success = false;
        /** Query result records */
        public List<SObject> records = new List<SObject>();
        /** Number of records returned */
        public Integer recordCount = 0;
        /** Error message if failed */
        public String errorMessage;
        /** Stack trace if exception */
        public String stackTrace;
        /** Execution time in milliseconds */
        public Integer executionTime = 0;
        /** Name of user who ran the query */
        public String runAsUser;
    }

    /**
    * @description Test result (immutable data class)
    **/
    private class TestResult {
        public final Boolean success;
        public final String message;

        public TestResult(Boolean success, String message) {
            this.success = success;
            this.message = message;
        }
    }

}

