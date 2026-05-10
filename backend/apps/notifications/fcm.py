import logging

logger = logging.getLogger(__name__)


def send_job_assignment_notification(user, job):
    logger.info(f"Notification: Job {job.job_id} assigned to {user.email}")
