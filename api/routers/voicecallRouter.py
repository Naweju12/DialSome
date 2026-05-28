from fastapi import APIRouter, Depends, status, WebSocket, WebSocketDisconnect
from fastapi.responses import JSONResponse
from models import User, Contact
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
  current_user = await User.get_or_none(id=user_id)
  if current_user is None:
    return JSONResponse(
      content={"status": False, "message": "Invalid Session"},
      status_code=status.HTTP_401_UNAUTHORIZED,
    )

  emails = [e.strip() for e in data.email.split(",") if e.strip()]
  if not emails:
    return JSONResponse(
      content={"status": False, "message": "No emails provided"},
      status_code=status.HTTP_400_BAD_REQUEST,
    )

  if len(emails) > 4:
    return JSONResponse(
      content={"status": False, "message": "Group call is limited to a maximum of 5 participants."},
      status_code=status.HTTP_400_BAD_REQUEST,
    )

  room_id = data.room_id if data.room_id else str(uuid.uuid7())
  invited_users = []
  
  for email in emails:
    target_user = await User.get_or_none(email=email)
    if target_user is None or target_user.fcm_token is None:
      continue

    is_permitted = await Contact.filter(
      owner_id=target_user.id, contact_user_id=current_user.id
    ).exists()

    if not is_permitted:
      continue

    payload = {
      "type": "incoming_call",
      "room_id": room_id,
      "caller_email": current_user.email,
      "caller_name": current_user.firstname,
      "is_group": "true" if len(emails) > 1 else "false",
      "participants": ",".join(emails + [current_user.email])
    }
    await fcm.send_fcm_notification(target_user.fcm_token, payload)
    invited_users.append(target_user.firstname)

  if not invited_users:
    return JSONResponse(
      content={"status": False, "message": "No valid contacts could be reached"},
      status_code=status.HTTP_404_NOT_FOUND,
    )

  room_name = ", ".join(invited_users)
  return JSONResponse(
    content={
      "status": True,
      "message": "Group call initialized",
      "data": {"room_id": room_id, "room_name": room_name},
    },
    status_code=status.HTTP_200_OK,
  )


@router.delete("/endcall")
async def end_call(
  data: voice.VoiceData, user_id: str = Depends(authenticate.verify_jwt)
):
  current_user = await User.get_or_none(id=user_id)
  if current_user is None:
    return JSONResponse(
      content={"status": False, "message": "Invalid Session"},
      status_code=status.HTTP_401_UNAUTHORIZED,
    )

  emails = [e.strip() for e in data.email.split(",") if e.strip()]
  for email in emails:
    target_user = await User.get_or_none(email=email)
    if target_user and target_user.fcm_token:
      payload = {
        "type": "end_call",
        "to": email,
        "caller_email": current_user.email,
        "caller_name": current_user.firstname,
      }
      await fcm.send_fcm_notification(target_user.fcm_token, payload)

  return JSONResponse(
    content={"status": True, "message": "Call ended successfully"},
    status_code=status.HTTP_200_OK,
  )
