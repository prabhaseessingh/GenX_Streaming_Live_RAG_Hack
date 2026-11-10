"""Gnani Prisma REST adapter for short uploaded audio clips."""
import os
from pathlib import Path

import httpx


class ASRUnavailable(RuntimeError):
    """Raised when Gnani ASR is not configured or cannot process the clip."""


class GnaniASR:
    def __init__(self):
        self.api_key = os.getenv("GNANI_API_KEY", "").strip()
        if not self.api_key:
            raise ASRUnavailable("Set GNANI_API_KEY in backend/.env to enable Gnani audio transcription")
        self.endpoint = os.getenv("GNANI_STT_URL", "https://api.vachana.ai/stt/v3")
        self.language = os.getenv("GNANI_LANGUAGE_CODE", "en-IN")
        self.model = os.getenv("GNANI_STT_MODEL", "prisma-v3.0")

    def transcribe(self, audio_path: str):
        path = Path(audio_path)
        try:
            with path.open("rb") as audio_file:
                response = httpx.post(
                    self.endpoint,
                    headers={"X-API-Key-ID": self.api_key},
                    data={"language_code": self.language, "model": self.model, "format": "transcribe"},
                    files={"audio_file": (path.name, audio_file)},
                    timeout=httpx.Timeout(90.0, connect=15.0),
                )
        except httpx.HTTPError as exc:
            raise RuntimeError(f"Gnani speech service request failed: {exc}") from exc

        if response.is_error:
            try:
                detail = response.json().get("error", {}).get("message") or response.json().get("detail")
            except (ValueError, AttributeError):
                detail = response.text[:500]
            if response.status_code in (401, 403):
                raise RuntimeError("Gnani rejected the API key or its permissions")
            raise RuntimeError(f"Gnani speech service returned HTTP {response.status_code}: {detail or 'request failed'}")

        try:
            payload = response.json()
            transcript = payload["transcript"].strip()
        except (ValueError, KeyError, AttributeError, TypeError) as exc:
            raise RuntimeError("Gnani returned an invalid transcription response") from exc
        segments = [{"timestamp_s": 0.0, "text": transcript}] if transcript else []
        return segments, {
            "language": payload.get("detected_language_code", self.language),
            "duration": None,
            "model": payload.get("model", self.model),
        }
