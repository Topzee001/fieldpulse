from rest_framework import serializers
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken
from django.utils import timezone

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    """User serializer for profile responses"""
    full_name = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ['id', 'email', 'first_name', 'last_name', 'full_name', 
                  'biometric_enabled', 'device_id', 'last_active']
        read_only_fields = ['id', 'last_active']
    
    def get_full_name(self, obj):
        return obj.get_full_name


class LoginSerializer(serializers.Serializer):
    """Serializer for email/password login"""
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)
    device_id = serializers.CharField(required=False, allow_blank=True)
    fcm_token = serializers.CharField(required=False, allow_blank=True)
    
    def validate(self, attrs):
        email = attrs.get('email')
        password = attrs.get('password')
        
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            raise serializers.ValidationError({'email': 'Invalid email or password'})
        
        if not user.check_password(password):
            raise serializers.ValidationError({'email': 'Invalid email or password'})
        
        if not user.is_active:
            raise serializers.ValidationError({'email': 'Account is disabled'})
        
        # Update device info
        if attrs.get('device_id'):
            user.device_id = attrs['device_id']
        if attrs.get('fcm_token'):
            user.fcm_token = attrs['fcm_token']
        
        user.last_active = timezone.now()
        user.save(update_fields=['device_id', 'fcm_token', 'last_active'])
        
        # Generate tokens
        refresh = RefreshToken.for_user(user)
        
        attrs['user'] = user
        attrs['refresh'] = str(refresh)
        attrs['access'] = str(refresh.access_token)
        
        return attrs


class RefreshTokenSerializer(serializers.Serializer):
    """Serializer for refresh token rotation"""
    refresh = serializers.CharField()
    
    def validate(self, attrs):
        try:
            refresh = RefreshToken(attrs['refresh'])
            user = User.objects.get(id=refresh.payload['user_id'])
            
            attrs['user'] = user
            attrs['access'] = str(refresh.access_token)
            
            # Rotate refresh token (SimpleJWT does this automatically when ROTATE_REFRESH_TOKENS=True)
            # We just need to return the new refresh if needed
            if hasattr(refresh, 'blacklist'):
                refresh.blacklist()
                new_refresh = RefreshToken.for_user(user)
                attrs['refresh'] = str(new_refresh)
            
            return attrs
        except Exception as e:
            raise serializers.ValidationError({'refresh': 'Invalid or expired refresh token'})


class BiometricLoginSerializer(serializers.Serializer):
    """Serializer for biometric login"""
    email = serializers.EmailField()
    biometric_enabled = serializers.BooleanField()
    device_id = serializers.CharField()
    
    def validate(self, attrs):
        email = attrs.get('email')
        device_id = attrs.get('device_id')
        
        try:
            user = User.objects.get(email=email, device_id=device_id)
        except User.DoesNotExist:
            raise serializers.ValidationError({'email': 'Device not recognized or user not found'})
        
        if not user.biometric_enabled:
            raise serializers.ValidationError({'biometric_enabled': 'Biometric login not enabled for this user'})
        
        if not user.is_active:
            raise serializers.ValidationError({'email': 'Account is disabled'})
        
        user.last_active = timezone.now()
        user.save(update_fields=['last_active'])
        
        refresh = RefreshToken.for_user(user)
        
        attrs['user'] = user
        attrs['refresh'] = str(refresh)
        attrs['access'] = str(refresh.access_token)
        
        return attrs


class BiometricToggleSerializer(serializers.Serializer):
    """Serializer for enabling/disabling biometric login"""
    enable = serializers.BooleanField()
    password = serializers.CharField(write_only=True)
    
    def validate(self, attrs):
        user = self.context['request'].user
        
        if not user.check_password(attrs['password']):
            raise serializers.ValidationError({'password': 'Invalid password'})
        
        return attrs