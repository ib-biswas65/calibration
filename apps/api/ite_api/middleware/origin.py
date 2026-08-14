from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse, Response

from ite_api.config import get_settings

_SAFE = {"GET", "HEAD", "OPTIONS"}


class OriginCheckMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next) -> Response:
        if request.method in _SAFE:
            return await call_next(request)
        s = get_settings()
        allowed = {o.strip() for o in s.allowed_origins.split(",") if o.strip()}
        origin = request.headers.get("origin", "")
        if not origin or origin not in allowed:
            return JSONResponse({"detail": "bad origin"}, status_code=400)
        return await call_next(request)
