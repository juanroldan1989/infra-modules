import json
import os
import urllib3 # type: ignore

http = urllib3.PoolManager()

SLACK_WEBHOOK_URL = os.getenv("SLACK_WEBHOOK_URL")

def lambda_handler(event, context):
  if not SLACK_WEBHOOK_URL:
    return {
      "statusCode": 500,
      "body": "Error: SLACK_WEBHOOK_URL environment variable not set"
    }

  message = {
    "text": f"⚠️ ECS Service Health Check Failed: {event['Records'][0]['Sns']['Subject']}\n{event['Records'][0]['Sns']['Message']}"
  }

  response = http.request(
    "POST",
    SLACK_WEBHOOK_URL,
    body=json.dumps(message),
    headers={"Content-Type": "application/json"}
  )

  return {
    "statusCode": response.status,
    "body": response.data.decode("utf-8")
  }
