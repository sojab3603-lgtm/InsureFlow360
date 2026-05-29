@isTest
private class FraudDetectionQueueableTest {
    @isTest static void testExecuteHighRiskClaimUpdatesScoreAndStatus() {
        Claim__c claim = new Claim__c(
            Claim_Amount__c = 1200000
        );
        insert claim;

        Test.startTest();
            System.enqueueJob(
                new FraudDetectionQueueable(new List<Id>{ claim.Id })
            );
        Test.stopTest();

        claim = [
            SELECT Fraud_Score__c,
                   Fraud_Status__c,
                   Investigation_Required__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(90, claim.Fraud_Score__c);
        System.assertEquals('High Risk', claim.Fraud_Status__c);
        System.assertEquals(true, claim.Investigation_Required__c);

        Integration_Log__c log = [
            SELECT Status__c,
                   Log_Level__c,
                   Source_System__c
            FROM Integration_Log__c
            WHERE Source_System__c = 'Fraud Engine'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals('Success', log.Status__c);
        System.assertEquals('INFO', log.Log_Level__c);
    }

    @isTest static void testExecuteMediumRiskClaimSetsMediumStatus() {
        Claim__c claim = new Claim__c(
            Claim_Amount__c = 600000
        );
        insert claim;

        Test.startTest();
            System.enqueueJob(
                new FraudDetectionQueueable(new List<Id>{ claim.Id })
            );
        Test.stopTest();

        claim = [
            SELECT Fraud_Score__c,
                   Fraud_Status__c,
                   Investigation_Required__c
            FROM Claim__c
            WHERE Id = :claim.Id
        ];

        System.assertEquals(60, claim.Fraud_Score__c);
        System.assertEquals('Medium Risk', claim.Fraud_Status__c);
        System.assertEquals(false, claim.Investigation_Required__c);
    }
}
