public with sharing class FraudDetectionQueueable implements Queueable {

    private List<Id> claimIds;

    public FraudDetectionQueueable(List<Id> claimIds) {
        this.claimIds = claimIds;
    }

    public void execute(QueueableContext context) {

        List<Claim__c> claims = [
            SELECT Id,
                   Name,
                   Claim_Amount__c,
                   Fraud_Score__c,
                   Fraud_Status__c,
                   Investigation_Required__c
            FROM Claim__c
            WHERE Id IN :claimIds
        ];

        List<Claim__c> claimsToUpdate = new List<Claim__c>();
        List<Claim_Alert__e> events = new List<Claim_Alert__e>();

        for (Claim__c claim : claims) {

            Integer fraudScore = calculateFraudScore(claim);

            claim.Fraud_Score__c = fraudScore;

            if (fraudScore >= 80) {

                claim.Fraud_Status__c = 'High Risk';
                claim.Investigation_Required__c = true;

                events.add(
                    new Claim_Alert__e(
                        Claim_Id__c = claim.Id,
                        Fraud_Score__c = fraudScore,
                        Alert_Type__c = 'HIGH_RISK',
                        Message__c = 'High risk claim detected'
                    )
                );

            } else if (fraudScore >= 50) {

                claim.Fraud_Status__c = 'Medium Risk';

            } else {

                claim.Fraud_Status__c = 'Low Risk';
            }

            claimsToUpdate.add(claim);
        }

        if (!claimsToUpdate.isEmpty()) {
            update claimsToUpdate;
        }

        if (!events.isEmpty()) {
            EventBus.publish(events);
        }

        IntegrationLogService.createInfoLog(
            'Fraud Engine',
            'Fraud analysis completed',
            null
        );
    }

    private Integer calculateFraudScore(Claim__c claim) {

        Integer score = 0;

        if (claim.Claim_Amount__c > 500000) {
            score += 60;
        }

        if (claim.Claim_Amount__c > 1000000) {
            score += 30;
        }

        return score;
    }
}