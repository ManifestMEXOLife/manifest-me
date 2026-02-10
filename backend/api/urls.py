from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from .views import manifest_video, check_profile_status, upload_profile_image, register_user, get_user_videos

print("🔥 DEBUG: URLs loading with Legacy Support...")

urlpatterns = [
    # --- AUTHENTICATION ---
    # 1. The "Standard" way (likely what your iPhone is using)
    path('token/pair/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    
    # 2. The "Clean" way (just in case)
    path('register/', register_user, name='register'),
    path('login/', TokenObtainPairView.as_view(), name='login'),
    
    # 3. Refresh token (standard)
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # --- FEATURES ---
    path('manifest/', manifest_video, name='manifest_video'),
    path('profile/status/', check_profile_status, name='profile_status'),
    path('profile/upload/', upload_profile_image, name='profile_upload'),

    path('videos/', get_user_videos, name='get_videos'),
]