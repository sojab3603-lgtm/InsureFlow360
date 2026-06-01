@isTest
private class AgentforceInsuranceAiAssistantTest {
    @isTest static void testGetWelcomeMessage() {
        AgentforceInsuranceAiAssistantController.AssistantResponse response = AgentforceInsuranceAiAssistantController.getWelcomeMessage();
        System.assertNotEquals(null, response);
        System.assert(response.reply.contains('Agentforce Insurance AI Assistant'));
        System.assert(response.confidence != null && response.confidence != '');
    }

    @isTest static void testProcessUserQueryClaimStatus() {
        AgentforceInsuranceAiAssistantController.AssistantResponse response = AgentforceInsuranceAiAssistantController.processUserQuery('What is the claim status for my policy?');
        System.assert(response.reply.contains('claim status'));
        System.assertEquals('Claim Status', response.topic);
    }

    @isTest static void testProcessUserQueryFraudAlert() {
        AgentforceInsuranceAiAssistantController.AssistantResponse response = AgentforceInsuranceAiAssistantController.processUserQuery('How do I investigate a fraud alert?');
        System.assert(response.reply.contains('Fraud alerts'));
        System.assertEquals('Fraud Alerts', response.topic);
    }

    @isTest static void testProcessUserQueryPayment() {
        AgentforceInsuranceAiAssistantController.AssistantResponse response = AgentforceInsuranceAiAssistantController.processUserQuery('Tell me about payment monitoring.');
        System.assert(response.reply.contains('Payment monitoring'));
        System.assertEquals('Payment Monitoring', response.topic);
    }

    @isTest static void testProcessUserQueryBlank() {
        AgentforceInsuranceAiAssistantController.AssistantResponse response = AgentforceInsuranceAiAssistantController.processUserQuery('');
        System.assert(response.reply.contains('Please type your question'));
        System.assertEquals('General', response.topic);
    }
}
