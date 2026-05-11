
from rest_framework import serializers
from .models import Job, Photo, Signature
from django.utils import timezone

class JobListSerializer(serializers.ModelSerializer):
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    is_overdue = serializers.SerializerMethodField()
    scheduled_time = serializers.SerializerMethodField()

    class Meta:
        model = Job
        fields = [
            'id', 'job_id', 'customer_name', 'customer_address', 'scheduled_start', 
            'scheduled_time', 'status', 'status_display', 'is_overdue', 'version'
        ]

    def get_is_overdue(self, obj):
        """Check if job is overdue"""
        return obj.is_overdue
    
    def get_scheduled_time(self, obj):
        """Format scheduled time for display: 'Today 2:30 PM' or 'Tomorrow 9:00 AM'"""
        now = timezone.now().date()
        scheduled_date = obj.scheduled_start.date()
        
        if scheduled_date == now:
            return f"Today {obj.scheduled_start.strftime('%I:%M %p')}"
        elif scheduled_date == now + timezone.timedelta(days=1):
            return f"Tomorrow {obj.scheduled_start.strftime('%I:%M %p')}"
        else:
            return obj.scheduled_start.strftime('%b %d, %I:%M %p')

class JobDetailSerializer(serializers.ModelSerializer):
    """
    Full job serializer for detail view.
    Includes checklist schema and all customer info.
    """
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    is_overdue = serializers.SerializerMethodField()
    scheduled_window = serializers.SerializerMethodField()
    
    class Meta:
        model = Job
        fields = [
            'id', 'job_id', 'customer_name', 'customer_phone', 'customer_email',
            'customer_address', 'latitude', 'longitude', 'description', 'notes',
            'scheduled_start', 'scheduled_end', 'scheduled_window', 'status',
            'status_display', 'is_overdue', 'checklist_schema', 'version',
            'actual_start', 'actual_completion', 'created_at', 'updated_at', 'assigned_to'
        ]

    def get_is_overdue(self, obj):
        return obj.is_overdue
    
    def get_scheduled_window(self, obj):
        return {
            'start': obj.scheduled_start.isoformat(),
            'end': obj.scheduled_end.isoformat(),
            'display': f"{obj.scheduled_start.strftime('%I:%M %p')} - {obj.scheduled_end.strftime('%I:%M %p')}"
        }

class JobStatusUpdateSerializer(serializers.Serializer):
    """Serializer for updating job status"""
    status = serializers.ChoiceField(choices=Job.Status.choices)
    
    def validate_status(self, value):
        """Validate status transition logic"""
        job = self.context['job']
        
        # Status transition rules
        allowed_transitions = {
            Job.Status.PENDING: [Job.Status.IN_PROGRESS, Job.Status.CANCELLED],
            Job.Status.IN_PROGRESS: [Job.Status.COMPLETED, Job.Status.CANCELLED],
            Job.Status.COMPLETED: [],  # Terminal state
            Job.Status.CANCELLED: [],  # Terminal state
        }
        
        # Allow same status for idempotency
        if value == job.status:
            return value
            
        if value not in allowed_transitions.get(job.status, []):
            raise serializers.ValidationError(
                f"Cannot transition from {job.get_status_display()} to {dict(Job.Status.choices).get(value)}"
            )
        
        return value

class JobChecklistSaveSerializer(serializers.Serializer):
    """Serializer for saving checklist responses"""
    data = serializers.JSONField()
    is_draft = serializers.BooleanField(default=True)
    
    def validate_data(self, value):
        """Basic validation - full validation happens in form on client"""
        if not isinstance(value, dict):
            raise serializers.ValidationError("Data must be a JSON object")
        return value


class PhotoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Photo
        fields = ['id', 'job', 'field_id', 'image_url', 'thumbnail_url', 
                  'timestamp', 'latitude', 'longitude', 'uploaded_at']
        read_only_fields = ['id', 'image_url', 'thumbnail_url', 'uploaded_at']

class SignatureSerializer(serializers.ModelSerializer):
    class Meta:
        model = Signature
        fields = ['id', 'job', 'signature_url', 'timestamp']
        read_only_fields = ['id', 'timestamp']