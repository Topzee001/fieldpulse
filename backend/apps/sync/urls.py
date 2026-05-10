from django.urls import path
from .views import SyncStatusView, ConflictResolveView

urlpatterns = [
    path('status/', SyncStatusView.as_view(), name='sync-status'),
    path('conflicts/<int:conflict_id>/resolve/', ConflictResolveView.as_view(), name='conflict-resolve'),
]