from django.shortcuts import render

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
import time

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def manifest_video(request):
    # 1. Get the prompt from the iPhone
    prompt = request.data.get('prompt')
    print(f"MANIFEST REQUEST: {prompt}")

    # simulate thinking (AI Generation time)
    time.sleep(2)

    dummy_video = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"

    return Response({
        "status": "success",
        "prompt": prompt,
        "video_url": dummy_video
    })