from fastapi import FastAPI, File, UploadFile, Form, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uuid
from datetime import datetime
from typing import Optional

from app.models import JobResponse, JobListResponse, JobStatus
from app.database import db
from app.services.fal_service import fal_service

app = FastAPI(
    title="AI Image Editing API",
    description="Backend API for AI-powered image editing using fal.ai",
    version="1.0.0"
)

# CORS Configuration - Allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


async def process_job_in_background(job_id: str, original_image_url: str, prompt: str):
    """
    Background task to process the image editing job
    """
    try:
        # Update job status to processing
        await db.update_job(job_id, status=JobStatus.PROCESSING)

        # Process the image
        result = await fal_service.edit_image(original_image_url, prompt)

        if result["success"]:
            # Update job with success
            await db.update_job(
                job_id,
                status=JobStatus.COMPLETED,
                edited_image_url=result["edited_image_url"]
            )
        else:
            # Update job with error
            await db.update_job(
                job_id,
                status=JobStatus.FAILED,
                error_message=result.get("error", "Unknown error occurred")
            )

    except Exception as e:
        # Update job with error
        await db.update_job(
            job_id,
            status=JobStatus.FAILED,
            error_message=str(e)
        )


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "ok",
        "message": "AI Image Editing API is running",
        "timestamp": datetime.utcnow().isoformat()
    }



@app.post("/api/jobs", response_model=JobResponse)
async def create_job(
    background_tasks: BackgroundTasks,
    image: Optional[UploadFile] = File(None),
    image_url: Optional[str] = Form(None),
    prompt: str = Form(...)
):
    """
    Create a new image editing job

    Parameters:
    - image: The image file to edit
    - image_url: The URL of the image to edit
    - prompt: Text description of the desired edits

    Returns:
    - Job details with job_id for tracking
    """
    try:
        if image_url:
            original_image_url = image_url
        else:
            # Validate image file
            if not image.content_type or not image.content_type.startswith("image/"):
                raise HTTPException(status_code=400, detail="File must be an image")

            # Read image data
            image_data = await image.read()

            # Upload image to fal.ai to get URL
            try:
                original_image_url = await fal_service.upload_image_to_fal(image_data)
            except Exception as e:
                raise HTTPException(status_code=500, detail=f"Failed to upload image: {str(e)}")

        # Create job in database
        job = await db.create_job(
            prompt=prompt,
            original_image_url=original_image_url
        )
        if not job:
            raise HTTPException(status_code=500, detail="Failed to create job in database")

        # Add background task to process the image
        background_tasks.add_task(process_job_in_background, job.id, original_image_url, prompt)
        # Return Job Response
        return JobResponse(
            id=job.id,
            prompt=job.prompt,
            status=JobStatus(job.status),
            original_image_url=job.original_image_url,
            edited_image_url=job.edited_image_url,
            error_message=job.error_message,
            created_at=datetime.fromisoformat(str(job.created_at)),
            updated_at=datetime.fromisoformat(str(job.updated_at))
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/jobs/{job_id}", response_model=JobResponse)
async def get_job(job_id: str):
    """
    Get job status and results by job_id

    Parameters:
    - job_id: The unique identifier for the job

    Returns:
    - Job details including status and results if completed
    """
    try:
        job = await db.get_job(job_id)

        if not job:
            raise HTTPException(status_code=404, detail="Job not found")

        return JobResponse(
            id=job.id,
            prompt=job.prompt,
            status=JobStatus(job.status),
            original_image_url=job.original_image_url,
            edited_image_url=job.edited_image_url,
            error_message=job.error_message,
            created_at=datetime.fromisoformat(str(job.created_at)),
            updated_at=datetime.fromisoformat(str(job.updated_at))
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/jobs", response_model=JobListResponse)
async def list_jobs(limit: int = 100, offset: int = 0):
    """
    List all jobs with pagination

    Parameters:
    - limit: Maximum number of jobs to return (default: 100)
    - offset: Number of jobs to skip (default: 0)

    Returns:
    - List of jobs and total count
    """
    try:
        jobs_data, total = await db.get_all_jobs(limit=limit, offset=offset)
        jobs = [
            JobResponse(
                id=job.id,
                prompt=job.prompt,
                status=JobStatus(job.status),
                original_image_url=job.original_image_url,
                edited_image_url=job.edited_image_url,
                error_message=job.error_message,
                created_at=datetime.fromisoformat(str(job.created_at)),
                updated_at=datetime.fromisoformat(str(job.updated_at)),
            )
            for job in jobs_data
        ]

        return JobListResponse(jobs=jobs, total=total)

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
