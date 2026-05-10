from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.throttling import ScopedRateThrottle
from django.db import models
from django.utils import timezone
from datetime import datetime
from drf_spectacular.utils import extend_schema, extend_schema_view
from django.core.files.base import ContentFile
from PIL import Image, ImageOps

from .models import Job, Photo, Signature
from .serializers import (
    JobListSerializer, JobDetailSerializer, 
    JobStatusUpdateSerializer, JobChecklistSaveSerializer, PhotoSerializer
)
from .pagination import JobCursorPagination
from .filters import JobFilter
from checklists.models import ChecklistResponse
from checklists.utils import validate_checklist_response
from sync.models import Conflict
from django.core.files.storage import default_storage
import io
import os



class SyncUploadRateThrottle(ScopedRateThrottle):
    """Rate limit for heavy endpoints (sync and file uploads)"""
    scope = 'sync_uploads'


@extend_schema_view(
    get=extend_schema(description="Get paginated list of jobs for current technician"),
)
class JobListView(generics.ListCreateAPIView):
    """
    GET /api/jobs/ - Returns cursor-paginated list of jobs.
    POST /api/jobs/ - Creates a new job (Admin/Staff only ideally, but enabled for testing).
    """
    permission_classes = [IsAuthenticated]
    pagination_class = JobCursorPagination
    filterset_class = JobFilter

    def get_serializer_class(self):
        # Use simple serializer for listing, detailed serializer for creation/validation
        if self.request.method == 'POST':
            from .serializers import JobDetailSerializer
            return JobDetailSerializer
        return JobListSerializer
    
    def get_permissions(self):
        """Only admins can create jobs. Anyone authenticated can list."""
        from rest_framework.permissions import IsAdminUser, IsAuthenticated
        if self.request.method == 'POST':
            return [IsAdminUser()]
        return [IsAuthenticated()]

    def get_queryset(self):
        """Return jobs assigned to current user, ordered by scheduled time. Admin sees all."""
        queryset = Job.objects.all().select_related('assigned_to')
        
        # If not an admin/staff, restrict to their own assigned jobs
        if not self.request.user.is_staff:
            queryset = queryset.filter(assigned_to=self.request.user)
            
        return queryset

    def perform_create(self, serializer):
        """When admin creates a job, it uses the provided assigned_to field"""
        # We don't auto-assign to self anymore, we let the admin provide the technician ID in the payload!
        serializer.save()


class JobDetailView(generics.RetrieveAPIView):
    """
    GET /api/jobs/<id>/
    Returns full job details including checklist schema.
    """
    serializer_class = JobDetailSerializer
    permission_classes = [IsAuthenticated]
    lookup_field = 'id'
    
    def get_queryset(self):
        return Job.objects.filter(assigned_to=self.request.user)


class JobStatusUpdateView(APIView):
    """
    PATCH /api/jobs/<id>/status/
    Update job status (pending -> in_progress -> completed)
    """
    permission_classes = [IsAuthenticated]
    
    def patch(self, request, id):
        try:
            job = Job.objects.get(id=id, assigned_to=request.user)
        except Job.DoesNotExist:
            return Response({'error': 'Job not found'}, status=status.HTTP_404_NOT_FOUND)
        
        serializer = JobStatusUpdateSerializer(data=request.data, context={'job': job})
        serializer.is_valid(raise_exception=True)
        
        new_status = serializer.validated_data['status']
        old_status = job.status
        
        job.status = new_status
        
        # Track actual start/completion times
        if new_status == Job.Status.IN_PROGRESS and not job.actual_start:
            job.actual_start = timezone.now()
        elif new_status == Job.Status.COMPLETED and not job.actual_completion:
            job.actual_completion = timezone.now()
        
        # Increment version for conflict detection
        job.version += 1
        job.save()
        
        return Response({
            'status': 'updated',
            'old_status': old_status,
            'new_status': new_status,
            'version': job.version
        })


