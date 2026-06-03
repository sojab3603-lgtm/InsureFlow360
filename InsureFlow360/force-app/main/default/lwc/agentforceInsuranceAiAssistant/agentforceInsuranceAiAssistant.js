import { LightningElement } from 'lwc';
import getWelcomeMessage from '@salesforce/apex/AgentforceInsuranceAiAssistantController.getWelcomeMessage';
import getClaimSummary from '@salesforce/apex/AgentforceInsuranceAiAssistantController.getClaimSummary';
import processUserQuery from '@salesforce/apex/AgentforceInsuranceAiAssistantController.processUserQuery';

export default class AgentforceInsuranceAiAssistant extends LightningElement {
    chatHistory = [];
    userQuery = '';
    isLoading = false;
    error = null;
    summary = null;
    quickSuggestions = [];
    assistantHelpText = 'Type a claim, fraud, payment, or policy question above or tap a suggestion for instant guidance.';

    connectedCallback() {
        this.loadWelcomeMessage();
        this.loadSummary();
    }

    createChatMessage(from, text, topic, confidence, detailsText) {
        return {
            key: `${from}-${Date.now()}-${Math.floor(Math.random() * 10000)}`,
            from,
            text,
            topic,
            confidence,
            detailsText,
            cssClass: from === 'assistant' ? 'message assistant-message' : 'message user-message',
            displayName: from === 'assistant' ? 'Agentforce AI' : 'You'
        };
    }

    loadWelcomeMessage() {
        getWelcomeMessage()
            .then(response => {
                this.chatHistory = [
                    this.createChatMessage('assistant', response.reply, response.topic, response.confidence, response.detailsText)
                ];
                this.quickSuggestions = response.suggestions || [];
                this.error = null;
            })
            .catch(error => {
                this.error = error.body ? error.body.message : String(error);
            });
    }

    loadSummary() {
        getClaimSummary()
            .then(response => {
                this.summary = response;
            })
            .catch(error => {
                this.error = error.body ? error.body.message : String(error);
            });
    }

    handleInputChange(event) {
        this.userQuery = event.target.value;
    }

    handleSuggestionClick(event) {
        const suggestion = event.target.dataset.suggestion;
        if (suggestion) {
            this.userQuery = suggestion;
            this.handleSend();
        }
    }

    handleSend() {
        const question = this.userQuery && this.userQuery.trim();
        if (!question) {
            return;
        }

        this.chatHistory = [
            ...this.chatHistory,
            this.createChatMessage('user', question)
        ];
        this.userQuery = '';
        this.isLoading = true;
        this.error = null;

        processUserQuery({ userQuery: question })
            .then(response => {
                this.chatHistory = [
                    ...this.chatHistory,
                    this.createChatMessage('assistant', response.reply, response.topic, response.confidence, response.detailsText)
                ];
                this.quickSuggestions = response.suggestions || [];
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error.body ? error.body.message : String(error);
                this.isLoading = false;
            });
    }

    get hasHistory() {
        return this.chatHistory.length > 0;
    }

    get sendButtonLabel() {
        return this.isLoading ? 'Processing...' : 'Send';
    }

    get sendDisabled() {
        return this.isLoading || !this.userQuery || !this.userQuery.trim();
    }
}
