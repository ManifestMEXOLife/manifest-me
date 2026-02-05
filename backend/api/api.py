from ninja import NinjaAPI
from typing import List

from django.contrib.auth.models import User

from ninja_extra import NinjaExtraAPI
from ninja_jwt.controller import NinjaJWTDefaultController

from .models import Video, Profile
from .schemas import VideoIn, VideoOut, UserCreate, UserOut, ProfilePictureUpdate

api = NinjaExtraAPI()

# this auto adds the "Login" and "Refresh" endpoints
api.register_controllers(NinjaJWTDefaultController)

# 1. Create a Video (POST)
@api.post("/videos", response=VideoOut)
def create_video(request, data: VideoIn):
    # 1. Find the User first (to make sure they exist)
    user = User.objects.get(id=data.user_id)
    
    # 2. Create the Video and LINK it to that user
    video = Video.objects.create(
        prompt=data.prompt,
        user=user  # <--- This is the magic link
    )
    
    return video

# 2. List all Videos (GET)
@api.get("/videos", response=List[VideoOut])
def list_videos(request):
    return Video.objects.all()

# 3. Check Status of one Video (GET)
@api.get("/videos/{video_id}", response=VideoOut)
def get_video(request, video_id: int):
    return Video.objects.get(id=video_id)

@api.post("/register", response=UserOut)
def register(request, data: UserCreate):
    # 1. create_user handles password hashing automatically!
    user = User.objects.create_user(
        username=data.username,
        email=data.email,
        password=data.password
    )
    # 2. Create the Sidecar (Profile)
    # We use the URL provided, or None if they didn't send one
    Profile.objects.create(user=user, profile_picture_url=data.profile_picture_url)

    # 3. Construct the response manually
    return UserOut(
        id=user.id,
        username=user.username,
        email=user.email,
        profile_picture_url=data.profile_picture_url
    )

@api.put("/users/{user_id}/profile-picture", response=UserOut)
def update_profile_picture(request, user_id: int, data: ProfilePictureUpdate):
    # 1. Find the User
    user = User.objects.get(id=user_id)
    
    # 2. Get the Profile (or create it if it's missing)
    profile, created = Profile.objects.get_or_create(user=user)
    
    # 3. Update the link
    profile.profile_picture_url = data.profile_picture_url
    profile.save()
    
    # 4. Return the full user object (with the new picture)
    return UserOut(
        id=user.id,
        username=user.username,
        email=user.email,
        profile_picture_url=profile.profile_picture_url
    )