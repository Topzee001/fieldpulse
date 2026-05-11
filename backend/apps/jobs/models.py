from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.conf import settings
from django.utils import timezone

class Job(models.Model):
    """
    Core job/assignment entity. Represents a task for a field technician.
    """
    
    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        IN_PROGRESS = 'in_progress', 'In Progress'
        COMPLETED = 'completed', 'Completed'
        CANCELLED = 'cancelled', 'Cancelled'
        OVERDUE = 'overdue', 'Overdue'  # Virtual status, computed
    
    job_id = models.CharField(
        max_length=50, 
        unique=True, 
        db_index=True,
        help_text="Human-readable job identifier (e.g., JOB-2025-001)"
    )
    
    assigned_to = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='jobs',
        db_index=True
    )
    
    customer_name = models.CharField(max_length=255)
    customer_phone = models.CharField(max_length=20)
    customer_email = models.EmailField(blank=True, null=True)
    customer_address = models.TextField()
    
    latitude = models.DecimalField(
        max_digits=9, 
        decimal_places=6,
        validators=[MinValueValidator(-90), MaxValueValidator(90)]
    )
    longitude = models.DecimalField(
        max_digits=9, 
        decimal_places=6,
        validators=[MinValueValidator(-180), MaxValueValidator(180)]
    )
    
    description = models.TextField()
    notes = models.TextField(blank=True, help_text="Internal notes for technician")
    
    scheduled_start = models.DateTimeField(db_index=True)
    scheduled_end = models.DateTimeField()
    
    status = models.CharField(
        max_length=20, 
        choices=Status.choices, 
        default=Status.PENDING,
        db_index=True
    )
    actual_start = models.DateTimeField(null=True, blank=True)
    actual_completion = models.DateTimeField(null=True, blank=True)
    
    checklist_schema = models.JSONField(
        default=dict,
        help_text="JSON schema defining the checklist fields for this job type"
    )
    
    version = models.IntegerField(default=1)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'jobs'
        ordering = ['scheduled_start', 'job_id']
        indexes = [
            # Composite index for common query patterns
            models.Index(fields=['assigned_to', 'status', 'scheduled_start']),
            # For version checking during sync
            models.Index(fields=['id', 'version']),
            # For date range filtering
            models.Index(fields=['scheduled_start', 'scheduled_end']),
        ]
    
    def __str__(self):
        return f"{self.job_id} - {self.customer_name} ({self.status})"
    
    @property
    def is_overdue(self):
        """Check if job is overdue (scheduled start passed and not completed)."""
        if self.status not in [self.Status.COMPLETED, self.Status.CANCELLED]:
            return self.scheduled_start < timezone.now()
        return False

class Photo(models.Model):
    """Photos captured during job checklist"""
    job = models.ForeignKey('jobs.Job', on_delete=models.CASCADE, related_name='photos')
    field_id = models.CharField(max_length=100, help_text="Checklist field ID this photo belongs to")
    image_url = models.URLField(max_length=500)
    thumbnail_url = models.URLField(max_length=500, blank=True)
    timestamp = models.DateTimeField()
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)
    is_synced = models.BooleanField(default=True)   # True if uploaded to cloud
    
    class Meta:
        db_table = 'photos'
        ordering = ['-timestamp']
    
    def __str__(self):
        return f"Photo for {self.job.job_id} - {self.field_id}"

class Signature(models.Model):
    """Customer signature for a job"""
    job = models.OneToOneField('jobs.Job', on_delete=models.CASCADE, related_name='signature')
    signature_url = models.URLField(max_length=500)
    timestamp = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'signatures'
    
    def __str__(self):
        return f"Signature for {self.job.job_id}"