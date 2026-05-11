from django.contrib.auth.models import AbstractUser, UserManager as BaseUserManager
from django.db import models
from django.utils.translation import gettext_lazy as _


class UserManager(BaseUserManager):
    def create_superuser(self, email=None, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(email, password, **extra_fields)

    def create_user(self, email=None, password=None, **extra_fields):
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user


class User(AbstractUser):
    """
    Extended user model for field technicians.
    Uses EMAIL as the unique identifier instead of username.
    """
    
    username = None
    
    email = models.EmailField(_('email address'), unique=True)
    
    first_name = models.CharField(_('first name'), max_length=150)
    last_name = models.CharField(_('last name'), max_length=150)

    objects = UserManager()
    
    device_id = models.CharField(
        max_length=255, 
        blank=True, 
        null=True,
        help_text="Unique device identifier for targeting push notifications"
    )
    
    fcm_token = models.CharField(
        max_length=255, 
        blank=True, 
        null=True,
        help_text="Firebase Cloud Messaging token for this device"
    )
    
    biometric_enabled = models.BooleanField(
        default=False,
        help_text="User can use Face ID / Fingerprint to login"
    )
    
    last_active = models.DateTimeField(auto_now=True)
    
    is_active = models.BooleanField(default=True)
    
    USERNAME_FIELD = 'email'

    USERNAME_FIELD = 'email'

    REQUIRED_FIELDS = ['first_name', 'last_name']

    REQUIRED_FIELDS = ['first_name', 'last_name']

    
    class Meta:
        db_table = 'users'

        db_table = 'users'

        verbose_name = _('User')
        verbose_name_plural = _('Users')
        indexes = [
            models.Index(fields=['email']),
            models.Index(fields=['device_id']),
            models.Index(fields=['last_active']),
        ]

    def __str__(self):
        return f"{self.get_full_name} ({self.email})"
    
    @property
    def get_full_name(self):
        """Return the full name of the user."""
        return f"{self.first_name} {self.last_name}".strip() or self.email

