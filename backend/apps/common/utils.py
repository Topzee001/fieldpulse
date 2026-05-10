import re
from datetime import datetime

def validate_phone(phone):
    """Simple phone validation (strip non-digits, check length)"""
    digits = re.sub(r'\D', '', phone)
    return len(digits) >= 10

def format_timestamp(dt: datetime) -> str:
    """ISO format with timezone"""
    return dt.isoformat() if dt else None

def generate_job_id():
    """Generate human-readable job ID"""
    return f"JOB-{datetime.now().strftime('%Y%m%d')}-{datetime.now().microsecond % 10000:04d}"