"""
VisionMate AI - Logging Utility
================================
Configures loguru for structured, coloured logging.
"""

import sys
from loguru import logger


def setup_logger(name: str = "visionmate"):
    """Configure and return a named logger."""
    logger.remove()  # Remove default handler
    logger.add(
        sys.stdout,
        format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | "
               "<level>{level: <8}</level> | "
               "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> - "
               "<level>{message}</level>",
        level="DEBUG",
        colorize=True,
    )
    logger.add(
        "logs/visionmate.log",
        rotation="10 MB",
        retention="7 days",
        level="INFO",
        format="{time} | {level} | {name}:{function}:{line} - {message}",
    )
    return logger
