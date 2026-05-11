"""
Integration tests for Job management flow.
Covers: List Jobs, Get Detail, Update Status
"""

from datetime import timedelta
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from authentication.models import User
from jobs.models import Job


class JobListAndStatusFlowTest(TestCase):
    """Integration test: List Jobs, Get Detail, Update Status"""

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email='tech@test.com',
            password='TestPass123!',
            first_name='Test',
            last_name='Tech',
        )
        # Login and set auth
        login = self.client.post('/api/auth/login/', {
            'email': 'tech@test.com',
            'password': 'TestPass123!',
        }, format='json')
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")

        # Create test jobs
        now = timezone.now()
        self.job1 = Job.objects.create(
            job_id='JOB-TEST-0001',
            assigned_to=self.user,
            customer_name='Alice Johnson',
            customer_phone='(555) 111-2222',
            customer_email='alice@test.com',
            customer_address='100 Test St, TestCity, NY 10001',
            latitude=40.7128,
            longitude=-74.006,
            description='HVAC Repair',
            notes='Call before arriving',
            scheduled_start=now + timedelta(hours=1),
            scheduled_end=now + timedelta(hours=3),
            status=Job.Status.PENDING,
            checklist_schema={
                'fields': [
                    {'id': 'work', 'type': 'text_area', 'label': 'Work Performed', 'required': True},
                    {'id': 'satisfied', 'type': 'checkbox', 'label': 'Customer Satisfied', 'required': True},
                ]
            },
            version=1,
        )
        self.job2 = Job.objects.create(
            job_id='JOB-TEST-0002',
            assigned_to=self.user,
            customer_name='Bob Smith',
            customer_phone='(555) 333-4444',
            customer_address='200 Test Ave, TestCity, NY 10002',
            latitude=40.7128,
            longitude=-74.006,
            scheduled_start=now - timedelta(hours=2),
            scheduled_end=now - timedelta(hours=1),
            status=Job.Status.COMPLETED,
            version=1,
        )

    def test_list_jobs_returns_assigned_jobs(self):
        response = self.client.get('/api/jobs/')
        self.assertEqual(response.status_code, 200)
        self.assertIn('results', response.data)
        job_ids = [j['job_id'] for j in response.data['results']]
        self.assertIn('JOB-TEST-0001', job_ids)
        self.assertIn('JOB-TEST-0002', job_ids)

    def test_list_jobs_does_not_return_other_users_jobs(self):
        other_user = User.objects.create_user(
            email='other@test.com', password='OtherPass123!',
        )
        Job.objects.create(
            job_id='JOB-OTHER-0001',
            assigned_to=other_user,
            customer_name='Charlie',
            customer_address='300 Other St',
            latitude=40.7128,
            longitude=-74.006,
            scheduled_start=timezone.now(),
            scheduled_end=timezone.now() + timedelta(hours=1),
            status=Job.Status.PENDING,
            version=1,
        )
        response = self.client.get('/api/jobs/')
        job_ids = [j['job_id'] for j in response.data['results']]
        self.assertNotIn('JOB-OTHER-0001', job_ids)

    def test_get_job_detail(self):
        response = self.client.get(f'/api/jobs/{self.job1.id}/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['job_id'], 'JOB-TEST-0001')
        self.assertEqual(response.data['customer_name'], 'Alice Johnson')
        self.assertIn('checklist_schema', response.data)

    def test_status_update_pending_to_in_progress(self):
        response = self.client.patch(
            f'/api/jobs/{self.job1.id}/status/',
            {'status': 'in_progress'},
            format='json',
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['old_status'], 'pending')
        self.assertEqual(response.data['new_status'], 'in_progress')

        # Verify the job was actually updated
        self.job1.refresh_from_db()
        self.assertEqual(self.job1.status, Job.Status.IN_PROGRESS)
        self.assertIsNotNone(self.job1.actual_start)

    def test_status_update_in_progress_to_completed(self):
        self.job1.status = Job.Status.IN_PROGRESS
        self.job1.actual_start = timezone.now()
        self.job1.save()

        response = self.client.patch(
            f'/api/jobs/{self.job1.id}/status/',
            {'status': 'completed'},
            format='json',
        )
        self.assertEqual(response.status_code, 200)
        self.job1.refresh_from_db()
        self.assertEqual(self.job1.status, Job.Status.COMPLETED)
        self.assertIsNotNone(self.job1.actual_completion)

    def test_invalid_status_transition_rejected(self):
        # Pending -> Completed is not allowed (must go through in_progress)
        response = self.client.patch(
            f'/api/jobs/{self.job1.id}/status/',
            {'status': 'completed'},
            format='json',
        )
        self.assertEqual(response.status_code, 400)

    def test_idempotent_status_update(self):
        # Set to in_progress first
        self.client.patch(
            f'/api/jobs/{self.job1.id}/status/',
            {'status': 'in_progress'},
            format='json',
        )
        # Try to set to in_progress again (should be idempotent)
        response = self.client.patch(
            f'/api/jobs/{self.job1.id}/status/',
            {'status': 'in_progress'},
            format='json',
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['status'], 'no_change')

    def test_status_update_increments_version(self):
        old_version = self.job1.version
        self.client.patch(
            f'/api/jobs/{self.job1.id}/status/',
            {'status': 'in_progress'},
            format='json',
        )
        self.job1.refresh_from_db()
        self.assertEqual(self.job1.version, old_version + 1)

    def test_filter_jobs_by_status(self):
        response = self.client.get('/api/jobs/', {'status': 'pending'})
        self.assertEqual(response.status_code, 200)
        for job in response.data['results']:
            self.assertEqual(job['status'], 'pending')

    def test_search_jobs_by_customer_name(self):
        response = self.client.get('/api/jobs/', {'search': 'Alice'})
        self.assertEqual(response.status_code, 200)
        results = response.data['results']
        self.assertTrue(len(results) >= 1)
        self.assertTrue(any(j['customer_name'] == 'Alice Johnson' for j in results))