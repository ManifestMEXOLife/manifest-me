import json
import logging
from google.cloud import tasks_v2

# Set up a logger that Google Cloud can see easily
logger = logging.getLogger(__name__)

def enqueue_video_task(job_id, template_name, user_id):
    print(f"DEBUG STEP 1: Entering enqueue_video_task for job {job_id}")
    
    try:
        client = tasks_v2.CloudTasksClient()
        print("DEBUG STEP 2: CloudTasksClient initialized")

        project = "manifest-me-app"
        queue = "video-generation-queue"
        location = "us-central1"
        url = "https://manifest-me-api-79704250837.us-central1.run.app/api/worker/"

        parent = client.queue_path(project, location, queue)

        payload = {
            "job_id": str(job_id),
            "template_name": template_name,
            "user_id": user_id
        }

        task = {
            "http_request": {
                "http_method": tasks_v2.HttpMethod.POST,
                "url": url,
                "headers": {"Content-type": "application/json"},
                "body": json.dumps(payload).encode("utf-8"),
                "oidc_token": {
                    "service_account_email": "79704250837-compute@developer.gserviceaccount.com",
                },
            }
        }
        client.create_task(request={"parent": parent, "task": task})
        
    except Exception as e:
        print(f"❌ DEBUG ERROR in tasks.py: {str(e)}")
        # Re-raise the error so the View knows it failed
        raise e