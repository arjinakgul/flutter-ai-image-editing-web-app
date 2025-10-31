from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from enum import Enum


class JobStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


class JobCreate(BaseModel):
    prompt: str
    image_url: Optional[str] = None


class JobResponse(BaseModel):
    id: int
    prompt: str
    status: JobStatus
    original_image_url: Optional[str] = None
    edited_image_url: Optional[str] = None
    error_message: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class JobListResponse(BaseModel):
    jobs: list[JobResponse]
    total: int