class JobChecklistView(APIView):
    """
    PUT/PATCH /api/jobs/<id>/checklist/
    Save checklist responses (full or partial)
    """
    permission_classes = [IsAuthenticated]
    
    def get_checklist_response(self, job, user):
        """Get or create checklist response for this job"""
        response, created = ChecklistResponse.objects.get_or_create(
            job=job,
            defaults={'data': {}, 'is_draft': True}
        )
        return response

    
    def get(self, request, id):
        """Get existing checklist response for this job"""
        try:
            job = Job.objects.get(id=id, assigned_to=request.user)
        except Job.DoesNotExist:
            return Response({'error': 'Job not found'}, status=status.HTTP_404_NOT_FOUND)
        
        response = self.get_checklist_response(job, request.user)
        
        return Response({
            'data': response.data,
            'is_draft': response.is_draft,
            'synced_at': response.synced_at,
            'last_modified': response.last_modified
        })
    
    def put(self, request, id):
        """Full save of checklist (replace all data)"""
        return self._save_checklist(request, id, partial=False)
    
    def patch(self, request, id):
        """Partial save of checklist (merge with existing)"""
        return self._save_checklist(request, id, partial=True)
    
    def _save_checklist(self, request, id, partial):
        try:
            job = Job.objects.get(id=id, assigned_to=request.user)
        except Job.DoesNotExist:
            return Response({'error': 'Job not found'}, status=status.HTTP_404_NOT_FOUND)
        
        serializer = JobChecklistSaveSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        response = self.get_checklist_response(job, request.user)
        
        if partial:
            # Merge: update only provided fields
            response.data.update(serializer.validated_data['data'])
        else:
            # Replace: full overwrite
            response.data = serializer.validated_data['data']
        
        response.is_draft = serializer.validated_data.get('is_draft', True)
        
        # Validate data against schema if they are submitting the final version
        if not response.is_draft:
            is_valid, validation_errors = validate_checklist_response(
                response.data, 
                job.checklist_schema
            )
            if not is_valid:
                return Response({'validation_errors': validation_errors}, status=status.HTTP_400_BAD_REQUEST)
        
        # If not draft, mark as synced
        if not response.is_draft:
            response.synced_at = timezone.now()
        
        response.save()
        
        # Increment job version for conflict detection
        job.version += 1
        job.save(update_fields=['version'])
        
        return Response({
            'data': response.data,
            'is_draft': response.is_draft,
            'synced_at': response.synced_at,
            'version': job.version
        })


class JobSyncView(APIView):
    """
    POST /api/jobs/<id>/sync/
    Batch sync offline changes (checklist + status + photos in one request)
    """
    permission_classes = [IsAuthenticated]
    throttle_classes = [SyncUploadRateThrottle]

    def post(self, request, id):
        try:
            job = Job.objects.get(id=id, assigned_to=request.user)
        except Job.DoesNotExist:
            return Response({'error': 'Job not found'}, status=status.HTTP_404_NOT_FOUND)

        received_version = request.data.get('version', job.version)

        # Conflict detection
        if received_version < job.version:
            # Fetch current checklist response
            current_data = {}
            try:
                resp = ChecklistResponse.objects.get(job=job)
                current_data = resp.data
            except ChecklistResponse.DoesNotExist:
                pass

            conflict = Conflict.objects.create(
                job=job,
                user=request.user,
                local_data=request.data.get('checklist_data', {}),
                server_data=current_data,
                conflicting_fields=list(set(request.data.get('checklist_data', {}).keys()) & set(current_data.keys()))
            )
            return Response({
                'conflict': True,
                'conflict_id': conflict.id,
                'message': 'Job was modified on server. Please resolve conflict.'
            }, status=status.HTTP_409_CONFLICT)

        # Apply updates
        if 'checklist_data' in request.data:
            response, _ = ChecklistResponse.objects.get_or_create(job=job)
            response.data.update(request.data['checklist_data'])
            response.is_draft = False
            response.synced_at = timezone.now()
            response.save()

        # Apply status update if present
        if 'status' in request.data:
            new_status = request.data['status']
            if new_status in [Job.Status.IN_PROGRESS, Job.Status.COMPLETED]:
                job.status = new_status
                if new_status == Job.Status.IN_PROGRESS and not job.actual_start:
                    job.actual_start = timezone.now()
                elif new_status == Job.Status.COMPLETED and not job.actual_completion:
                    job.actual_completion = timezone.now()

        # Increment version
        job.version += 1
        job.save()

        return Response({
            'synced': True,
            'new_version': job.version,
            'conflicts': False
        })

