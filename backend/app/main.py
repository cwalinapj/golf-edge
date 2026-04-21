from fastapi import FastAPI

from backend.app.api import courses, events, mevo, rounds, sensors, sessions, ws

app = FastAPI(title="Golf Edge API")
app.include_router(courses.router)
app.include_router(rounds.router)
app.include_router(sessions.router)
app.include_router(events.router)
app.include_router(sensors.router)
app.include_router(mevo.router)
app.include_router(ws.router)


@app.get("/health")
def health():
    return {"status": "ok"}
