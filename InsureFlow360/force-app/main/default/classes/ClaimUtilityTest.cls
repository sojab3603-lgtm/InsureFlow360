@isTest
public class ClaimUtilityTest {

    @isTest static void testIsHighRiskClaimReturnsTrue() {
        Claim__c claim = new Claim__c(
            Claim_Amount__c = 2000000
        );

        System.assertEquals(true, ClaimUtility.isHighRiskClaim(claim));
    }

    @isTest static void testIsHighRiskClaimReturnsFalse() {
        Claim__c claim = new Claim__c(
            Claim_Amount__c = 50000
        );

        System.assertEquals(false, ClaimUtility.isHighRiskClaim(claim));
    }
}
