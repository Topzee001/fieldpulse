from rest_framework.pagination import CursorPagination
from rest_framework.response import Response

class JobCursorPagination(CursorPagination):
    """
    Cursor pagination for job list.
    Uses scheduled_start and id for stable ordering.
    """
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100
    ordering = ['scheduled_start', 'id']
    cursor_query_param = 'cursor'
    
    def get_paginated_response(self, data):
        return Response({
            'next': self.get_next_link(),
            'previous': self.get_previous_link(),
            'count': None,
            'results': data
        })