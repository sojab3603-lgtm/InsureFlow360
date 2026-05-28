@isTest
private class ClaimSelectorTest {

    @isTest static void testGetHighValueClaims() {
        Claim__c lowClaim = new Claim__c(
            Claim_Amount__c = 5000,
            Claim_Status__c = 'Submitted'
        );

        Claim__c highClaim = new Claim__c(
            Claim_Amount__c = 20000,
            Claim_Status__c = 'Submitted'
        );

        insert new List<Claim__c>{ lowClaim, highClaim };

        List<Claim__c> highValueClaims =
            ClaimSelector.getHighValueClaims(10000);

        System.assertEquals(1, highValueClaims.size());
        System.assertEquals(highClaim.Id, highValueClaims[0].Id);
    }
}
