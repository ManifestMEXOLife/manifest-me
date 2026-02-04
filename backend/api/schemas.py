from ninja import Schema
from datetime import datetime
from typing import Optional
from uuid import UUID

# What the iPhone sends TO us (just the prompt)
class VideoIn(Schema):
    prompt: str
    user_id: int

# What we send BACK to the iPhone (everything else)
class VideoOut(Schema):
    id: UUID
    user_id: int
    prompt: str
    status: str
    final_video_url: Optional[str] = None
    created_at: datetime

class UserCreate(Schema):
    username: str
    email: str
    password: str
    profile_picture_url: Optional[str] = None

class UserOut(Schema):
    id: int
    username: str
    email: str
    profile_picture_url: Optional[str] = None

class ProfilePictureUpdate(Schema):
    profile_picture_url: str