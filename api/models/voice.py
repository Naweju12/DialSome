from pydantic import BaseModel
from typing import Optional


class VoiceData(BaseModel):
  email: str
  room_id: Optional[str] = None