class JobPhotoUploadView(APIView):
    """
    POST /api/jobs/<id>/photos/
    Upload a photo for a specific job.
    Supports multipart/form-data with field 'photo' and optional 'field_id', 'latitude', 'longitude'.
    """
    permission_classes = [IsAuthenticated]
    throttle_classes = [SyncUploadRateThrottle]

    def post(self, request, id):
        try:
            job = Job.objects.get(id=id, assigned_to=request.user)
        except Job.DoesNotExist:
            return Response({'error': 'Job not found'}, status=status.HTTP_404_NOT_FOUND)

        uploaded_file = request.FILES.get('photo')
        if not uploaded_file:
            return Response({'error': 'No photo provided'}, status=status.HTTP_400_BAD_REQUEST)

        # Validate image
        if not uploaded_file.content_type.startswith('image/'):
            return Response({'error': 'File must be an image'}, status=status.HTTP_400_BAD_REQUEST)

        # Compress image
        img = Image.open(uploaded_file)
        # Fix EXIF orientation
        try:
            img = ImageOps.exif_transpose(img)
        except:
            pass

        # Resize to max 1200px longest edge
        max_size = 1200
        if max(img.size) > max_size:
            ratio = max_size / max(img.size)
            new_size = (int(img.size[0] * ratio), int(img.size[1] * ratio))
            img = img.resize(new_size, Image.Resampling.LANCZOS)

        # Compress to JPEG 80% quality
        output = io.BytesIO()
        img.convert('RGB').save(output, format='JPEG', quality=80)
        compressed_data = output.getvalue()

        # Generate file name
        ext = '.jpg'
        filename = f"jobs/{job.id}/photos/{datetime.now().timestamp()}{ext}"
        saved_path = default_storage.save(filename, ContentFile(compressed_data))

        # Create photo record
        photo = Photo.objects.create(
            job=job,
            field_id=request.data.get('field_id', 'photo'),
            image_url=default_storage.url(saved_path),
            timestamp=datetime.now(),
            latitude=request.data.get('latitude'),
            longitude=request.data.get('longitude'),
            is_synced=True  # Uploaded directly
        )

        # For offline queue, we would set is_synced=False and queue; but direct upload is fine for now.

        return Response({
            'id': photo.id,
            'image_url': photo.image_url,
            'timestamp': photo.timestamp.isoformat(),
            'field_id': photo.field_id
        }, status=status.HTTP_201_CREATED)

class JobSignatureUploadView(APIView):
    """
    POST /api/jobs/<id>/signature/
    Upload a signature PNG for a job.
    """
    permission_classes = [IsAuthenticated]
    throttle_classes = [SyncUploadRateThrottle]

    def post(self, request, id):
        try:
            job = Job.objects.get(id=id, assigned_to=request.user)
        except Job.DoesNotExist:
            return Response({'error': 'Job not found'}, status=status.HTTP_404_NOT_FOUND)

        uploaded_file = request.FILES.get('signature')
        if not uploaded_file:
            return Response({'error': 'No signature provided'}, status=status.HTTP_400_BAD_REQUEST)

        # Validate PNG
        if not uploaded_file.content_type == 'image/png':
            return Response({'error': 'Signature must be PNG'}, status=status.HTTP_400_BAD_REQUEST)

        # Generate file name
        filename = f"jobs/{job.id}/signature_{datetime.now().timestamp()}.png"
        saved_path = default_storage.save(filename, uploaded_file)

        # Create or update signature
        signature, created = Signature.objects.update_or_create(
            job=job,
            defaults={'signature_url': default_storage.url(saved_path)}
        )

        return Response({
            'id': signature.id,
            'signature_url': signature.signature_url,
            'timestamp': signature.timestamp.isoformat()
        }, status=status.HTTP_200_OK if not created else status.HTTP_201_CREATED)