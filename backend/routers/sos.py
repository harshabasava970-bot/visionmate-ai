"""
VisionMate AI - /sos Router
=============================
Emergency SOS endpoint.
Sends GPS location via SMS (Twilio) and returns a TTS alert.
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from config import get_settings
from services.voice import text_to_speech
from utils.logger import setup_logger

router = APIRouter()
logger = setup_logger(__name__)
settings = get_settings()


class SOSRequest(BaseModel):
    latitude: float = Field(..., description="User's current latitude")
    longitude: float = Field(..., description="User's current longitude")
    contact_number: str | None = Field(
        None, description="Override emergency contact number"
    )
    lang: str = Field("en", description="TTS language code")


class SOSResponse(BaseModel):
    status: str
    message: str
    audio_b64: str
    sms_sent: bool


@router.post("/", response_model=SOSResponse)
async def send_sos(req: SOSRequest):
    """
    Trigger emergency SOS:
    1. Send SMS with GPS coordinates via Twilio
    2. Return TTS confirmation audio
    """
    contact = req.contact_number or settings.emergency_contact
    if not contact:
        raise HTTPException(
            status_code=503,
            detail="No emergency contact configured.",
        )

    maps_link = (
        f"https://maps.google.com/?q={req.latitude},{req.longitude}"
    )
    sms_body = (
        f"🆘 VisionMate SOS Alert!\n"
        f"User needs help.\n"
        f"Location: {maps_link}\n"
        f"Coordinates: {req.latitude:.6f}, {req.longitude:.6f}"
    )

    sms_sent = False
    try:
        # Only attempt Twilio if credentials are configured
        if all([
            settings.twilio_account_sid,
            settings.twilio_auth_token,
            settings.twilio_from_number,
        ]):
            from twilio.rest import Client as TwilioClient
            client = TwilioClient(
                settings.twilio_account_sid, settings.twilio_auth_token
            )
            client.messages.create(
                body=sms_body,
                from_=settings.twilio_from_number,
                to=contact,
            )
            sms_sent = True
            logger.info(f"SOS SMS sent to {contact}")
        else:
            logger.warning("Twilio not configured. SMS not sent.")
    except Exception as exc:
        logger.error(f"Twilio SMS error: {exc}")

    voice_msg = (
        "Emergency alert sent. Help is on the way. Stay calm."
        if sms_sent
        else "Emergency alert triggered. Please call for help."
    )
    audio_b64 = text_to_speech(voice_msg, lang=req.lang)

    return SOSResponse(
        status="triggered",
        message=voice_msg,
        audio_b64=audio_b64,
        sms_sent=sms_sent,
    )
