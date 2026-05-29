public with sharing class IntegrationLogService {

    public static void createInfoLog(
        String source,
        String message,
        String relatedRecordId
    ) {

        insert new Integration_Log__c(
            Source_System__c = source,
            Message__c = message,
            Status__c = 'Success',
            Log_Level__c = 'INFO',
            Related_Record_Id__c = relatedRecordId
        );
    }

    public static void createErrorLog(
        String source,
        String message,
        String relatedRecordId
    ) {

        insert new Integration_Log__c(
            Source_System__c = source,
            Message__c = message,
            Status__c = 'Failed',
            Log_Level__c = 'ERROR',
            Related_Record_Id__c = relatedRecordId
        );
    }
}