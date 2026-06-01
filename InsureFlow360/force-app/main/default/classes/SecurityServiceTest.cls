@isTest
private class SecurityServiceTest {

    @isTest static void testGetUserSecurityContext() {
        Test.startTest();
            SecurityService.SecurityContext context = SecurityService.getUserSecurityContext();
        Test.stopTest();

        System.assertNotEquals(null, context);
        System.assertNotEquals(null, context.accessibleFields);
        System.assert(context.accessibleFields.size() > 0);
    }

    @isTest static void testSanitizeInput() {
        String maliciousInput = '<script>alert(xss)</script>';
        String sanitized = SecurityService.sanitizeInput(maliciousInput);

        System.assert(!sanitized.contains('<script>'));
        System.assert(!sanitized.contains('</script>'));
    }

    @isTest static void testEncodeOutput() {
        String output = 'Test output';
        String encoded = SecurityService.encodeOutput(output);

        System.assertEquals('Test output', encoded);
    }

    @isTest static void testValidateFieldAccess() {
        Test.startTest();
            SecurityService.validateFieldAccess(Claim__c.sObjectType, new List<String>{ 'Id', 'Name' });
        Test.stopTest();

        // If no exception is thrown, test passes
        System.assert(true);
    }

    @isTest static void testProcessBatch() {
        List<Claim__c> claims = new List<Claim__c>();
        for (Integer i = 0; i < 10; i++) {
            claims.add(new Claim__c(Claim_Amount__c = 1000 + i));
        }

        Test.startTest();
            SecurityService.processBatch(claims, 'insert');
        Test.stopTest();

        System.assertEquals(10, [SELECT COUNT() FROM Claim__c]);
    }

    @isTest static void testQueryWithLimit() {
        for (Integer i = 0; i < 50; i++) {
            insert new Claim__c(Claim_Amount__c = 1000 + i);
        }

        Test.startTest();
            List<SObject> results = SecurityService.queryWithLimit(
                'SELECT Id FROM Claim__c ORDER BY CreatedDate DESC',
                10
            );
        Test.stopTest();

        System.assert(results.size() <= 10);
    }
}
