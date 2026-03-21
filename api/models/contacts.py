from pydantic import BaseModel


class ContactData(BaseModel):
  email: str
