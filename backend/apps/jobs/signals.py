from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Job
from notifications.fcm import send_job_assignment_notification

@receiver(post_save, sender=Job)
def notify_technician_on_new_job(sender, instance, created, **kwargs):
    if created:
        send_job_assignment_notification(instance.assigned_to, instance)