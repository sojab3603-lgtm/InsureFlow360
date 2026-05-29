@isTest
global class PaymentGatewayServiceTest {
    global class MockPaymentFailure implements HttpCalloutMock {
        global HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"error":"failed"}');
            response.setStatusCode(500);
            return response;
        }
    }

    @isTest static void testProcessPaymentLogsSuccess() {
        Account acct = new Account(Name = 'Payment Success');
        insert acct;

        Test.setMock(HttpCalloutMock.class, new MockKYCResponse());

        Test.startTest();
            Boolean result = PaymentGatewayService.processPayment(500.00, acct.Id);
        Test.stopTest();

        System.assertEquals(true, result);

        Integration_Log__c log = [
            SELECT Status__c,
                   Log_Level__c,
                   Related_Record_Id__c
            FROM Integration_Log__c
            WHERE Related_Record_Id__c = :String.valueOf(acct.Id)
            LIMIT 1
        ];

        System.assertEquals('Success', log.Status__c);
        System.assertEquals('INFO', log.Log_Level__c);
    }

    @isTest static void testProcessPaymentLogsFailureOnHttpError() {
        Account acct = new Account(Name = 'Payment Failure');
        insert acct;

        Test.setMock(HttpCalloutMock.class, new MockPaymentFailure());

        Test.startTest();
            Boolean result = PaymentGatewayService.processPayment(500.00, acct.Id);
        Test.stopTest();

        System.assertEquals(false, result);

        Integration_Log__c log = [
            SELECT Status__c,
                   Log_Level__c,
                   Related_Record_Id__c
            FROM Integration_Log__c
            WHERE Related_Record_Id__c = :String.valueOf(acct.Id)
            LIMIT 1
        ];

        System.assertEquals('Failed', log.Status__c);
        System.assertEquals('ERROR', log.Log_Level__c);
    }
}
