public with sharing class KYCVerificationService {

    public static void verifyCustomerKYC(Id customerId) {

        try {

            Customer__c customer = [
                SELECT Id,
                       Full_Name__c,
                       Email__c,
                       KYC_Status__c
                FROM Customer__c
                WHERE Id = :customerId
                LIMIT 1
            ];

            Http http = new Http();

            HttpRequest request = new HttpRequest();

            request.setEndpoint(
                'callout:KYC_Verification_API/users/1'
            );

            request.setMethod('GET');

            request.setTimeout(10000);

            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200) {

                customer.KYC_Status__c = 'Verified';

                update customer;

                IntegrationLogService.createInfoLog(
                    'KYC API',
                    'KYC verification successful',
                    customer.Id
                );

            } else {

                customer.KYC_Status__c = 'Rejected';

                update customer;

                IntegrationLogService.createErrorLog(
                    'KYC API',
                    'KYC verification failed',
                    customer.Id
                );
            }

        } catch (Exception ex) {

            IntegrationLogService.createErrorLog(
                'KYC API',
                ex.getMessage(),
                customerId
            );

            throw ex;
        }
    }
}