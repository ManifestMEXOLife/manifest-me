from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from .views import manifest_video

print("🔥 DEBUG: URLs loading with Legacy Support...")

urlpatterns = [
    # --- AUTHENTICATION ---
    # 1. The "Standard" way (likely what your iPhone is using)
    path('token/pair/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    
    # 2. The "Clean" way (just in case)
    path('login/', TokenObtainPairView.as_view(), name='login'),
    
    # 3. Refresh token (standard)
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # --- FEATURES ---
    path('manifest/', manifest_video, name='manifest_video'),
]