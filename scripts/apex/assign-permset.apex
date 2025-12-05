// Script to auto-assign JT_Dynamic_Queries permission set to current user
// Run this before E2E tests to ensure user has access

String permSetName = 'JT_Dynamic_Queries';
Id currentUserId = UserInfo.getUserId();

// Check if user already has the permission set
List<PermissionSetAssignment> existingAssignments = [
    SELECT Id
    FROM PermissionSetAssignment
    WHERE PermissionSet.Name = :permSetName
    AND AssigneeId = :currentUserId
    LIMIT 1
];

if (existingAssignments.isEmpty()) {
    // User doesn't have it, assign it
    PermissionSet ps = [
        SELECT Id, Name
        FROM PermissionSet
        WHERE Name = :permSetName
        LIMIT 1
    ];

    PermissionSetAssignment psa = new PermissionSetAssignment(
        PermissionSetId = ps.Id,
        AssigneeId = currentUserId
    );

    insert psa;
    System.debug('✅ Permission Set "' + permSetName + '" assigned to user: ' + UserInfo.getUserEmail());
} else {
    System.debug('✅ Permission Set "' + permSetName + '" already assigned to user: ' + UserInfo.getUserEmail());
}




