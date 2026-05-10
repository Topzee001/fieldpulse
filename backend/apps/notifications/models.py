from django.db import models
from django.conf import settings
from jobs.models import Job

class NotificationLog(models.Model):
    """
    Log of push notifications sent.
    Used for debugging and analytics (not strictly required but good practice).
    """
    
    class NotificationType(models.TextChoices):
        NEW_JOB = 'new_job', 'New Job Assignment'
        JOB_UPDATED = 'job_updated', 'Job Details Updated'
        SYNC_COMPLETE = 'sync_complete', 'Sync Complete'
        REMINDER = 'reminder', 'Job Reminder'
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE,
        related_name='notifications'
    )
    job = models.ForeignKey(Job, on_delete=models.CASCADE, null=True, blank=True)
    
    notification_type = models.CharField(max_length=20, choices=NotificationType.choices)
    title = models.CharField(max_length=255)
    body = models.TextField()
    
    # FCM delivery tracking
    fcm_message_id = models.CharField(max_length=255, blank=True)
    sent_at = models.DateTimeField(auto_now_add=True)
    delivered = models.BooleanField(default=False)
    tapped = models.BooleanField(default=False)  # User tapped notification
    
    class Meta:
        db_table = 'notification_logs'
        ordering = ['-sent_at']
        indexes = [
            models.Index(fields=['user', 'sent_at']),
            models.Index(fields=['delivered']),
        ]
    
    def __str__(self):
        return f"Notification to {self.user.email}: {self.title}"


class DeviceToken(models.Model):
    """
    Stores device tokens for push notifications.
    A user can have multiple devices (phone, tablet).
    """
    
    PLATFORM_CHOICES = [
        ('ios', 'iOS'),
        ('android', 'Android'),
    ]
    
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE,
        related_name='device_tokens'
    )
    
    fcm_token = models.CharField(
        max_length=255, 
        unique=True,
        help_text="FCM registration token"
    )
    platform = models.CharField(max_length=10, choices=PLATFORM_CHOICES)
    device_id = models.CharField(max_length=255, blank=True)
    
    is_active = models.BooleanField(default=True)
    last_used = models.DateTimeField(auto_now=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'device_tokens'
        indexes = [
            models.Index(fields=['user', 'is_active']),
            models.Index(fields=['fcm_token']),
        ]
    
    def __str__(self):
        return f"{self.user.email} - {self.platform} (Active: {self.is_active})"