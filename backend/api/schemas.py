from ninja import Schema
from datetime import datetime
from typing import Optional

# What the iPhone sends TO us (just the prompt)
class VideoIn(Schema):
    prompt: str

# What we send BACK to the iPhone (everything else)
class VideoOut(Schema):
    id: int
    prompt: str
    status: str
    final_video_url: Optional[str] = None
    created_at: datetime