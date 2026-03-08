from fastapi import APIRouter, Depends, status, WebSocket, WebSocketDisconnect
from fastapi.responses import JSONResponse
from models.user import User
import uuid_utils as uuid
from models import voice
from middlewares import authenticate
import asyncio
from services import fcm


router = APIRouter(prefix="/voicecall", tags=["Voicecall"])
socket = APIRouter(prefix="/ws", tags=["Websocket"])
rooms: dict[str, list[WebSocket]] = {}


@socket.websocket("/{room_id}")
async def websocket_endpoint(websocket: WebSocket, room_id: str):
  await websocket.accept()
  if room_id not in rooms:
    rooms[room_id] = []
  rooms[room_id].append(websocket)

  try:
    while True:
      data = await websocket.receive_text()
      for client in rooms[room_id]:
        if client != websocket:
          await client.send_text(data)
  except WebSocketDisconnect:
    rooms[room_id].remove(websocket)


@router.post("/send")
async def call_person(
  data: voice.VoiceData, user_id: str = Depends(authenticate.verify_jwt)
):
  current_user, target_user = await asyncio.gather(
    User.get_or_none(id=user_id), User.get_or_none(email=data.email)
  )

  if current_user is None:
    return JSONResponse(
      content={"status": False, "message": "Invalid Session"},
      status_code=status.HTTP_401_UNAUTHORIZED,
    )

  if target_user is None or target_user.fcm_token is None:
    return JSONResponse(
      content={"status": False, "message": "User not found"},
      status_code=status.HTTP_404_NOT_FOUND,
    )

  room_id = str(uuid.uuid7())
  payload = {
    "type": "incoming_call",
    "room_id": room_id,
    "caller_email": current_user.email,
  }
  await fcm.send_fcm_notification(target_user.fcm_token, payload)
  return JSONResponse(
    content={
      "status": True,
      "message": "Offer sent successfully",
      "data": {"room_id": room_id},
    },
    status_code=status.HTTP_200_OK,
  )


@router.delete("/endcall")
async def end_call(
  data: voice.VoiceData, user_id: str = Depends(authenticate.verify_jwt)
):
  current_user, target_user = await asyncio.gather(
    User.get_or_none(id=user_id), User.get_or_none(email=data.email)
  )

  if current_user is None:
    return JSONResponse(
      content={"status": False, "message": "Invalid Session"},
      status_code=status.HTTP_401_UNAUTHORIZED,
    )

  if target_user is None or target_user.fcm_token is None:
    return JSONResponse(
      content={"status": False, "message": "User not found"},
      status_code=status.HTTP_404_NOT_FOUND,
    )

  payload = {"type": "end_call", "to": data.email}
  await fcm.send_fcm_notification(target_user.fcm_token, payload)
  return JSONResponse(
    content={"status": True, "message": "Call ended successfully"},
    status_code=status.HTTP_200_OK,
  )
