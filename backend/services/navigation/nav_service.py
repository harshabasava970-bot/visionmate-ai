"""
VisionMate AI - Navigation Service
=====================================
Wraps Google Maps Directions API to provide step-by-step voice navigation.
"""

from __future__ import annotations

import googlemaps
from config import get_settings
from utils.logger import setup_logger

logger = setup_logger(__name__)
settings = get_settings()


def _get_client() -> googlemaps.Client:
    """Return a Google Maps client."""
    if not settings.google_maps_api_key:
        raise ValueError("GOOGLE_MAPS_API_KEY is not configured.")
    return googlemaps.Client(key=settings.google_maps_api_key)


def get_directions(
    origin_lat: float,
    origin_lng: float,
    destination: str,
    mode: str = "walking",
) -> dict:
    """
    Fetch walking directions from current GPS location to destination.

    Args:
        origin_lat: Current latitude.
        origin_lng: Current longitude.
        destination: Destination address or place name.
        mode: Travel mode (walking | transit | driving).

    Returns:
        {
            "steps": [{"instruction": str, "distance": str, "duration": str}],
            "total_distance": str,
            "total_duration": str,
            "voice_instructions": [str]
        }
    """
    client = _get_client()
    origin = f"{origin_lat},{origin_lng}"

    try:
        result = client.directions(origin, destination, mode=mode, language="en")
    except Exception as exc:
        logger.error(f"Google Maps API error: {exc}")
        raise

    if not result:
        return {"error": "No route found.", "steps": []}

    route = result[0]
    leg = route["legs"][0]

    steps = []
    voice_instructions = []

    for step in leg["steps"]:
        # Strip HTML tags from instruction
        instruction = _strip_html(step["html_instructions"])
        distance = step["distance"]["text"]
        duration = step["duration"]["text"]

        steps.append({
            "instruction": instruction,
            "distance": distance,
            "duration": duration,
        })
        voice_instructions.append(f"{instruction}. In {distance}.")

    return {
        "steps": steps,
        "total_distance": leg["distance"]["text"],
        "total_duration": leg["duration"]["text"],
        "voice_instructions": voice_instructions,
        "start_address": leg["start_address"],
        "end_address": leg["end_address"],
    }


def _strip_html(text: str) -> str:
    """Remove HTML tags from Google Maps instruction strings."""
    import re
    clean = re.sub(r"<[^>]+>", " ", text)
    return re.sub(r"\s+", " ", clean).strip()
