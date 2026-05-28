public with sharing class ClaimService {

    /*
     * Validate Claim Amount
     */
    public static void validateClaimAmount(
        List<Claim__c> claims
    ) {

        for (Claim__c claim : claims) {

            if (
                claim.Claim_Amount__c != null &&
                claim.Claim_Amount__c <= 0
            ) {

                claim.addError(
                    'Claim amount must be greater than zero.'
                );
            }
        }
    }

    /*
     * Validate Status Transition
     */
    public static void validateStatusTransition(
        List<Claim__c> newClaims,
        Map<Id, Claim__c> oldMap
    ) {

        for (Claim__c claim : newClaims) {

            Claim__c oldClaim =
                oldMap.get(claim.Id);

            if (
                oldClaim != null &&
                oldClaim.Claim_Status__c == 'Rejected' &&
                claim.Claim_Status__c == 'Approved'
            ) {

                claim.addError(
                    'Rejected claims cannot be directly approved.'
                );
            }
        }
    }

    /*
     * Create Audit Logs
     */
    public static void createAuditLogs(
        List<Claim__c> claims
    ) {

        List<Integration_Log__c> logs =
            new List<Integration_Log__c>();

        for (Claim__c claim : claims) {

            logs.add(
                new Integration_Log__c(
                    Status__c = 'Success'
                )
            );
        }

        if (!logs.isEmpty()) {
            insert logs;
        }
    }

    /*
     * Publish Event
     */
    public static void publishClaimEvent(
        List<Claim__c> claims
    ) {

        for (Claim__c claim : claims) {

            System.debug(
                'Publishing event for Claim Id: '
                + claim.Id
            );
        }
    }
}