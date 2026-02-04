from ninja import NinjaAPI
from typing import List
from .models import Video
from .schemas import VideoIn, VideoOut

api = NinjaAPI()

# 1. Create a Video (POST)
@api.post("/videos", response=VideoOut)
def create_video(request, data: VideoIn):
    # This saves a new row in your Postgres database
    video = Video.objects.create(prompt=data.prompt)
    return video

# 2. List all Videos (GET)
@api.get("/videos", response=List[VideoOut])
def list_videos(request):
    return Video.objects.all()

# 3. Check Status of one Video (GET)
@api.get("/videos/{video_id}", response=VideoOut)
def get_video(request, video_id: int):
    return Video.objects.get(id=video_id)