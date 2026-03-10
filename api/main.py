import firebase_admin
from firebase_admin import credentials
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from fastapi import status
from core import lifespan
from routers import voicecallRouter, usersRouter, authRouters
from core import settings
import database


app = FastAPI(
  title="DialSome",
  docs_url=settings.DOCS_URL,
  redoc_url=settings.REDOC_URL,
  openapi_url=settings.OPENAPI_URL,
  lifespan=lifespan.APILifespan,
)

firebase_admin.initialize_app(
  credentials.Certificate(settings.FIREBASE_SERVICE_ACCOUNT)
)

app.include_router(voicecallRouter.router)
app.include_router(voicecallRouter.socket)
app.include_router(usersRouter.router)
app.include_router(authRouters.router)

# Initialize Database ORM
database.InitializeORM(app, settings.POSTGREDSQL_URI)

# Initialize Cache Database
_ = database.CACHE

# Initialize Auth Storage
_ = database.AUTH_STORAGE


@app.get("/")
async def root():
  return JSONResponse(
    {"status": True, "message": "Service is working"}, status_code=status.HTTP_200_OK
  )


@app.head("/")
async def root_head():
  return


if __name__ == "__main__":
  import uvicorn

  uvicorn.run(app, host="0.0.0.0", port=8000)
