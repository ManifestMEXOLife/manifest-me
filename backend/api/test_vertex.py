import os
import time
from google import genai
from google.genai import types

# FORCE KEY
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "/app/google_credentials.json"

client = genai.Client(
    vertexai=True,
    project="manifest-me-app",
    location="us-central1",
)

# 1. DEFINE OUTPUT LOCATION
# We use a specific folder so we can find it
bucket_name = "manifest-me-videos-nick"
output_folder = f"gs://{bucket_name}/testing/"

print(f"📂 Output Destination: {output_folder}")

# 2. DEFINE ASSET (Face)
person_image = types.VideoGenerationReferenceImage(
    image=types.Image(
        gcs_uri=f"gs://{bucket_name}/users/2/profile/avatar.jpg",
        mime_type="image/jpeg"
    ),
    reference_type="asset" 
)

print("🚀 Submitting Job...")

try:
    operation = client.models.generate_videos(
        model="veo-3.1-generate-preview",
        prompt="A cinematic video of the character from the reference image relaxing on a luxury tropical beach. Golden hour lighting, 4k.",
        config=types.GenerateVideosConfig(
            reference_images=[person_image],
            aspect_ratio="16:9",
            person_generation="allow_adult",
            output_gcs_uri=output_folder # <--- The video goes here
        )
    )
    print(f"🎟️ Job ID: {operation.name}")
except Exception as e:
    print(f"❌ Submission Failed: {e}")
    exit(1)

# 3. POLL
while not operation.done:
    print("   ...still cooking (approx 60s)...")
    time.sleep(10)
    operation = client.operations.get(operation=operation)

# 4. FIND THE FILE
# The API result might be empty, but the file exists!
if operation.result and operation.result.generated_videos:
    # If the API behaves nicely, it returns the path
    print(f"✅ API Says Video is at: {operation.result.generated_videos[0].video.uri}")
else:
    # If API returns None, we check the folder manually
    print(f"✅ Job Done! (API returned None, but checking bucket...)")
    print(f"   Go check this folder in Cloud Console: {output_folder}")
    
    # Optional: List the file to prove it exists
    from google.cloud import storage
    storage_client = storage.Client()
    blobs = list(storage_client.list_blobs(bucket_name, prefix="testing/"))
    if blobs:
        print(f"   🎉 FOUND IT! Latest file: gs://{bucket_name}/{blobs[-1].name}")
    else:
        print("   ❌ File not found in bucket. Something weird happened.")