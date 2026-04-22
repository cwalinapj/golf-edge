from fastapi import FastAPI

from backend.app.api import admin, events, mevo, proxy, sensors, sessions, ws

app = FastAPI(title="Rail Golf API")
app.include_router(sessions.router)
app.include_router(events.router)
app.include_router(sensors.router)
app.include_router(mevo.router)
app.include_router(proxy.router)
app.include_router(admin.router)
app.include_router(ws.router)


@app.get("/health")
def health():
    return {"status": "ok"}
