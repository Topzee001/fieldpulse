from .models import User
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.throttling import ScopedRateThrottle
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from drf_spectacular.utils import extend_schema
from .serializers import (
    LoginSerializer, RefreshTokenSerializer, 
    BiometricLoginSerializer, BiometricToggleSerializer,
    UserSerializer
)
from rest_framework_simplejwt.tokens import RefreshToken


class LoginRateThrottle(ScopedRateThrottle):
    """Stricter rate limit for auth endpoints (5 requests/min)"""
    scope = 'login'


class CustomTokenObtainPairView(TokenObtainPairView):
    """
    Custom login endpoint that accepts email/password and returns JWT tokens.
    Implements:
    - Email/password authentication
    - Refresh token rotation ready (SimpleJWT handles it)
    - Device tracking
    """
    serializer_class = LoginSerializer
    throttle_classes = [LoginRateThrottle]

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        return Response({
            'access': serializer.validated_data['access'],
            'refresh': serializer.validated_data['refresh'],
            'user': UserSerializer(serializer.validated_data['user']).data,
        }, status=status.HTTP_200_OK)


class CustomTokenRefreshView(TokenRefreshView):
    """
    Custom refresh endpoint that returns new access token.
    SimpleJWT handles rotation automatically.
    """
    serializer_class = RefreshTokenSerializer

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        try:
            serializer.is_valid(raise_exception=True)
        except Exception as e:
            return Response({"refresh": ["Invalid or expired refresh token"]}, status=status.HTTP_400_BAD_REQUEST)
            
        return Response({
            'access': serializer.validated_data['access'],
            'refresh': serializer.validated_data['refresh'],
            'user': UserSerializer(serializer.validated_data['user']).data,
        }, status=status.HTTP_200_OK)


class BiometricLoginView(APIView):
    """Biometric login for returning users"""
    permission_classes = [AllowAny]
    serializer_class = BiometricLoginSerializer
    throttle_classes = [LoginRateThrottle]
    
    @extend_schema(request=BiometricLoginSerializer, responses={200: LoginSerializer})
    def post(self, request):
        serializer = BiometricLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        return Response({
            'refresh': serializer.validated_data['refresh'],
            'access': serializer.validated_data['access'],
            'user': UserSerializer(serializer.validated_data['user']).data
        }, status=status.HTTP_200_OK)


class BiometricToggleView(APIView):
    """Enable or disable biometric login"""
    permission_classes = [IsAuthenticated]
    serializer_class = BiometricToggleSerializer
    
    def post(self, request):
        serializer = BiometricToggleSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        
        request.user.biometric_enabled = serializer.validated_data['enable']
        request.user.save(update_fields=['biometric_enabled'])
        
        return Response({
            'biometric_enabled': request.user.biometric_enabled,
            'message': f'Biometric login {"enabled" if request.user.biometric_enabled else "disabled"}'
        }, status=status.HTTP_200_OK)


class LogoutView(APIView):
    """Logout by blacklisting the refresh token"""
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        try:
            refresh_token = request.data.get('refresh')
            if refresh_token:
                token = RefreshToken(refresh_token)
                token.blacklist()
            return Response({'message': 'Successfully logged out'}, status=status.HTTP_200_OK)
        except Exception:
            return Response({'message': 'Logged out'}, status=status.HTTP_200_OK)

class RegisterView(APIView):
    """Simple registration for demo purposes"""
    permission_classes = [AllowAny]
    throttle_classes = [LoginRateThrottle]
    
    def post(self, request):
        email = request.data.get('email')
        password = request.data.get('password')
        first_name = request.data.get('first_name', '')
        last_name = request.data.get('last_name', '')
        
        if not email or not password:
            return Response({'error': 'Email and password required'}, status=400)
        
        if User.objects.filter(email=email).exists():
            return Response({'error': 'User already exists'}, status=400)
        
        user = User.objects.create_user(
            email=email,
            password=password,
            first_name=first_name,
            last_name=last_name
        )
        
        refresh = RefreshToken.for_user(user)
        
        return Response({
            'user': {'id': user.id, 'email': user.email, 'first_name': user.first_name, 'last_name': user.last_name},
            'refresh': str(refresh),
            'access': str(refresh.access_token)
        }, status=201)



class ProfileView(APIView):
    """Get current user profile"""
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)
    
    def patch(self, request):
        user = request.user
        if 'first_name' in request.data:
            user.first_name = request.data['first_name']
        if 'last_name' in request.data:
            user.last_name = request.data['last_name']
        user.save(update_fields=['first_name', 'last_name'])
        
        return Response(UserSerializer(user).data)

class SessionCheckView(APIView):
    """
    Check if current session/token is still valid.
    Returns 200 if valid, 401 if expired.
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        return Response({
            'valid': True,
            'user': UserSerializer(request.user).data,
            'expires_in': 900  # 15 minutes(access token expiry time)
        })

class UpdateFCMTokenView(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request):
        token = request.data.get('fcm_token')
        if token:
            request.user.fcm_token = token
            request.user.save(update_fields=['fcm_token'])
            return Response({'status': 'updated'})
        return Response({'error': 'token required'}, status=400)
