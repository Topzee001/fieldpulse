from django.db import models
from django.conf import settings
from jobs.models import Job
from django.utils import timezone
from datetime import timedelta

class SyncQueue(models.Model):
    """
    Queue for offline changes that need to be synced to server.
    When a technician works offline, changes go here.
    When online, this queue is processed.
    """
    
    class ActionType(models.TextChoices):
        CHECKLIST_UPDATE = 'checklist_update', 'Checklist Update'
        STATUS_CHANGE = 'status_change', 'Status Change'
        PHOTO_UPLOAD = 'photo_upload', 'Photo Upload'
        SIGNATURE_UPLOAD = 'signature_upload', 'Signature Upload'
    
    job = models.ForeignKey(
        Job, 
        on_delete=models.CASCADE, 
        related_name='sync_queue_items'
    )
    
    # Which technician made the change
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE,
        null=True
    )
    
    action = models.CharField(max_length=20, choices=ActionType.choices)
    
    # The actual change data
    payload = models.JSONField()
    
    # Retry mechanism
    retry_count = models.IntegerField(default=0)
    last_retry = models.DateTimeField(null=True, blank=True)
    next_retry = models.DateTimeField(
        null=True, 
        blank=True,
        help_text="When to attempt retry (exponential backoff)"
    )
    
    # Status tracking
    completed = models.BooleanField(default=False)
    completed_at = models.DateTimeField(null=True, blank=True)
    error_message = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'sync_queue'
        ordering = ['created_at']
        indexes = [
            models.Index(fields=['completed', 'next_retry']),
            models.Index(fields=['job', 'action']),
        ]
    
    def __str__(self):
        return f"{self.action} for {self.job.job_id} (Retry: {self.retry_count})"
    
    def schedule_retry(self):
        """
        Exponential backoff: 2^retry_count seconds
        retry 0: 2s, retry 1: 4s, retry 2: 8s, retry 3: 16s...
        Max 10 retries.
        """
        if self.retry_count >= 10:
            self.completed = True
            self.error_message = "Max retries exceeded"
        else:
            delay_seconds = 2 ** self.retry_count  # Exponential
            self.next_retry = timezone.now() + timedelta(seconds=delay_seconds)
            self.last_retry = timezone.now()
            self.retry_count += 1
        self.save(update_fields=['retry_count', 'next_retry', 'last_retry'])


class Conflict(models.Model):
    """
    Stores conflicts when local and server versions diverge.
    Requires user resolution.
    """
    
    class ResolutionType(models.TextChoices):
        KEEP_LOCAL = 'keep_local', 'Keep Local Changes'
        KEEP_SERVER = 'keep_server', 'Accept Server Version'
        MERGED = 'merged', 'Manually Merged'
    
    job = models.ForeignKey(Job, on_delete=models.CASCADE, related_name='conflicts')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    
    # The two conflicting versions
    local_data = models.JSONField()
    server_data = models.JSONField()
    
    # Which fields conflicted (for UI highlighting)
    conflicting_fields = models.JSONField(default=list)
    
    # Resolution tracking
    resolved = models.BooleanField(default=False)
    resolution = models.CharField(max_length=20, choices=ResolutionType.choices, null=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'conflicts'
        indexes = [
            models.Index(fields=['job', 'resolved']),
        ]
    
    def __str__(self):
        return f"Conflict on {self.job.job_id} - Resolved: {self.resolved}"