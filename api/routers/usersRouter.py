from fastapi import APIRouter, status, Depends
from fastapi.responses import JSONResponse
from models import User, Contact, fcm, contacts
from core import logger
from services import users
from typing import Mapping, Any
from middlewares import authenticate, google
import asyncio


router = APIRouter(prefix="/users", tags=["Users"])


@router.post("/login")
async def login_user(
  payload: Mapping[str, Any] = Depends(google.get_current_user_email),
):
  if "email" not in payload:
    logger.LOGGER.error("Login Payload doesn't contains any Email ID")
    return JSONResponse(
      content={"status": False, "message": "The Payload doesn't contains any email ID"},
      status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
    )

  result = await users.login(payload["email"].lower())

  if result is None:
    return JSONResponse(
      content={"status": False, "message": "User doesn't exist"},
      status_code=status.HTTP_404_NOT_FOUND,
    )

  user_data, jwt_data = result[0], result[1]

  logger.LOGGER.debug(f"Login Successful: {user_data.email}")
  return JSONResponse(
    content={
      "status": True,
      "message": "Login Successful",
      "data": {
        "id": str(user_data.id),
        "email": user_data.email,
        "firstname": user_data.firstname,
        "lastname": user_data.lastname,
        "jwt": jwt_data.to_dict(),
      },
    },
    status_code=status.HTTP_200_OK,
  )


@router.post("/register")
async def register_user(
  payload: Mapping[str, Any] = Depends(google.get_current_user_email),
):
  if "email" not in payload:
    logger.LOGGER.error("Register Payload doesn't contains any 'email' field")
    return JSONResponse(
      content={
        "status": False,
        "message": "The Payload doesn't contains any 'email' field",
      },
      status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
    )

  if ("given_name" not in payload) or ("name" not in payload):
    logger.LOGGER.error(
      "Register Payload doesn't contains any 'given_name' or 'name' field"
    )
    return JSONResponse(
      content={
        "status": False,
        "message": "The Payload doesn't contains any 'given_name' or 'name' field",
      },
      status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
    )

  if "sub" not in payload:
    logger.LOGGER.error("Register Payload doesn't contains any 'sub' field")
    return JSONResponse(
      content={
        "status": False,
        "message": "The Payload doesn't contains any 'sub' field",
      },
      status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
    )

  first_name = str(payload.get("given_name") or payload.get("name"))
  last_name = str(payload.get("family_name", ""))
  user_email = str(payload.get("email"))
  google_id = str(payload.get("sub"))

  created = await users.register(
    first_name=first_name, last_name=last_name, email=user_email, google_id=google_id
  )

  if created:
    logger.LOGGER.debug("Registration Successful")
    return JSONResponse(
      content={"status": True, "message": "Registration Successful"},
      status_code=status.HTTP_201_CREATED,
    )
  else:
    logger.LOGGER.debug("Email already exist")
    return JSONResponse(
      content={"status": False, "message": "Email already exist"},
      status_code=status.HTTP_409_CONFLICT,
    )


@router.post("/add")
async def add_user(
  data: contacts.ContactData, user_id: str = Depends(authenticate.verify_jwt)
):
  current_user, target_user = await asyncio.gather(
    User.get_or_none(id=user_id), User.get_or_none(email=data.email)
  )

  if current_user is None:
    return JSONResponse(
      content={"status": False, "message": "Invalid Session"},
      status_code=status.HTTP_401_UNAUTHORIZED,
    )

  if target_user is None:
    return JSONResponse(
      content={"status": False, "message": "User not found"},
      status_code=status.HTTP_404_NOT_FOUND,
    )

  result = await Contact.create(owner=current_user, contact_user=target_user)

  if result is not None:
    return JSONResponse(
      content={"status": True, "message": f"{data.email} is added to your contact"},
      status_code=status.HTTP_201_CREATED,
    )
  else:
    return JSONResponse(
      content={
        "status": False,
        "message": "Unable to save to contact, Please try again later",
      },
      status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
    )


@router.post("/ban")
async def ban_user(
  data: contacts.ContactData, user_id: str = Depends(authenticate.verify_jwt)
):
  current_user, target_user = await asyncio.gather(
    User.get_or_none(id=user_id), User.get_or_none(email=data.email)
  )

  if current_user is None:
    return JSONResponse(
      content={"status": False, "message": "Invalid Session"},
      status_code=status.HTTP_401_UNAUTHORIZED,
    )

  if target_user is None:
    return JSONResponse(
      content={"status": False, "message": "User not found"},
      status_code=status.HTTP_404_NOT_FOUND,
    )

  response = await Contact.get_or_none(owner=current_user, contact_user=target_user)

  if response is not None:
    await response.delete()

  return JSONResponse(
    content={"status": True, "message": "Contact removed successfully"},
    status_code=status.HTTP_200_OK,
  )


@router.get("/contacts")
async def get_contacts(user_id: str = Depends(authenticate.verify_jwt)):
  current_user = await User.get_or_none(id=user_id)
  if current_user is None:
    return JSONResponse(
      content={"status": False, "message": "Invalid Session"},
      status_code=status.HTTP_401_UNAUTHORIZED,
    )

  data = []
  async for item in Contact.filter(owner=current_user).prefetch_related("contact_user"):
    name = item.contact_user.firstname
    if item.contact_user.lastname:
      name += " " + item.contact_user.lastname
    email = item.contact_user.email

    data.append({"name": name, "email": email})

  logger.LOGGER.debug(data)

  return JSONResponse(
    content={"status": True, "message": "Contact fetching successful", "data": data},
    status_code=status.HTTP_200_OK,
  )


fcmRouter = APIRouter(prefix="/fcm", tags=["FCM"])


@fcmRouter.post("/update")
async def update_fcm_token(
  data: fcm.FCMUpdate, user_id: str = Depends(authenticate.verify_jwt)
):
  user = await User.get_or_none(id=user_id)

  if not user:
    logger.LOGGER.debug("User not found")
    return JSONResponse(
      content={"status": False, "message": "User not found"},
      status_code=status.HTTP_404_NOT_FOUND,
    )

  # Update the token field
  user.fcm_token = data.fcm_token
  await user.save()

  return JSONResponse(
    content={"status": "success", "message": "FCM token updated"},
    status_code=status.HTTP_200_OK,
  )


router.include_router(fcmRouter)
