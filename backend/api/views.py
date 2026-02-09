from django.shortcuts import render

from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response
from google.cloud import storage
from .engine import generate_manifestation, upload_blob, BUCKET_NAME

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def manifest_video(request):
    prompt = request.data.get('prompt', '').lower()

    # get the user ID
    user_id = str(request.user.id)
    
    # Simple Logic to pick the folder based on keywords
    if 'beach' in prompt or 'ocean' in prompt or 'sea' in prompt:
        template = "beach_manifestation"
    elif 'work' in prompt or 'job' in prompt or 'abroad' in prompt:
        template = "work_abroad_manifestation"
    else:
        template = "wildlife_retreat_manifestation" # The default fallback

    print(f"🔮 Prompt: '{prompt}' -> Selected Template: '{template}'")

    try:
        # 2. PASS THE ID TO THE ENGINE
        video_url = generate_manifestation(prompt, template_name=template, user_id=user_id)
        
        return Response({
            "status": "success",
            "video_url": video_url,
            "template_used": template
        })
    except Exception as e:
        print(f"❌ ERROR: {e}")
        return Response({
            "status": "error",
            "message": str(e)
        }, status=500)
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def check_profile_status(request):
    """Checks if the user has an avatar uploaded."""
    user_id = str(request.user.id)
    
    # Check GCS for the file
    storage_client = storage.Client()
    bucket = storage_client.bucket(BUCKET_NAME)
    blob = bucket.blob(f"users/{user_id}/profile/avatar.jpg")
    
    return Response({
        "has_image": blob.exists()
    })

@api_view(['POST'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser]) # Allow file uploads
def upload_profile_image(request):
    """Uploads the user's face."""
    user_id = str(request.user.id)
    file_obj = request.FILES.get('file')
    
    if not file_obj:
        return Response({"error": "No file provided"}, status=400)
    
    # Save temporarily to upload
    temp_path = f"/tmp/{user_id}_avatar.jpg"
    with open(temp_path, 'wb+') as destination:
        for chunk in file_obj.chunks():
            destination.write(chunk)
            
    # Upload to Google Cloud
    # We use 'users/{id}/profile/avatar.jpg' as the standard path
    target_path = f"users/{user_id}/profile/avatar.jpg"
    public_url = upload_blob(BUCKET_NAME, temp_path, target_path)
    
    return Response({
        "status": "success", 
        "image_url": public_url
    })