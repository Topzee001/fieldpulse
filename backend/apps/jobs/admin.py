from django.contrib import admin
from .models import Job

@admin.register(Job)
class JobAdmin(admin.ModelAdmin):
    list_display = ['job_id', 'customer_name', 'assigned_to', 'status', 'scheduled_start']
    list_filter = ['status', 'assigned_to', 'scheduled_start']
    search_fields = ['job_id', 'customer_name', 'customer_phone', 'customer_address']
    readonly_fields = ['version', 'created_at', 'updated_at']   