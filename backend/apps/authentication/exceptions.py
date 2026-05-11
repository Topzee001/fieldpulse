from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status
from django.core.exceptions import ValidationError

def custom_exception_handler(exc, context):
    """
    Custom exception handler to return consistent error format
    for session expiration and other auth errors.
    """
    response = exception_handler(exc, context)
    
    if response is not None:
        if response.status_code == status.HTTP_401_UNAUTHORIZED:
            response.data = {
                'error': 'authentication_failed',
                'detail': response.data.get('detail', 'Invalid or expired token'),
                'code': 'token_expired' if 'expired' in str(response.data).lower() else 'invalid_token'
            }
        
        elif response.status_code == status.HTTP_400_BAD_REQUEST:
            if isinstance(response.data, dict):
                response.data = {
                    'error': 'validation_error',
                    'fields': response.data
                }
    
    return response


def rate_limit_exceeded(request, exception):
    """Custom response when rate limit is exceeded"""
    return Response(
        {
            'error': 'rate_limit_exceeded',
            'detail': 'Too many requests. Please try again later.',
            'retry_after': 60
        },
        status=status.HTTP_429_TOO_MANY_REQUESTS
    )