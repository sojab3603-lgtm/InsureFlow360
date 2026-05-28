@isTest
private class ClaimTriggerHandlerTest {

    @isTest static void testBeforeInsertAfterInsertTriggerPath() {
        Claim__c newClaim = new Claim__c(
            Claim_Amount__c = 150,
            Claim_Status__c = 'Submitted'
        );

        Test.startTest();
            insert newClaim;
        Test.stopTest();

        Integer logCount = [SELECT count() FROM Integration_Log__c WHERE Status__c = 'Success'];
        System.assertEquals(1, logCount);
    }

    @isTest static void testBeforeUpdateTriggerPreventsRejectedToApproved() {
        Claim__c existingClaim = new Claim__c(
            Claim_Amount__c = 100,
            Claim_Status__c = 'Rejected'
        );

        insert existingClaim;

        existingClaim.Claim_Status__c = 'Approved';

        Boolean exceptionThrown = false;

        Test.startTest();
            try {
                update existingClaim;
            } catch (DmlException e) {
                exceptionThrown = true;
                System.assert(e.getMessage().contains('Rejected claims cannot be directly approved.'));
            }
        Test.stopTest();

        System.assert(exceptionThrown);
    }
}
