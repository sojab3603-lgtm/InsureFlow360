@isTest
private class PerformanceOptimizationServiceTest {

    @isTest static void testCacheData() {
        String testKey = 'testKey';
        String testData = 'test data';

        Test.startTest();
            PerformanceOptimizationService.cacheData(testKey, testData, 300);
            Object cachedData = PerformanceOptimizationService.getCachedData(testKey);
        Test.stopTest();

        System.assertEquals(testData, cachedData);
    }

    @isTest static void testClearCache() {
        String testKey = 'testKey';

        PerformanceOptimizationService.cacheData(testKey, 'data', 300);
        PerformanceOptimizationService.clearCache(testKey);

        Object cachedData = PerformanceOptimizationService.getCachedData(testKey);
        System.assertEquals(null, cachedData);
    }

    @isTest static void testGetClaimsOptimized() {
        List<Claim__c> testClaims = new List<Claim__c>();
        testClaims.add(new Claim__c(Claim_Amount__c = 5000));
        testClaims.add(new Claim__c(Claim_Amount__c = 15000));
        testClaims.add(new Claim__c(Claim_Amount__c = 500000));
        insert testClaims;

        Test.startTest();
            List<Claim__c> result = PerformanceOptimizationService.getClaimsOptimized(10000);
        Test.stopTest();

        System.assertEquals(2, result.size());
    }

    @isTest static void testGetClaimsLazyLoad() {
        for (Integer i = 0; i < 50; i++) {
            insert new Claim__c(Claim_Amount__c = 1000 + i);
        }

        Test.startTest();
            List<Claim__c> result = PerformanceOptimizationService.getClaimsLazyLoad(0, 10);
        Test.stopTest();

        System.assert(result.size() <= 10);
    }

    @isTest static void testGetClaimAggregates() {
        insert new List<Claim__c>{
            new Claim__c(Claim_Amount__c = 10000),
            new Claim__c(Claim_Amount__c = 20000),
            new Claim__c(Claim_Amount__c = 30000)
        };

        Test.startTest();
            AggregateResult[] results = PerformanceOptimizationService.getClaimAggregates();
        Test.stopTest();

        System.assertEquals(1, results.size());
    }

    @isTest static void testGetClaimsByStatusEfficient() {
        List<Claim__c> claims = new List<Claim__c>{
            new Claim__c(Claim_Amount__c = 10000, Claim_Status__c = 'Approved'),
            new Claim__c(Claim_Amount__c = 20000, Claim_Status__c = 'Submitted')
        };
        insert claims;

        Test.startTest();
            List<Claim__c> result = PerformanceOptimizationService.getClaimsByStatusEfficient('Approved');
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('Approved', result[0].Claim_Status__c);
    }
}
