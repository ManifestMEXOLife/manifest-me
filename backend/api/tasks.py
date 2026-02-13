import os
import json
import logging
from google.cloud import tasks_v2

WORKER_URL = os.environ["WORKER_URL"]
WORKER_SECRET = os.environ["WORKER_SECRET"]

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
        url = WORKER_URL

        parent = client.queue_path(project, location, queue)

        payload = {
            "job_id": str(job_id),
            "template_name": template_name,
            "user_id": user_id
        }

        task_name = client.task_path(project, location, queue, f"video-{job_id}")

        task = {
            "name": task_name,
            "http_request": {
                "http_method": tasks_v2.HttpMethod.POST,
                "url": url,
                "headers": {
                    "Content-Type": "application/json",
                    "X-Worker-Secret": WORKER_SECRET,
                },
                "body": json.dumps(payload).encode("utf-8"),
            }
        }
        client.create_task(request={"parent": parent, "task": task})
        
    except Exception as e:
        print(f"❌ DEBUG ERROR in tasks.py: {str(e)}")
        # Re-raise the error so the View knows it failed
        raise e