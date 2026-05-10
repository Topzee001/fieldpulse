from django.urls import path
from .views import (
    CustomTokenObtainPairView, CustomTokenRefreshView,
    BiometricLoginView, BiometricToggleView, LogoutView, ProfileView, SessionCheckView,  
    RegisterView, UpdateFCMTokenView
)

urlpatterns = [
    # Add your URL patterns here
    path('login/', CustomTokenObtainPairView.as_view(), name='login'),
    path('register/', RegisterView.as_view(), name='register'),
    path('refresh/', CustomTokenRefreshView.as_view(), name='refresh'),
    path('logout/', LogoutView.as_view(), name='logout'),
    path('biometric/login/', BiometricLoginView.as_view(), name='biometric-login'),
    path('biometric/toggle/', BiometricToggleView.as_view(), name='biometric-toggle'),
    path('profile/', ProfileView.as_view(), name='profile'),
    path('check/', SessionCheckView.as_view(), name='session-check'),
    path('fcm-token/', UpdateFCMTokenView.as_view(), name='update-fcm-token'),
]
