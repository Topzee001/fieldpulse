import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings
import json

# Initialize once
if not firebase_admin._apps:
    cred_path = getattr(settings, 'FCM_CREDENTIALS_PATH', None)
    if cred_path and cred_path.exists():
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)

def send_job_assignment_notification(user, job):
    """Send push notification to a technician about new job assignment."""
    if not user.fcm_token:
        return None
    
    message = messaging.Message(
        notification=messaging.Notification(
            title=f"New Job: {job.job_id}",
            body=f"{job.customer_name} - {job.scheduled_start.strftime('%I:%M %p')}"
        ),
        data={
            'type': 'new_job',
            'job_id': str(job.id),
            'job_number': job.job_id,
        },
        token=user.fcm_token,
    )
    try:
        response = messaging.send(message)
        return response
    except Exception as e:
        print(f"FCM send failed: {e}")
        return None