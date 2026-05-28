public with sharing class ClaimTriggerHandler {

    public void beforeInsert(
        List<Claim__c> newClaims
    ) {

        ClaimService.validateClaimAmount(
            newClaims
        );
    }

    public void beforeUpdate(
        List<Claim__c> newClaims,
        Map<Id, Claim__c> oldMap
    ) {

        ClaimService.validateStatusTransition(
            newClaims,
            oldMap
        );
    }

    public void afterInsert(
        List<Claim__c> newClaims
    ) {

        ClaimService.createAuditLogs(
            newClaims
        );
    }

    public void afterUpdate(
        List<Claim__c> newClaims,
        Map<Id, Claim__c> oldMap
    ) {

        ClaimService.publishClaimEvent(
            newClaims
        );
    }
}