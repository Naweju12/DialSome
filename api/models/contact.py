from tortoise.models import Model
from tortoise import fields


class Contact(Model):
  id = fields.UUIDField(primary_key=True)
  owner = fields.ForeignKeyField(
    "models.User", related_name="contacts", on_delete=fields.CASCADE
  )
  contact_user = fields.ForeignKeyField(
    "models.User", related_name="added_by", on_delete=fields.CASCADE
  )
