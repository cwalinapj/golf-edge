from fastapi import APIRouter, WebSocket

router = APIRouter(tags=["ws"])


@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    await websocket.send_json({"type": "hello", "message": "golf-edge websocket connected"})
    try:
        while True:
            data = await websocket.receive_text()
            await websocket.send_json({"type": "echo", "payload": data})
    except Exception:
        await websocket.close()
