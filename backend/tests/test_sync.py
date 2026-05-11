"""
Integration tests for Checklist flow.
Covers: Save Draft, Retrieve, Submit Final
"""

from datetime import timedelta
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from authentication.models import User
from jobs.models import Job


class ChecklistFlowTest(TestCase):
    """Integration test: Save Checklist Draft, Retrieve, Submit Final"""

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email='tech@test.com',
            password='TestPass123!',
            first_name='Test',
            last_name='Tech',
        )
        login = self.client.post('/api/auth/login/', {
            'email': 'tech@test.com',
            'password': 'TestPass123!',
        }, format='json')
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")

        self.job = Job.objects.create(
            job_id='JOB-CHECK-0001',
            assigned_to=self.user,
            customer_name='Draft Test',
            customer_address='500 Check St',
            latitude=40.7128,
            longitude=-74.006,
            scheduled_start=timezone.now() + timedelta(hours=1),
            scheduled_end=timezone.now() + timedelta(hours=3),
            status=Job.Status.IN_PROGRESS,
            actual_start=timezone.now(),
            checklist_schema={
                'fields': [
                    {'id': 'work_performed', 'type': 'text_area', 'label': 'Work Performed', 'required': True},
                    {'id': 'parts_used', 'type': 'text', 'label': 'Parts Used', 'required': False},
                    {'id': 'customer_satisfied', 'type': 'checkbox', 'label': 'Customer Satisfied', 'required': True},
                ]
            },
            version=1,
        )

    def test_save_checklist_draft(self):
        response = self.client.patch(
            f'/api/jobs/{self.job.id}/checklist/',
            {
                'data': {'work_performed': 'Started fixing the AC'},
                'is_draft': True,
            },
            format='json',
        )
        self.assertEqual(response.status_code, 200)

    def test_get_checklist_response(self):
        # Save a draft first
        self.client.patch(
            f'/api/jobs/{self.job.id}/checklist/',
            {
                'data': {'work_performed': 'Fixed the AC', 'customer_satisfied': True},
                'is_draft': True,
            },
            format='json',
        )

        # Retrieve it
        response = self.client.get(f'/api/jobs/{self.job.id}/checklist/')
        self.assertEqual(response.status_code, 200)
        self.assertIn('data', response.data)
        self.assertEqual(response.data['data']['work_performed'], 'Fixed the AC')
        self.assertEqual(response.data['is_draft'], True)

    def test_submit_final_checklist(self):
        response = self.client.patch(
            f'/api/jobs/{self.job.id}/checklist/',
            {
                'data': {
                    'work_performed': 'Replaced compressor',
                    'parts_used': 'Compressor unit #45',
                    'customer_satisfied': True,
                },
                'is_draft': False,
            },
            format='json',
        )
        self.assertEqual(response.status_code, 200)

        # Verify it's no longer a draft
        get_response = self.client.get(f'/api/jobs/{self.job.id}/checklist/')
        self.assertEqual(get_response.data['is_draft'], False)

    def test_checklist_update_preserves_existing_data(self):
        # Save first field
        self.client.patch(
            f'/api/jobs/{self.job.id}/checklist/',
            {'data': {'work_performed': 'Step 1 done'}, 'is_draft': True},
            format='json',
        )

        # Save second field (should merge with existing)
        self.client.patch(
            f'/api/jobs/{self.job.id}/checklist/',
            {'data': {'parts_used': 'Part A'}, 'is_draft': True},
            format='json',
        )

        get_response = self.client.get(f'/api/jobs/{self.job.id}/checklist/')
        data = get_response.data['data']
        self.assertIn('work_performed', data)
        self.assertIn('parts_used', data)