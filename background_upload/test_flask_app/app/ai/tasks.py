import requests
from celery import Celery

celery = Celery(__name__, broker="redis://localhost:6379/0")


@celery.task
def analyze_media(file_path):
    # Mock analysis and send result to analyze endpoint
    analyze_url = "http://localhost:8000/ai/analyze"
    requests.post(analyze_url, json={"file_path": file_path})
