"""
Integration tests for Authentication flow.
Covers: Login, Token Refresh, Token Validation
"""

from django.test import TestCase
from rest_framework.test import APIClient
from authentication.models import User


class AuthenticationFlowTest(TestCase):
    """Integration test: Login, Token Refresh, Token Validation"""

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            email='tech@test.com',
            password='TestPass123!',
            first_name='Test',
            last_name='Tech',
        )

    def test_login_returns_tokens_and_user(self):
        response = self.client.post('/api/auth/login/', {
            'email': 'tech@test.com',
            'password': 'TestPass123!',
        }, format='json')

        self.assertEqual(response.status_code, 200)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)
        self.assertIn('user', response.data)
        self.assertEqual(response.data['user']['email'], 'tech@test.com')

    def test_login_rejects_wrong_password(self):
        response = self.client.post('/api/auth/login/', {
            'email': 'tech@test.com',
            'password': 'wrong',
        }, format='json')

        self.assertIn(response.status_code, [400, 401])

    def test_login_rejects_nonexistent_user(self):
        response = self.client.post('/api/auth/login/', {
            'email': 'nobody@test.com',
            'password': 'TestPass123!',
        }, format='json')

        self.assertIn(response.status_code, [400, 401])

    def test_token_refresh_flow(self):
        # Login first
        login_response = self.client.post('/api/auth/login/', {
            'email': 'tech@test.com',
            'password': 'TestPass123!',
        }, format='json')
        refresh_token = login_response.data['refresh']

        # Refresh to get new access token
        refresh_response = self.client.post('/api/auth/refresh/', {
            'refresh': refresh_token,
        }, format='json')

        self.assertEqual(refresh_response.status_code, 200)
        self.assertIn('access', refresh_response.data)

    def test_protected_endpoint_rejects_unauthenticated(self):
        response = self.client.get('/api/jobs/')
        self.assertEqual(response.status_code, 401)

    def test_protected_endpoint_accepts_valid_token(self):
        login_response = self.client.post('/api/auth/login/', {
            'email': 'tech@test.com',
            'password': 'TestPass123!',
        }, format='json')
        token = login_response.data['access']

        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        response = self.client.get('/api/jobs/')
        self.assertEqual(response.status_code, 200)