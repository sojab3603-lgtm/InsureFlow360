@IsTest
private class KYCVerificationServiceTest {

    @IsTest
    static void verifyCustomerKYCTest() {

        Customer__c customer = new Customer__c(
            Full_Name__c = 'Test Customer',
            Email__c = 'test@test.com'
        );

        insert customer;

        Test.setMock(
            HttpCalloutMock.class,
            new MockKYCResponse()
        );

        Test.startTest();

        KYCVerificationService.verifyCustomerKYC(
            customer.Id
        );

        Test.stopTest();

        Customer__c updatedCustomer = [
            SELECT KYC_Status__c
            FROM Customer__c
            WHERE Id = :customer.Id
        ];

        System.assertEquals(
            'Verified',
            updatedCustomer.KYC_Status__c
        );
    }
}