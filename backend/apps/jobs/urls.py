from django.urls import path
from .views import (
    JobListView, JobDetailView, JobStatusUpdateView,
    JobChecklistView, JobSyncView, JobPhotoUploadView, JobSignatureUploadView
)

urlpatterns = [
    path('', JobListView.as_view(), name='job-list'),
    path('<int:id>/', JobDetailView.as_view(), name='job-detail'),
    path('<int:id>/status/', JobStatusUpdateView.as_view(), name='job-status'),
    path('<int:id>/checklist/', JobChecklistView.as_view(), name='job-checklist'),
    path('<int:id>/sync/', JobSyncView.as_view(), name='job-sync'),
    path('<int:id>/photos/', JobPhotoUploadView.as_view(), name='job-photo-upload'),
    path('<int:id>/signature/', JobSignatureUploadView.as_view(), name='job-signature-upload'),
]




