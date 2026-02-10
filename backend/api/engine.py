import os
import time
import uuid  # <--- NEW: For unique folder names
from google import genai
from google.genai import types
from google.cloud import storage
from moviepy.editor import VideoFileClip, concatenate_videoclips

# --- 1. FORCE AUTHENTICATION ---
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "/app/google_credentials.json"

# --- 2. CONFIGURATION ---
PROJECT_ID = "manifest-me-app"
LOCATION = "us-central1"
BUCKET_NAME = "manifest-me-videos-nick"

# --- 3. INITIALIZE CLIENTS ---
client = genai.Client(
    vertexai=True,
    project=PROJECT_ID,
    location=LOCATION
)
storage_client = storage.Client()

# --- MONKEYPATCH ---
import PIL.Image
if not hasattr(PIL.Image, 'ANTIALIAS'):
    PIL.Image.ANTIALIAS = PIL.Image.LANCZOS

def download_blob(bucket_name, source_blob_name, destination_file_name):
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(source_blob_name)
    if not blob.exists():
        print(f"⚠️ Warning: {source_blob_name} not found.")
        return False
    blob.download_to_filename(destination_file_name)
    return True

def upload_blob(bucket_name, source_file_name, destination_blob_name):
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)
    blob.upload_from_filename(source_file_name)
    return blob.generate_signed_url(version="v4", expiration=604800, method="GET")

def generate_veo_video(local_avatar_path, prompt, output_local_path):
    print(f"🧠 Calling Vertex AI with prompt: '{prompt}'...")
    
    # 1. Load Avatar
    if not os.path.exists(local_avatar_path):
        raise FileNotFoundError(f"Avatar not found at {local_avatar_path}")
    with open(local_avatar_path, "rb") as f:
        image_bytes = f.read()

    # 2. Configure Asset
    person_image = types.VideoGenerationReferenceImage(
        image=types.Image(image_bytes=image_bytes, mime_type="image/jpeg"),
        reference_type="asset" 
    )

    # 3. SETUP MAILBOX (Unique Output Folder)
    # We create a unique folder for this specific run
    run_id = str(uuid.uuid4())
    output_gcs_folder = f"gs://{BUCKET_NAME}/generated/{run_id}/"
    print(f"📂 Target Mailbox: {output_gcs_folder}")

    # 4. SUBMIT JOB
    print("🚀 Submitting Job...")
    try:
        operation = client.models.generate_videos(
            model="veo-3.1-generate-preview",
            prompt=prompt,
            config=types.GenerateVideosConfig(
                reference_images=[person_image],
                aspect_ratio="16:9",
                person_generation="allow_adult",
                output_gcs_uri=output_gcs_folder  # <--- FORCE OUTPUT HERE
            )
        )
        print(f"🎟️ Job ID: {operation.name}")
    except Exception as e:
        print(f"❌ Submission Failed: {e}")
        raise e

    # 5. POLL
    while not operation.done:
        print("   ...generating (approx 60s)...")
        time.sleep(10)
        operation = client.operations.get(operation=operation)

    # 6. RETRIEVE FROM MAILBOX
    # We ignore the API response and look directly in the folder we created.
    print(f"📦 Checking mailbox: generated/{run_id}/")
    blobs = list(storage_client.list_blobs(BUCKET_NAME, prefix=f"generated/{run_id}/"))
    
    if not blobs:
        raise Exception("Video generated but NOT found in bucket. Model output failed.")
        
    # Grab the first file in that folder (there should only be one)
    video_blob = blobs[0]
    print(f"✅ Found Video: {video_blob.name}")
    
    video_blob.download_to_filename(output_local_path)
    print(f"💾 Saved to {output_local_path}")

def generate_manifestation(user_prompt, template_name="beach_manifestation", user_id="guest"):
    
    base_dir = "/tmp"
    intro_path = f"{base_dir}/intro.mp4"
    outro_path = f"{base_dir}/outro.mp4"
    avatar_path = f"{base_dir}/avatar.jpg"
    ai_clip_path = f"{base_dir}/generated.mp4"
    final_output_path = f"{base_dir}/final.mp4"
    
    print(f"🎬 Starting Manifestation for User {user_id}...")

    # 1. DOWNLOAD ASSETS
    try:
        download_blob(BUCKET_NAME, f"{template_name}/intro.mp4", intro_path)
        download_blob(BUCKET_NAME, f"{template_name}/outro.mp4", outro_path)
        download_blob(BUCKET_NAME, f"users/{user_id}/profile/avatar.jpg", avatar_path)
    except Exception as e:
        print(f"❌ Asset Download Error: {e}")
        raise e

    # 2. PROMPT
    base_prompt = ""
    if template_name == "beach_manifestation":
        base_prompt = "Cinematic video of the character from the reference image relaxing on a luxury tropical beach. Smiling, linen clothes. Golden hour lighting, 4k."
    elif template_name == "work_abroad_manifestation":
        # Added: "Wearing a stylish blazer and business attire" to force the look
        base_prompt = "Cinematic video of the character from the reference image walking through an old European city. Wearing business attire. Cobblestone streets. Vintage style, warm lighting, 4k."
    else: 
        # Added: "Wearing technical hiking gear" to force the look
        base_prompt = "Cinematic video of the character from the reference image hiking in a green forest. Wearing technical hiking gear and a backpack. Nature atmosphere, 4k."
        
    final_prompt = f"{base_prompt} Action: {user_prompt}"

    # 3. GENERATE
    try:
        generate_veo_video(avatar_path, final_prompt, ai_clip_path)
    except Exception as e:
        print(f"❌ AI Generation Failed: {e}")
        print("⚠️ Falling back to intro clip...")
        download_blob(BUCKET_NAME, f"{template_name}/intro.mp4", ai_clip_path)

    # 4. STITCH
    print("✂️ Stitching...")
    try:
        clip_intro = VideoFileClip(intro_path)
        clip_outro = VideoFileClip(outro_path)
        clip_ai = VideoFileClip(ai_clip_path)
        
        if clip_ai.duration < 6:
             clip_ai = clip_ai.loop(duration=6)
        else:
             clip_ai = clip_ai.subclip(0, 6)
            
        clip_ai = clip_ai.resize(newsize=clip_intro.size)
        
        final = concatenate_videoclips([clip_intro, clip_ai, clip_outro], method="compose")
        final.write_videofile(final_output_path, codec="libx264", audio_codec="aac", fps=24)
        
    except Exception as e:
        print(f"❌ Stitching Error: {e}")
        raise e

    # 5. UPLOAD
    timestamp = int(time.time())
    output_key = f"users/{user_id}/videos/manifest_{timestamp}.mp4"
    return upload_blob(BUCKET_NAME, final_output_path, output_key)