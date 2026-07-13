from __future__ import annotations

import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent


class Config:
    DATABASE = os.getenv("TEACHING_DB", str(BASE_DIR / "data" / "teaching.db"))
    TOKEN_EXPIRE_DAYS = int(os.getenv("TOKEN_EXPIRE_DAYS", "7"))
    JSON_AS_ASCII = False
    MAX_CONTENT_LENGTH = 8 * 1024 * 1024
