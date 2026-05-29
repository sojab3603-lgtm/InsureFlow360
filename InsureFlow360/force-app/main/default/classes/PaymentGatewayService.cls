public with sharing class PaymentGatewayService {

    public static Boolean processPayment(
        Decimal amount,
        Id paymentId
    ) {

        try {

            Http http = new Http();

            HttpRequest request = new HttpRequest();

            request.setEndpoint(
                'callout:KYC_Verification_API/posts'
            );

            request.setMethod('POST');

            request.setHeader(
                'Content-Type',
                'application/json'
            );

            request.setBody(
                JSON.serialize(
                    new Map<String, Object>{
                        'amount' => amount,
                        'paymentId' => paymentId
                    }
                )
            );

            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200 ||
                response.getStatusCode() == 201) {

                IntegrationLogService.createInfoLog(
                    'Payment Gateway',
                    'Payment successful',
                    String.valueOf(paymentId)
                );

                return true;
            }

            IntegrationLogService.createErrorLog(
                'Payment Gateway',
                'Payment failed',
                String.valueOf(paymentId)
            );

            return false;

        } catch (Exception ex) {

            IntegrationLogService.createErrorLog(
                'Payment Gateway',
                ex.getMessage(),
                String.valueOf(paymentId)
            );

            return false;
        }
    }
}