"""
Database models matching the Supabase table schema
"""
from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class JobDB(BaseModel):
    """
    Database model for jobs table in Supabase
    """
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    prompt: str
    status: str
    original_image_url: Optional[str] = None
    edited_image_url: Optional[str] = None
    error_message: Optional[str] = None

    class Config:
        from_attributes = True
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }


class JobCreate(BaseModel):
    """Model for creating a new job (INSERT)"""
    prompt: str
    status: str
    original_image_url: Optional[str] = None


class JobUpdate(BaseModel):
    """Model for updating an existing job (UPDATE)"""
    status: Optional[str] = None
    edited_image_url: Optional[str] = None
    error_message: Optional[str] = None
