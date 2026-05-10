"""
Run: python manage.py seed_jobs
"""

import random
from datetime import datetime, timedelta
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils import timezone
from jobs.models import Job

User = get_user_model()

class Command(BaseCommand):
    help = 'Generate 100+ realistic jobs for testing'
    
    # Sample data
    FIRST_NAMES = ['James', 'Mary', 'John', 'Patricia', 'Robert', 'Jennifer', 'Michael', 'Linda', 'William', 'Elizabeth']
    LAST_NAMES = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez']
    STREETS = ['Main St', 'Oak Ave', 'Pine Rd', 'Maple Dr', 'Cedar Ln', 'Elm Blvd', 'Washington St', 'Lake Shore Dr']
    CITIES = ['Springfield', 'Riverside', 'Lakewood', 'Greenville', 'Fairview', 'Salem', 'Georgetown', 'Clinton']
    
    JOB_TYPES = [
        'HVAC Repair', 'Plumbing Installation', 'Electrical Inspection', 
        'Appliance Repair', 'Pest Control', 'Lawn Maintenance',
        'Security System Setup', 'Internet Installation', 'Solar Panel Cleaning'
    ]
    
    CHECKLIST_SCHEMA = {
        "fields": [
            {"id": "work_performed", "type": "text_area", "label": "Work Performed", "required": True},
            {"id": "parts_used", "type": "text", "label": "Parts Used", "required": False},
            {"id": "customer_satisfied", "type": "checkbox", "label": "Customer Satisfied", "required": True},
            {"id": "before_photo", "type": "photo", "label": "Before Photo", "required": False},
            {"id": "after_photo", "type": "photo", "label": "After Photo", "required": False},
            {"id": "signature", "type": "signature", "label": "Customer Signature", "required": True}
        ]
    }
    
    def handle(self, *args, **options):
        # Get or create test technician
        tech, created = User.objects.get_or_create(
            email='tech@fieldpulse.com',
            defaults={
                'first_name': 'Test',
                'last_name': 'Technician',
                'is_active': True
            }
        )
        
        if created or not tech.has_usable_password():
            tech.set_password('Tech123!')
            tech.save()
        
        # Create 100+ jobs
        jobs_created = 0
        now = timezone.now()
        
        for i in range(120):
            # Random date within last 30 days to next 7 days
            days_offset = random.randint(-30, 7)
            scheduled_date = now + timedelta(days=days_offset)
            
            # Random time between 8 AM and 6 PM
            hour = random.randint(8, 18)
            minute = random.choice([0, 15, 30, 45])
            scheduled_start = scheduled_date.replace(hour=hour, minute=minute, second=0, microsecond=0)
            scheduled_end = scheduled_start + timedelta(hours=random.choice([1, 2, 3]))
            
            # Random status based on date
            if scheduled_start > now:
                job_status = Job.Status.PENDING
            elif random.random() < 0.6:
                job_status = Job.Status.COMPLETED
            elif random.random() < 0.5:
                job_status = Job.Status.IN_PROGRESS
            else:
                job_status = Job.Status.PENDING
            
            # Generate random customer
            first_name = random.choice(self.FIRST_NAMES)
            last_name = random.choice(self.LAST_NAMES)
            street_num = random.randint(100, 9999)
            street = random.choice(self.STREETS)
            city = random.choice(self.CITIES)
            
            Job.objects.create(
                job_id=f"JOB-{datetime.now().year}-{i+1:04d}",
                assigned_to=tech,
                customer_name=f"{first_name} {last_name}",
                customer_phone=f"({random.randint(200,999)}) {random.randint(200,999)}-{random.randint(1000,9999)}",
                customer_email=f"{first_name.lower()}.{last_name.lower()}@example.com",
                customer_address=f"{street_num} {street}, {city}, {random.choice(['NY', 'CA', 'TX', 'FL', 'IL'])} {random.randint(10000, 99999)}",
                latitude=round(40.7128 + random.uniform(-0.1, 0.1), 6),
                longitude=round(-74.0060 + random.uniform(-0.1, 0.1), 6),
                description=random.choice(self.JOB_TYPES),
                notes=f"Customer requests {random.choice(['morning', 'afternoon'])} appointment. Call before arriving.",
                scheduled_start=scheduled_start,
                scheduled_end=scheduled_end,
                status=job_status,
                checklist_schema=self.CHECKLIST_SCHEMA,
                version=1
            )
            jobs_created += 1
            
            if jobs_created % 20 == 0:
                self.stdout.write(f"Created {jobs_created} jobs...")
        
        self.stdout.write(self.style.SUCCESS(f"\n✅ Created {jobs_created} jobs for technician: {tech.email}"))
        self.stdout.write(f"\n📊 Job status breakdown:")
        self.stdout.write(f"   Pending: {Job.objects.filter(status='pending').count()}")
        self.stdout.write(f"   In Progress: {Job.objects.filter(status='in_progress').count()}")
        self.stdout.write(f"   Completed: {Job.objects.filter(status='completed').count()}")
