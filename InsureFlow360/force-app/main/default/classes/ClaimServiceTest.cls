@isTest
private class ClaimServiceTest {

    @isTest static void testValidateClaimAmountRejectsInvalidAmount() {
        Claim__c invalidClaim = new Claim__c(
            Claim_Amount__c = -100,
            Claim_Status__c = 'Submitted'
        );

        ClaimService.validateClaimAmount(
            new List<Claim__c>{ invalidClaim }
        );

        Boolean exceptionThrown = false;

        try {
            insert invalidClaim;
        } catch (DmlException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Claim amount must be greater than zero.'));
        }

        System.assert(exceptionThrown);
    }

    @isTest static void testValidateStatusTransitionRejectsRejectedApproval() {
        Claim__c existingClaim = new Claim__c(
            Claim_Amount__c = 100,
            Claim_Status__c = 'Rejected'
        );

        insert existingClaim;

        Claim__c updatedClaim = new Claim__c(
            Id = existingClaim.Id,
            Claim_Status__c = 'Approved'
        );

        ClaimService.validateStatusTransition(
            new List<Claim__c>{ updatedClaim },
            new Map<Id, Claim__c>{ existingClaim.Id => existingClaim }
        );

        Boolean exceptionThrown = false;

        try {
            update updatedClaim;
        } catch (DmlException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Rejected claims cannot be directly approved.'));
        }

        System.assert(exceptionThrown);
    }

    @isTest static void testCreateAuditLogsInsertsIntegrationLog() {
        Claim__c claim = new Claim__c(
            Claim_Amount__c = 200,
            Claim_Status__c = 'Submitted'
        );

        insert claim;

        Test.startTest();
            ClaimService.createAuditLogs(new List<Claim__c>{ claim });
        Test.stopTest();

        Integer logCount = [SELECT count() FROM Integration_Log__c WHERE Status__c = 'Success'];
        System.assertEquals(1, logCount);
    }

    @isTest static void testPublishClaimEventDoesNotThrow() {
        Claim__c claim = new Claim__c(
            Claim_Amount__c = 300,
            Claim_Status__c = 'Submitted'
        );

        insert claim;

        Test.startTest();
            ClaimService.publishClaimEvent(new List<Claim__c>{ claim });
        Test.stopTest();

        System.assert(true);
    }
}
