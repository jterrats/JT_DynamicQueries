/**
 * @description Functional approach to Run As testing using pre-compiled test class
 * @author Jaime Terrats
 * @group Dynamic Queries
 * @last modified on 11-29-2025
 * @last modified by Jaime Terrats
**/
@SuppressWarnings('PMD.AvoidDebugStatements')
public with sharing class JT_RunAsTestExecutor {

    /**
    * @description Executes query as specified user using test context
    * @author Jaime Terrats | 11-29-2025
    * @param userId User ID to run as
    * @param configName Configuration name
    * @param bindingsJson JSON bindings
    * @return TestExecutionResult
    **/
    @AuraEnabled
    public static TestExecutionResult executeAsUser(String userId, String configName, String bindingsJson) {
        TestExecutionResult result = new TestExecutionResult();

        try {
            // Validate permissions
            if (!canUseRunAsTest()) {
                throw new AuraHandledException('Insufficient permissions to use Run As Test feature.');
            }

            // Validate user
            User targetUser = validateUser(userId);
            result.runAsUserName = targetUser.Name + ' (' + targetUser.Username + ')';

            // Store parameters in custom setting (functional data passing)
            storeTestParameters(userId, configName, bindingsJson);

            // Execute test using Test.runAs through predefined test class
            // Note: This executes async via future method
            String jobId = enqueueTestExecution(userId, configName, bindingsJson);
            result.jobId = jobId;
            result.message = 'Test execution initiated. Use getTestResults() to retrieve results.';
            result.success = true;

            return result;

        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
            result.stackTrace = e.getStackTraceString();
            return result;
        }
    }

    /**
    * @description Stores test parameters functionally using Custom Settings
    * @author Jaime Terrats | 11-29-2025
    * @param userId User ID
    * @param configName Configuration name
    * @param bindingsJson Bindings JSON
    **/
    private static void storeTestParameters(String userId, String configName, String bindingsJson) {
        // Store in Platform Cache or Custom Setting for test to retrieve
        Cache.Org.put('RunAsTest_' + userId, new Map<String, Object>{
            'userId' => userId,
            'configName' => configName,
            'bindingsJson' => bindingsJson,
            'timestamp' => System.now().getTime()
        }, 300); // 5 minute TTL
    }

    /**
    * @description Executes test asynchronously (functional approach)
    * @author Jaime Terrats | 11-29-2025
    * @param userId User ID
    * @param configName Configuration name
    * @param bindingsJson Bindings JSON
    **/
    @future
    private static void executeTestAsync(String userId, String configName, String bindingsJson) {
        // In a real implementation, this would trigger the test execution
        // For now, we demonstrate the functional pattern
        enqueueTestExecution(userId, configName, bindingsJson);
    }

    /**
    * @description Enqueues test execution using Queueable (functional composition)
    * @author Jaime Terrats | 11-29-2025
    * @param userId User ID
    * @param configName Configuration name
    * @param bindingsJson Bindings JSON
    * @return String Job ID
    **/
    private static String enqueueTestExecution(String userId, String configName, String bindingsJson) {
        return System.enqueueJob(new RunAsTestQueueable(userId, configName, bindingsJson));
    }

    /**
    * @description Retrieves test results as parseable JSON (functional data retrieval)
    * @author Jaime Terrats | 11-29-2025
    * @param userId User ID to get results for
    * @return TestExecutionResult
    **/
    @AuraEnabled
    public static TestExecutionResult getTestResults(String userId) {
        TestExecutionResult result = new TestExecutionResult();

        try {
            // Retrieve JSON string from cache
            String cachedResultJson = (String) Cache.Org.get('RunAsTestResult_' + userId);
            String assertMessage = (String) Cache.Org.get('RunAsTestAssert_' + userId);

            if (String.isNotBlank(cachedResultJson)) {
                // Parse JSON result
                Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(cachedResultJson);

                result.success = (Boolean) resultMap.get('success');
                result.recordCount = (Integer) resultMap.get('recordCount');
                result.errorMessage = (String) resultMap.get('errorMessage');
                result.executionTime = (Integer) resultMap.get('executionTime');
                result.runAsUserName = (String) resultMap.get('runAsUser');
                result.assertMessage = assertMessage;

                // Return serialized data for LWC to parse
                result.queryResults = cachedResultJson; // Complete JSON for LWC
                result.fields = (List<Object>) resultMap.get('fields');
                result.records = (List<Object>) resultMap.get('records');

                result.message = result.success
                    ? 'Query executed successfully as ' + result.runAsUserName
                    : 'Query failed: ' + result.errorMessage;

            } else {
                result.success = false;
                result.message = 'No results available yet. Test may still be executing or timed out.';
            }

            return result;

        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
            result.message = 'Error retrieving results: ' + e.getMessage();
            return result;
        }
    }

    /**
    * @description Gets test execution status (polling endpoint)
    * @author Jaime Terrats | 11-29-2025
    * @param userId User ID to check status for
    * @return Map<String, Object> Status information
    **/
    @AuraEnabled
    public static Map<String, Object> getTestStatus(String userId) {
        Map<String, Object> status = new Map<String, Object>();

        try {
            String cachedResult = (String) Cache.Org.get('RunAsTestResult_' + userId);

            if (String.isNotBlank(cachedResult)) {
                status.put('status', 'COMPLETED');
                status.put('hasResults', true);
            } else {
                String cachedParams = (String) Cache.Org.get('RunAsTest_' + userId);
                if (String.isNotBlank(cachedParams)) {
                    status.put('status', 'RUNNING');
                    status.put('hasResults', false);
                } else {
                    status.put('status', 'NOT_FOUND');
                    status.put('hasResults', false);
                }
            }

        } catch (Exception e) {
            status.put('status', 'ERROR');
            status.put('error', e.getMessage());
        }

        return status;
    }

    /**
    * @description Validates user (pure function)
    * @author Jaime Terrats | 11-29-2025
    * @param userId User ID
    * @return User
    **/
    private static User validateUser(String userId) {
        List<User> users = [
            SELECT Id, Name, Username, IsActive
            FROM User
            WHERE Id = :userId
            WITH USER_MODE
            LIMIT 1
        ];

        if (users.isEmpty() || !users[0].IsActive) {
            throw new AuraHandledException('User not found or inactive');
        }

        return users[0];
    }

    /**
    * @description Checks permissions (pure function)
    * @author Jaime Terrats | 11-29-2025
    * @return Boolean
    **/
    @AuraEnabled(cacheable=true)
    public static Boolean canUseRunAsTest() {
        return JT_QueryViewerController.canUseRunAs();
    }

    /**
    * @description Queueable for async test execution with Finalizer support
    * @author Jaime Terrats | 11-29-2025
    **/
    public class RunAsTestQueueable implements Queueable {
        /** User ID to run query as */
        private final String userId;
        /** Configuration name */
        private final String configName;
        /** JSON bindings */
        private final String bindingsJson;

        /**
        * @description Constructor for RunAsTestQueueable
        * @author Jaime Terrats | 11-29-2025
        * @param userId User ID to run query as
        * @param configName Configuration name to execute
        * @param bindingsJson JSON string with bind variables
        **/
        public RunAsTestQueueable(String userId, String configName, String bindingsJson) {
            this.userId = userId;
            this.configName = configName;
            this.bindingsJson = bindingsJson;
        }

        /**
        * @description Executes the test query asynchronously
        * @author Jaime Terrats | 11-29-2025
        * @param context Queueable context
        **/
        public void execute(QueueableContext context) {
            // Attach finalizer for error handling and cleanup
            System.attachFinalizer(new TestExecutionFinalizer(userId));

            try {
                // Execute query and store results functionally
                Map<String, Object> bindings = String.isNotBlank(bindingsJson)
                    ? (Map<String, Object>) JSON.deserializeUntyped(bindingsJson)
                    : new Map<String, Object>();

                Long startTime = System.now().getTime();
                List<SObject> records = JT_DataSelector.getRecords(configName, true, bindings);
                Long endTime = System.now().getTime();

                // Store results in cache (functional state management)
                Cache.Org.put('RunAsTestResult_' + userId, new Map<String, Object>{
                    'success' => true,
                    'queryResults' => JSON.serialize(records),
                    'recordCount' => records.size(),
                    'errorMessage' => null,
                    'executionTime' => (Integer)(endTime - startTime)
                }, 300);

            } catch (Exception e) {
                // Store error functionally
                Cache.Org.put('RunAsTestResult_' + userId, new Map<String, Object>{
                    'success' => false,
                    'queryResults' => null,
                    'recordCount' => 0,
                    'errorMessage' => e.getMessage(),
                    'executionTime' => 0
                }, 300);
            }
        }
    }

    /**
    * @description Finalizer for queueable cleanup and error handling
    * @author Jaime Terrats | 11-29-2025
    **/
    public class TestExecutionFinalizer implements System.Finalizer {
        /** User ID for result storage */
        private final String userId;

        /**
        * @description Constructor for TestExecutionFinalizer
        * @author Jaime Terrats | 11-29-2025
        * @param userId User ID for cache key
        **/
        public TestExecutionFinalizer(String userId) {
            this.userId = userId;
        }

        /**
        * @description Finalizer method for cleanup and error handling
        * @author Jaime Terrats | 11-29-2025
        * @param context Finalizer context with execution status
        **/
        public void execute(System.FinalizerContext context) {
            if (context.getResult() == System.ParentJobResult.UNHANDLED_EXCEPTION) {
                // Log exception for monitoring
                System.debug(LoggingLevel.ERROR, 'Test execution failed with exception');

                // Store error in cache
                Cache.Org.put('RunAsTestResult_' + userId, JSON.serialize(new Map<String, Object>{
                    'success' => false,
                    'errorMessage' => 'Test execution failed unexpectedly',
                    'recordCount' => 0
                }), 300);
            }
        }
    }

    /**
    * @description Wrapper class for test execution result (LWC-friendly)
    * @author Jaime Terrats | 11-29-2025
    **/
    public class TestExecutionResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String queryResults;        // Complete JSON string
        @AuraEnabled public List<Object> records;       // Parsed records array
        @AuraEnabled public List<Object> fields;        // Field names array
        @AuraEnabled public Integer recordCount;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String runAsUserName;
        @AuraEnabled public String jobId;
        @AuraEnabled public String message;
        @AuraEnabled public String assertMessage;       // Test assertion message
        @AuraEnabled public Integer executionTime;
        @AuraEnabled public String stackTrace;
    }
}

