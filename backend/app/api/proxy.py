from fastapi import APIRouter

from backend.app.schemas.proxy import ProxyStatusResponse

router = APIRouter(prefix="/proxy", tags=["proxy"])


@router.get("/status", response_model=ProxyStatusResponse)
def proxy_status():
    return ProxyStatusResponse(
        status="unconfigured",
        mevo_connected=False,
        client_connected=False,
        packets_seen=0,
        last_observation_at=None,
        detail="GolfSimRAS adapter is not wired yet.",
    )
