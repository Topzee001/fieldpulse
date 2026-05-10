import logging

logger = logging.getLogger(__name__)


class AuditLogMiddleware:
    """
    Audit logging middleware.
    Logs authenticated API requests, auth attempts, and failed logins
    for debugging and analytics.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Log requests to sensitive auth endpoints
        if request.path.startswith('/api/auth/'):
            logger.info(
                f"[AUDIT] Auth request: {request.method} {request.path} "
                f"from {request.META.get('REMOTE_ADDR')}"
            )

        response = self.get_response(request)

        # Log failed login attempts
        if response.status_code == 401 and request.path.startswith('/api/auth/login/'):
            logger.warning(
                f"[AUDIT] Failed login attempt from {request.META.get('REMOTE_ADDR')}"
            )

        # Log authenticated API requests
        if hasattr(request, 'user') and request.user.is_authenticated:
            if request.path.startswith('/api/'):
                logger.info(
                    f"[AUDIT] {request.method} {request.path} "
                    f"user={request.user.email} "
                    f"status={response.status_code}"
                )

        return response
