from django.db.models import Q
from django_filters import rest_framework as filters
from .models import Job

class JobFilter(filters.FilterSet):
    """
    Filtering for job list endpoint.
    Supports status, date range, and search.
    """
    status = filters.ChoiceFilter(choices=Job.Status.choices)
    
    # Date range filters
    scheduled_from = filters.DateTimeFilter(field_name='scheduled_start', lookup_expr='gte')
    scheduled_to = filters.DateTimeFilter(field_name='scheduled_start', lookup_expr='lte')
    
    # Search across multiple fields
    search = filters.CharFilter(method='filter_search')
    
    class Meta:
        model = Job
        fields = ['status', 'scheduled_from', 'scheduled_to', 'search']
    
    def filter_search(self, queryset, name, value):
        """Search by customer name, address, or job ID"""
        return queryset.filter(
            Q(job_id__icontains=value) |
            Q(customer_name__icontains=value) |
            Q(customer_address__icontains=value)
        )