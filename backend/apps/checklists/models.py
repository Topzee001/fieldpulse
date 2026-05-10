from django.db import models
from django.conf import settings
from jobs.models import Job

class ChecklistResponse(models.Model):
    """
    Stores the technician's responses to a job's dynamic checklist.
    One-to-one with Job because each job has exactly one checklist response.
    """
    
    job = models.OneToOneField(
        Job, 
        on_delete=models.CASCADE, 
        related_name='checklist_response',
        help_text="The job this checklist belongs to"
    )
    
    # Field-value pairs: {"field_name": "user input"}
    # Structure: {
    #   "customer_signature": "https://minio.bucket/signature_123.png",
    #   "equipment_status": "Good",
    #   "photos": ["url1", "url2"]
    # }
    data = models.JSONField(default=dict)
    
    # Sync tracking
    synced_at = models.DateTimeField(null=True, blank=True)
    last_modified = models.DateTimeField(auto_now=True)
    
    # Draft tracking (for incomplete forms)
    is_draft = models.BooleanField(default=True)
    last_saved_draft = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        db_table = 'checklist_responses'
        indexes = [
            models.Index(fields=['job', 'synced_at']),
            models.Index(fields=['is_draft', 'last_modified']),
        ]
    
    def __str__(self):
        return f"Checklist for {self.job.job_id} (Draft: {self.is_draft})"


class ChecklistTemplate(models.Model):
    """
    Optional: Pre-defined checklist templates for different job types.
    This allows reusing schema across multiple jobs.
    """
    
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    schema = models.JSONField(
        help_text="JSON schema definition for the checklist"
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'checklist_templates'
    
    def __str__(self):
        return self.name