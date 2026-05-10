from rest_framework import serializers
from .models import Conflict, SyncQueue

class ConflictSerializer(serializers.ModelSerializer):
    job_id = serializers.IntegerField(source='job.id', read_only=True)
    job_title = serializers.CharField(source='job.job_id', read_only=True)
    
    class Meta:
        model = Conflict
        fields = ['id', 'job_id', 'job_title', 'local_data', 'server_data', 
                  'conflicting_fields', 'resolved', 'created_at']
        read_only_fields = ['id', 'created_at']


# class SyncQueueSerializer(serializers.ModelSerializer):
#     job_id = serializers.IntegerField(source='job.id', read_only=True)
#     job_title = serializers.CharField(source='job.job_id', read_only=True)
    
#     class Meta:
#         model = SyncQueue
#         fields = ['id', 'job_id', 'job_title', 'table_name', 'record_id', 
#                   'action', 'data', 'is_synced', 'created_at']
#         read_only_fields = ['id', 'created_at']