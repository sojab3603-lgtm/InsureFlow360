public with sharing class PerformanceOptimizationService {

    public class CacheKey {
        public String key { get; set; }
        public Long expirationTime { get; set; }

        public CacheKey(String keyValue, Long ttlSeconds) {
            this.key = keyValue;
            this.expirationTime = System.currentTimeMillis() + (ttlSeconds * 1000);
        }

        public Boolean isExpired() {
            return System.currentTimeMillis() > expirationTime;
        }
    }

    private static Map<String, Object> queryCache = new Map<String, Object>();
    private static Map<String, CacheKey> cacheExpiration = new Map<String, CacheKey>();

    @AuraEnabled(cacheable=true)
    public static Object getCachedData(String cacheKey) {
        if (queryCache.containsKey(cacheKey)) {
            CacheKey expiration = cacheExpiration.get(cacheKey);
            if (expiration != null && !expiration.isExpired()) {
                return queryCache.get(cacheKey);
            } else {
                queryCache.remove(cacheKey);
                cacheExpiration.remove(cacheKey);
            }
        }
        return null;
    }

    public static void cacheData(String cacheKey, Object data, Long ttlSeconds) {
        queryCache.put(cacheKey, data);
        cacheExpiration.put(cacheKey, new CacheKey(cacheKey, ttlSeconds));
    }

    public static void clearCache(String cacheKey) {
        queryCache.remove(cacheKey);
        cacheExpiration.remove(cacheKey);
    }

    public static void clearAllCache() {
        queryCache.clear();
        cacheExpiration.clear();
    }

    public static List<Claim__c> getClaimsOptimized(Decimal minAmount) {
        return [
            SELECT Id, Name, Claim_Amount__c, Claim_Status__c, Fraud_Status__c
            FROM Claim__c
            WHERE Claim_Amount__c >= :minAmount
            ORDER BY Claim_Amount__c DESC
            LIMIT 100
        ];
    }

    public static List<Claim__c> getClaimsLazyLoad(Integer offsetAmount, Integer pageSize) {
        return [
            SELECT Id, Name, Claim_Amount__c, Claim_Status__c, Fraud_Status__c
            FROM Claim__c
            ORDER BY CreatedDate DESC
            LIMIT :pageSize
            OFFSET :offsetAmount
        ];
    }

    public static AggregateResult[] getClaimAggregates() {
        return [
            SELECT COUNT(Id) recordCount, SUM(Claim_Amount__c) totalAmount
            FROM Claim__c
        ];
    }

    public static List<Claim__c> getClaimsByStatusEfficient(String status) {
        return [
            SELECT Id, Name, Claim_Amount__c
            FROM Claim__c
            WHERE Claim_Status__c = :status
            LIMIT 1000
        ];
    }
}
