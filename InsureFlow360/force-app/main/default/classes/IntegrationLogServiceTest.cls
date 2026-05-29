@isTest
private class IntegrationLogServiceTest {
    @isTest static void testCreateInfoLogInsertsInfoRecord() {
        Account acct = new Account(Name = 'Integration Log Test');
        insert acct;

        Test.startTest();
            IntegrationLogService.createInfoLog(
                'Integration Service',
                'Info event created',
                String.valueOf(acct.Id)
            );
        Test.stopTest();

        Integration_Log__c log = [
            SELECT Source_System__c,
                   Message__c,
                   Status__c,
                   Log_Level__c,
                   Related_Record_Id__c
            FROM Integration_Log__c
            WHERE Related_Record_Id__c = :String.valueOf(acct.Id)
            LIMIT 1
        ];

        System.assertEquals('Integration Service', log.Source_System__c);
        System.assertEquals('Info event created', log.Message__c);
        System.assertEquals('Success', log.Status__c);
        System.assertEquals('INFO', log.Log_Level__c);
    }

    @isTest static void testCreateErrorLogInsertsErrorRecord() {
        Account acct = new Account(Name = 'Integration Log Error Test');
        insert acct;

        Test.startTest();
            IntegrationLogService.createErrorLog(
                'Integration Service',
                'Error event created',
                String.valueOf(acct.Id)
            );
        Test.stopTest();

        Integration_Log__c log = [
            SELECT Source_System__c,
                   Message__c,
                   Status__c,
                   Log_Level__c,
                   Related_Record_Id__c
            FROM Integration_Log__c
            WHERE Related_Record_Id__c = :String.valueOf(acct.Id)
            LIMIT 1
        ];

        System.assertEquals('Integration Service', log.Source_System__c);
        System.assertEquals('Error event created', log.Message__c);
        System.assertEquals('Failed', log.Status__c);
        System.assertEquals('ERROR', log.Log_Level__c);
    }
}

