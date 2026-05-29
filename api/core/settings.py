from .environ import ENV
from .debug import DEBUG
from utils import eddsa
import base64
import json


DOCS_URL = "/docs" if DEBUG else None
REDOC_URL = "/redoc" if DEBUG else None
OPENAPI_URL = "/openapi.json" if DEBUG else None

# Load Client ID
if not ENV.exist("APP_CLIENT_ID"):
  raise EnvironmentError("APP_CLIENT_ID can't be empty")
CLIENT_ID = str(ENV.get("APP_CLIENT_ID"))

# Load REDIS_URI Environment Variable
if not ENV.exist("REDIS_URI"):
  raise EnvironmentError("REDIS_URI can't be empty")
REDIS_URI = str(ENV.get("REDIS_URI"))

# Load POSTGRESQL_URI Environment Variable
if not ENV.exist("POSTGRESQL_URI"):
  raise EnvironmentError("POSTGRESQL_URI doesn't exist")
POSTGREDSQL_URI = str(ENV.get("POSTGRESQL_URI"))

# EdDSA Key
if not ENV.exist("EDDSA_PRIVATE_KEY"):
  raise EnvironmentError("EDDSA_PRIVATE_KEY can't be empty")
EDDSA_KEY = eddsa.EdDSA(
  str(ENV.get("EDDSA_PRIVATE_KEY")).strip('"').strip("'").replace("\\n", "\n")
)

# Firebase Service Account
if not ENV.exist("FIREBASE_SERVICE_ACCOUNT"):
  raise EnvironmentError("FIREBASE_SERVICE_ACCOUNT can't be empty")
FIREBASE_SERVICE_ACCOUNT = json.loads(
  base64.b64decode(
    str(ENV.get("FIREBASE_SERVICE_ACCOUNT")).strip('"').strip("'").replace("\\n", "")
  ).decode()
)

# User Token
REFRESH_TOKEN_EXPIRY = 90 * 24 * 60 * 60  # 90 Days
ACCESS_TOKEN_EXPIRY = 60 * 60  # 1 hour
