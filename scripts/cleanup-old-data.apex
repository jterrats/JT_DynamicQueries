// Script to cleanup old execution records and audit logs
// Run this in Anonymous Apex or Developer Console

// Step 1: Check statistics (preview what will be deleted)
Map<String, Object> stats = JT_DataCleanupUtil.getCleanupStatistics();
System.debug('📊 Cleanup Statistics:');
System.debug('  Old Execution Records (>30 days): ' + stats.get('oldExecutionRecords'));
System.debug('  Stuck Execution Records (>7 days): ' + stats.get('stuckExecutionRecords'));
System.debug('  Old Audit Logs (>90 days): ' + stats.get('oldAuditLogs'));
System.debug('  Total Deletable Records: ' + stats.get('totalDeletableRecords'));

// Step 2: Perform cleanup (uncomment to execute)
// Map<String, Object> results = JT_DataCleanupUtil.performFullCleanup(30, 90);
// System.debug('✅ Cleanup Results:');
// System.debug('  Execution Records Deleted: ' + results.get('executionRecordsDeleted'));
// System.debug('  Audit Logs Deleted: ' + results.get('auditLogsDeleted'));
// System.debug('  Total Deleted: ' + results.get('totalDeleted'));

// Alternative: Cleanup specific object types
// Integer execDeleted = JT_DataCleanupUtil.cleanupExecutionRecords(30);
// Integer auditDeleted = JT_DataCleanupUtil.cleanupAuditLogs(90);
// System.debug('Execution records deleted: ' + execDeleted);
// System.debug('Audit logs deleted: ' + auditDeleted);

