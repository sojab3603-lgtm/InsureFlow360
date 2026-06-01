public with sharing class NotificationService {

    public class Notification {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public String type { get; set; } // info, warning, error, success
        @AuraEnabled public String relatedRecordId { get; set; }
        @AuraEnabled public DateTime createdDate { get; set; }
        @AuraEnabled public Boolean isRead { get; set; }

        public Notification(String title, String message, String type, String relatedRecordId) {
            this.id = generateId();
            this.title = title;
            this.message = message;
            this.type = type;
            this.relatedRecordId = relatedRecordId;
            this.createdDate = DateTime.now();
            this.isRead = false;
        }

        private String generateId() {
            return String.valueOf(System.currentTimeMillis()) + String.valueOf(Math.random()).substring(2, 7);
        }
    }

    public static List<Notification> inMemoryNotifications = new List<Notification>();

    @AuraEnabled
    public static Notification sendNotification(String title, String message, String type, String relatedRecordId) {
        Notification notification = new Notification(title, message, type, relatedRecordId);
        inMemoryNotifications.add(notification);

        // Keep only the last 100 notifications
        if (inMemoryNotifications.size() > 100) {
            inMemoryNotifications.remove(0);
        }

        // Log the notification
        IntegrationLogService.createInfoLog(
            'Notification Service',
            'Notification sent: ' + title,
            relatedRecordId
        );

        return notification;
    }

    @AuraEnabled
    public static List<Notification> getNotifications() {
        return inMemoryNotifications;
    }

    @AuraEnabled
    public static List<Notification> getUnreadNotifications() {
        List<Notification> unread = new List<Notification>();
        for (Notification n : inMemoryNotifications) {
            if (!n.isRead) {
                unread.add(n);
            }
        }
        return unread;
    }

    @AuraEnabled
    public static void markAsRead(String notificationId) {
        for (Notification n : inMemoryNotifications) {
            if (n.id == notificationId) {
                n.isRead = true;
                break;
            }
        }
    }

    @AuraEnabled
    public static void markAllAsRead() {
        for (Notification n : inMemoryNotifications) {
            n.isRead = true;
        }
    }

    @AuraEnabled
    public static void deleteNotification(String notificationId) {
        for (Integer i = 0; i < inMemoryNotifications.size(); i++) {
            if (inMemoryNotifications[i].id == notificationId) {
                inMemoryNotifications.remove(i);
                break;
            }
        }
    }

    // Trigger notification for high-risk claims
    public static void notifyHighRiskClaim(Claim__c claim) {
        sendNotification(
            'High-Risk Claim Alert',
            'Claim ' + claim.Name + ' has been flagged as high risk with score ' + claim.Fraud_Score__c,
            'warning',
            claim.Id
        );
    }

    // Trigger notification for claim approval
    public static void notifyClaimApproved(Claim__c claim) {
        sendNotification(
            'Claim Approved',
            'Claim ' + claim.Name + ' for amount $' + claim.Claim_Amount__c + ' has been approved',
            'success',
            claim.Id
        );
    }

    // Trigger notification for claim rejection
    public static void notifyClaimRejected(Claim__c claim) {
        sendNotification(
            'Claim Rejected',
            'Claim ' + claim.Name + ' has been rejected',
            'error',
            claim.Id
        );
    }
}
