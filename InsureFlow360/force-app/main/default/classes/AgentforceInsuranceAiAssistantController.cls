public with sharing class AgentforceInsuranceAiAssistantController {

    public class AssistantResponse {
        @AuraEnabled public String reply { get; set; }
        @AuraEnabled public String confidence { get; set; }
        @AuraEnabled public String topic { get; set; }
        @AuraEnabled public List<String> suggestions { get; set; }
        @AuraEnabled public String detailsText { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static AssistantResponse getWelcomeMessage() {
        return createResponse(
            'Hello! I am your Agentforce Insurance AI Assistant. I can help you understand claim status, fraud risk, payment monitoring, and policy guidance.',
            'Welcome',
           0.97 ,
            new List<String>{
                'Show me the current claim summary',
                'What are the latest fraud alerts?',
                'How do I improve policy coverage?'
            },
            'Use the quick buttons to ask for summaries and insights, or type a specific question about claims, fraud, payments, or policy coverage.'
        );
    }

    @AuraEnabled(cacheable=true)
    public static ClaimSelector.ClaimSummary getClaimSummary() {
        return ClaimSelector.getClaimSummary();
    }

    @AuraEnabled(cacheable=true)
    public static ClaimSelector.ClaimsAnalytics getClaimsAnalytics() {
        return ClaimSelector.getClaimsAnalytics();
    }

    @AuraEnabled
    public static AssistantResponse processUserQuery(String userQuery) {
        String safeQuery = String.isBlank(userQuery) ? '' : userQuery.trim();
        safeQuery = SecurityService.sanitizeInput(safeQuery);

        if (String.isBlank(safeQuery)) {
            return createResponse(
                'Please type your question so I can help with claims, payments, fraud alerts, or policy guidance.',
                'General',
                '0.45',
                new List<String>{
                    'Show me the current claim summary',
                    'What are the latest fraud alerts?'
                },
                null
            );
        }

        String normalized = safeQuery.toLowerCase();

        if (containsAny(normalized, new List<String>{'summary', 'dashboard', 'overview', 'report'})) {
            ClaimSelector.ClaimSummary summary = ClaimSelector.getClaimSummary();
            return createResponse(
                'Here is the latest claim summary from your data.',
                'Claims Summary',
                '0.94',
                new List<String>{
                    'Show me fraud analytics',
                    'Show me high value claims'
                },
                'Total claims: ' + String.valueOf(summary.totalClaims)
                + '\nApproved claims: ' + String.valueOf(summary.approvedClaims)
                + '\nPending claims: ' + String.valueOf(summary.pendingClaims)
                + '\nHigh risk claims: ' + String.valueOf(summary.highRiskClaims)
            );
        }

        if (containsAny(normalized, new List<String>{'analytics', 'trend', 'average', 'mean', 'fraud rate', 'fraud percentage', 'risk percentage'})) {
            ClaimSelector.ClaimsAnalytics analytics = ClaimSelector.getClaimsAnalytics();
            return createResponse(
                'I found the current claims analytics and risk metrics for your portfolio.',
                'Claims Analytics',
                '0.92',
                new List<String>{
                    'Show me the current claim summary',
                    'How do I reduce fraud risk?'
                },
                'Average claim amount: ' + String.valueOf(analytics.averageClaimAmount)
                + '\nTotal claim value: ' + String.valueOf(analytics.totalClaimsValue)
                + '\nFraud rate: ' + String.valueOf(analytics.fraudRatePercentage) + '%'
            );
        }

        if (containsAny(normalized, new List<String>{'high value', 'large claim', 'top claim', 'expensive claim'})) {
            List<Claim__c> claims = ClaimSelector.getHighValueClaims(100000);
            return createResponse(
                'I found the highest value claims in the system. Review the top results below.',
                'High-Value Claims',
                '0.90',
                new List<String>{
                    'Show me the current claim summary',
                    'How do I investigate a fraud alert?'
                },
                buildHighValueClaimText(claims)
            );
        }

        if (containsAny(normalized, new List<String>{'claim status', 'track claim', 'claim update', 'status of my claim'})) {
            return createResponse(
                'To check a specific claim, open the claim record page and review the Claim Status field. If you want an overall picture, ask for a claim summary.',
                'Claim Status',
                '0.92',
                new List<String>{
                    'Show me the current claim summary',
                    'How do I resolve a pending claim?'
                },
                null
            );
        }

        if (containsAny(normalized, new List<String>{'fraud', 'alert', 'investigate'})) {
            return createResponse(
                'Fraud alerts should be prioritized by fraud score. High risk claims need immediate review, while medium risk claims should be validated before approval.',
                'Fraud Alerts',
                '0.91',
                new List<String>{
                    'Show me fraud analytics',
                    'Show me high value claims'
                },
                null
            );
        }

        if (containsAny(normalized, new List<String>{'payment', 'transaction', 'refund', 'reconcile'})) {
            return createResponse(
                'Payment monitoring highlights failed and pending transfers. Use the Payment Monitoring Console to reconcile transactions and resolve exceptions quickly.',
                'Payment Monitoring',
                '0.90',
                new List<String>{
                    'Show me the current claim summary',
                    'How do I investigate fraud alerts?'
                },
                null
            );
        }

        if (containsAny(normalized, new List<String>{'policy', 'coverage', 'renewal', 'terms'})) {
            return createResponse(
                'Policy guidance depends on your coverage rules. Review your policy record for limit details, or ask your account manager about specific coverage conditions.',
                'Policy Guidance',
                '0.85',
                new List<String>{
                    'How do I improve policy coverage?',
                    'Show me the current claim summary'
                },
                null
            );
        }

        return createResponse(
            'I can help with claims, fraud alerts, payments, analytics, and policy guidance. Try asking for a claim summary, fraud risk insight, or payment status review.',
            'Fallback',
            '0.70',
            new List<String>{
                'Show me the current claim summary',
                'What are the latest fraud alerts?',
                'How do I improve policy coverage?'
            },
            null
        );
    }

    private static AssistantResponse createResponse(String reply, String topic, String confidence, List<String> suggestions, String detailsText) {
        AssistantResponse response = new AssistantResponse();
        response.reply = SecurityService.encodeOutput(reply);
        response.topic = topic;
        response.confidence = confidence;
        response.suggestions = suggestions == null ? new List<String>() : new List<String>();

        if (suggestions != null) {
            for (String suggestion : suggestions) {
                response.suggestions.add(SecurityService.encodeOutput(suggestion));
            }
        }

        response.detailsText = SecurityService.encodeOutput(detailsText);
        return response;
    }

    private static String buildHighValueClaimText(List<Claim__c> claims) {
        if (claims == null || claims.isEmpty()) {
            return 'No high-value claims found at this time.';
        }

        String summaryText = '';
        Integer index = 1;
        for (Claim__c claim : claims) {
            summaryText += index + '. ' + (claim.Name != null ? claim.Name : 'Unknown') + ' - ';
            summaryText += 'Amount: ' + (claim.Claim_Amount__c != null ? String.valueOf(claim.Claim_Amount__c) : 'N/A');
            summaryText += ', Status: ' + (claim.Claim_Status__c != null ? claim.Claim_Status__c : 'Unknown');
            summaryText += ', Risk: ' + (claim.Fraud_Status__c != null ? claim.Fraud_Status__c : 'Unknown');
            summaryText += '\n';
            if (index >= 3) {
                break;
            }
            index++;
        }

        return summaryText;
    }

    private static Boolean containsAny(String text, List<String> searchTerms) {
        if (text == null || searchTerms == null) {
            return false;
        }
        for (String term : searchTerms) {
            if (term != null && text.contains(term)) {
                return true;
            }
        }
        return false;
    }
}
