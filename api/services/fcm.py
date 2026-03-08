from firebase_admin import messaging
from core import logger
from fastapi import HTTPException


async def send_fcm_notification(fcm_token: str, payload: dict):
  # Construct the FCM Data Message
  message = messaging.Message(
    data=payload, token=fcm_token, android=messaging.AndroidConfig(priority="high")
  )

  # Send the message via Firebase
  try:
    response = messaging.send(message)
    return response
  except Exception as e:
    logger.LOGGER.debug(f"FCM Send Error: {str(e)}")
    raise HTTPException(status_code=500, detail=f"FCM Send Error: {str(e)}")
