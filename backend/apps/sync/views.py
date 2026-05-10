from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from .models import SyncQueue, Conflict
from jobs.models import Job, Photo
from checklists.models import ChecklistResponse

class ConflictResolveView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request, conflict_id):
        try:
            conflict = Conflict.objects.get(id=conflict_id, user=request.user, resolved=False)
        except Conflict.DoesNotExist:
            return Response({'error': 'Conflict not found'}, status=404)
        
        resolution = request.data.get('resolution')
        if resolution not in ['keep_local', 'keep_server']:
            return Response({'error': 'Invalid resolution'}, status=400)
        
        job = conflict.job
        
        if resolution == 'keep_local':
            # Apply local data to job's checklist
            # Here we assume local_data contains the checklist response
            response, _ = ChecklistResponse.objects.get_or_create(job=job)
            response.data = conflict.local_data
            response.is_draft = False
            response.synced_at = timezone.now()
            response.save()
            
            job.version += 1 # Update job version
            job.save()
        else:
            pass
        
        conflict.resolved = True
        conflict.resolution = resolution
        conflict.resolved_at = timezone.now()
        conflict.save()
        
        return Response({'status': 'resolved', 'resolution': resolution, 'job_id': job.id,
            'new_version': job.version})

class SyncStatusView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        pending_sync = SyncQueue.objects.filter(
            user=request.user,
            completed=False
        ).count()

        pending_conflicts = Conflict.objects.filter(
            user=request.user,
            resolved=False
        ).count()

        unsynced_photos = Photo.objects.filter(job__assigned_to=request.user, is_synced=False).count()

        return Response({
            'pending_sync_items': pending_sync,
            'pending_conflicts': pending_conflicts,
            'unsynced_photos': unsynced_photos,
            'is_syncing': False,  
        })