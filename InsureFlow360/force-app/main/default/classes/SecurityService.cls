public with sharing class SecurityService {

    public static final Integer MAX_QUERY_LIMIT = 10000;
    public static final Integer BATCH_SIZE = 200;

    public class SecurityContext {
        public Boolean canAccessClaims { get; set; }
        public Boolean canModifyClaims { get; set; }
        public Boolean canDeleteClaims { get; set; }
        public List<String> accessibleFields { get; set; }
    }

    @AuraEnabled
    public static SecurityContext getUserSecurityContext() {
        SecurityContext context = new SecurityContext();

        // Check object permissions
        Schema.DescribeSObjectResult claimDesc = Claim__c.sObjectType.getDescribe();
        context.canAccessClaims = claimDesc.isAccessible();
        context.canModifyClaims = claimDesc.isUpdateable();
        context.canDeleteClaims = claimDesc.isDeletable();

        // Get accessible fields
        context.accessibleFields = new List<String>();
        Map<String, Schema.SObjectField> fieldMap = claimDesc.fields.getMap();
        for (String fieldName : fieldMap.keySet()) {
            Schema.SObjectField field = fieldMap.get(fieldName);
            if (field.getDescribe().isAccessible()) {
                context.accessibleFields.add(fieldName);
            }
        }

        return context;
    }

    public static String sanitizeInput(String input) {
        if (input == null) {
            return null;
        }
        // Remove potentially malicious characters
        String sanitized = input.replaceAll('<script>', '')
                               .replaceAll('</script>', '')
                               .replaceAll('<iframe>', '')
                               .replaceAll('</iframe>', '')
                               .replaceAll('javascript:', '')
                               .replaceAll('onerror=', '')
                               .replaceAll('onclick=', '');
        return sanitized;
    }

    public static String encodeOutput(String output) {
        if (output == null) {
            return null;
        }
        return String.escapeSingleQuotes(output);
    }

    public static void validateFieldAccess(SObjectType objectType, List<String> fieldNames) {
        Schema.DescribeSObjectResult describeResult = objectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();

        for (String fieldName : fieldNames) {
            Schema.SObjectField field = fieldMap.get(fieldName.toLowerCase());
            if (field == null || !field.getDescribe().isAccessible()) {
                throw new SecurityException('Access denied to field: ' + fieldName);
            }
        }
    }

    public class SecurityException extends Exception {}

    // Batch processing for large operations
    public static void processBatch(List<SObject> records, String operation) {
        Integer batchCount = 0;
        List<SObject> batch = new List<SObject>();

        for (SObject record : records) {
            batch.add(record);
            if (batch.size() >= BATCH_SIZE) {
                processBatchOperation(batch, operation);
                batch = new List<SObject>();
                batchCount++;

                // Respect governor limits
                if (batchCount >= 5) {
                    break;
                }
            }
        }

        if (!batch.isEmpty()) {
            processBatchOperation(batch, operation);
        }
    }

    private static void processBatchOperation(List<SObject> batch, String operation) {
        try {
            if (operation == 'insert') {
                insert batch;
            } else if (operation == 'update') {
                update batch;
            } else if (operation == 'delete') {
                delete batch;
            }
        } catch (Exception e) {
            IntegrationLogService.createErrorLog(
                'Batch Operation',
                'Error during ' + operation + ': ' + e.getMessage(),
                null
            );
        }
    }

    // Query optimization with limits
    public static List<SObject> queryWithLimit(String queryString, Integer limitCount) {
        Integer actualLimit = Math.min(limitCount, MAX_QUERY_LIMIT);
        String limitedQuery = queryString + ' LIMIT ' + actualLimit;
        return Database.query(limitedQuery);
    }
}
