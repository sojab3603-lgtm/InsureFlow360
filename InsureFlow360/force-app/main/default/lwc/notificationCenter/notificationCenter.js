import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getUnreadNotifications from '@salesforce/apex/NotificationService.getUnreadNotifications';
import getNotifications from '@salesforce/apex/NotificationService.getNotifications';
import markAsRead from '@salesforce/apex/NotificationService.markAsRead';
import markAllAsRead from '@salesforce/apex/NotificationService.markAllAsRead';
import deleteNotification from '@salesforce/apex/NotificationService.deleteNotification';
import sendNotification from '@salesforce/apex/NotificationService.sendNotification';

export default class NotificationCenter extends LightningElement {
    @track notifications = [];
    @track unreadNotifications = [];
    @track showDropdown = false;
    @track isLoading = false;
    @track error = null;

    notificationsData;
    unreadData;

    @wire(getNotifications)
    wiredNotifications(result) {
        this.notificationsData = result;
        const { error, data } = result;
        if (data) {
            this.notifications = data.map(notification => ({
                ...notification,
                iconName: this.getNotificationIcon(notification.type),
                itemClass: this.getNotificationClass(notification.type)
            }));
            this.error = null;
        } else if (error) {
            this.error = error.body.message;
        }
    }

    @wire(getUnreadNotifications)
    wiredUnreadNotifications(result) {
        this.unreadData = result;
        const { error, data } = result;
        if (data) {
            this.unreadNotifications = data;
        } else if (error) {
            console.error('Error fetching unread notifications:', error);
        }
    }

    handleToggleDropdown() {
        this.showDropdown = !this.showDropdown;
    }

    handleCloseDropdown() {
        this.showDropdown = false;
    }

    handleMarkAsRead(event) {
        const notificationId = event.currentTarget.dataset.notificationId;
        this.isLoading = true;

        markAsRead({ notificationId })
            .then(() => {
                return refreshApex(this.notificationsData);
            })
            .then(() => {
                return refreshApex(this.unreadData);
            })
            .then(() => {
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error.body.message;
                this.isLoading = false;
            });
    }

    handleMarkAllAsRead() {
        this.isLoading = true;

        markAllAsRead()
            .then(() => {
                return refreshApex(this.notificationsData);
            })
            .then(() => {
                return refreshApex(this.unreadData);
            })
            .then(() => {
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error.body.message;
                this.isLoading = false;
            });
    }

    handleDeleteNotification(event) {
        const notificationId = event.currentTarget.dataset.notificationId;
        this.isLoading = true;

        deleteNotification({ notificationId })
            .then(() => {
                return refreshApex(this.notificationsData);
            })
            .then(() => {
                return refreshApex(this.unreadData);
            })
            .then(() => {
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error.body.message;
                this.isLoading = false;
            });
    }

    handleNotificationClick(event) {
        const recordId = event.currentTarget.dataset.recordId;
        if (recordId) {
            const notificationId = event.currentTarget.dataset.notificationId;
            this.handleMarkAsRead({ currentTarget: { dataset: { notificationId } } });
            window.location.href = `/${recordId}`;
        }
    }

    getNotificationIcon(type) {
        return type === 'error' ? 'utility:error' :
               type === 'warning' ? 'utility:warning' :
               type === 'success' ? 'utility:success' : 'utility:info';
    }

    getNotificationClass(type) {
        return 'notification-item ' + (type === 'error' ? 'notification-error' :
               type === 'warning' ? 'notification-warning' :
               type === 'success' ? 'notification-success' : 'notification-info');
    }

    get unreadCount() {
        return this.unreadNotifications.length;
    }

    get bellIconClass() {
        return this.unreadCount > 0 ? 'notification-badge' : '';
    }

    get dropdownClass() {
        return this.showDropdown ? 'slds-is-open' : '';
    }
}
