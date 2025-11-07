# AI Image Editing Web Application

A full-stack web application that leverages AI-powered image editing through the fal.ai Seedream v4 model. Built with Flutter for the frontend and FastAPI for the backend, this application enables users to transform images using natural language prompts with iterative editing capabilities and comprehensive history tracking.

## Overview

This monorepo contains a production-ready AI image editing platform that combines the power of ByteDance's Seedream v4 model with an intuitive web interface. Users can upload images, describe desired edits in plain text, and receive AI-generated results in real-time. The application supports iterative editing workflows, allowing users to refine their images through multiple editing passes, with all jobs persisted in a database for future reference.

**Live Demo:** https://ai-image-editing-web-app.web.app/

### Key Highlights

- **AI-Powered Editing:** Utilizes fal.ai's ByteDance Seedream v4 model for high-quality image transformations
- **Iterative Workflow:** Select original or edited images as the base for subsequent edits
- **Real-time Processing:** Live status updates with polling mechanism and progress tracking
- **Comprehensive History:** Browse, review, and continue editing from previous jobs
- **Modern Stack:** Flutter web frontend with FastAPI backend and Supabase database
- **Production Ready:** Configured for Firebase Hosting (frontend) and Vercel (backend)

## Features

### Core Features

#### 1. AI-Powered Image Editing
- Upload images via file picker
- Describe desired edits using natural language prompts
- AI processing powered by fal.ai's ByteDance Seedream v4 model
- Support for JPG, JPEG, PNG, and WEBP formats (up to 10MB)
- High-resolution output (2048x2048 pixels)

#### 2. Real-time Processing & Status Updates
- Live job status tracking (Pending → Processing → Completed/Failed)
- Automatic polling with 3-second intervals
- Visual loading states with shimmer effects
- 5-minute timeout handling for long-running jobs
- User-friendly error messages

#### 3. Before/After Comparison
- Side-by-side image display for visual comparison
- Interactive selection between original and edited versions
- Clear visual indicators and labels
- Smooth transitions and responsive layout

#### 4. Iterative Editing Workflow
- Select either original or edited image as the base for next edit
- Chain multiple edits sequentially to refine results
- All editing history preserved in database
- Continue editing from any previous job

#### 5. Gallery & History Management
- Comprehensive view of all editing jobs
- Paginated grid layout (responsive: 1-3 columns)
- Status badges for quick identification (Completed/Failed/Processing)
- Relative timestamps ("Just now", "2 hours ago", etc.)
- Detailed modal view with full job information
- Refresh functionality to sync latest jobs

#### 6. Image Download
- Download edited images to local system
- Timestamped filenames for organization
- Web-compatible download implementation

### Additional Features

- **Responsive Design:** Optimized for desktop, tablet, and mobile devices
- **Material Design 3:** Modern UI with consistent theming
- **Empty States:** Helpful guidance when no jobs exist
- **Error Handling:** Graceful degradation with informative messages
- **Background Processing:** Non-blocking job execution
- **Database Persistence:** All jobs stored in Supabase for reliability

## Tech Stack

### Frontend

- **Framework:** [Flutter](https://flutter.dev/)
- **UI Library:** Material Design 3
- **HTTP Client:** [http](https://pub.dev/packages/http)
- **File Handling:** [file_picker](https://pub.dev/packages/file_picker)
- **State Management:** StatefulWidget with setState (no external state library)
- **Hosting:** [Firebase Hosting](https://firebase.google.com/docs/hosting)

### Backend

- **Framework:** [FastAPI](https://fastapi.tiangolo.com/)
- **ASGI Server:** [Uvicorn](https://www.uvicorn.org/)
- **Database:** [Supabase](https://supabase.com/) (PostgreSQL)
- **AI Integration:** [fal.ai](https://fal.ai/) Python Client
- **Key Libraries:**
  - `supabase-py` - Database client
  - `fal-client` - AI model API client
  - `python-multipart` - File upload handling
  - `python-dotenv` - Environment variable management
  - `httpx` - Async HTTP client
  - `pillow` - Image processing
- **Hosting:** [Vercel](https://vercel.com/)

### AI Model

- **Provider:** [fal.ai](https://fal.ai/)
- **Model:** `fal-ai/bytedance/seedream/v4/edit`
- **Type:** ByteDance Seedream v4 - Image-to-image editing

### Database Schema (Supabase)

```sql
Table: jobs
├── id (int, primary key, auto-generated)
├── prompt (varchar)
├── status (varchar(20): pending | processing | completed | failed)
├── original_image_url (varchar)
├── edited_image_url (varchar)
├── error_message (varchar)
├── created_at (timestamp with time zone)
└── updated_at (timestamp with time zone)

```

### Development Tools

- **Code Editor:** [Cursor](https://cursor.com/)
- **AI Assistant:** [Claude Code](https://www.claude.com/product/claude-code)
- **Monorepo:** VS Code Workspace configuration
- **Version Control:** Git
- **Code Quality:** flutter_lints

## Architecture Overview

### System Architecture

This application follows a three-tier architecture with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Web Frontend                    │
│  ┌────────────┐  ┌──────────────┐  ┌──────────────────┐     │
│  │   Screens  │  │   Services   │  │     Widgets      │     │
│  │            │  │              │  │                  │     │
│  │ - HomePage │  │ - JobService │  │ - BeforeAfter    │     │
│  │ - History  │  │ - ApiService │  │                  │     │
│  └────────────┘  └──────────────┘  └──────────────────┘     │
│                          │                                  │
│                  JobService → ApiService                    │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ HTTP REST API
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    FastAPI Backend (Vercel)                 │
│  ┌────────────┐  ┌──────────────┐  ┌──────────────────┐     │
│  │ Endpoints  │  │   Services   │  │     Database     │     │
│  │            │  │              │  │                  │     │
│  │ - POST job │  │ - FalService │  │ - Supabase API   │     │
│  │ - GET job  │  │ - Processing │  │ - Job CRUD       │     │
│  │ - GET list │  │              │  │                  │     │
│  └────────────┘  └──────────────┘  └──────────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
                 ┌──────────┴──────────┐
                 │                     │
                 ▼                     ▼
         ┌──────────────┐      ┌─────────────┐
         │   fal.ai     │      │  Supabase   │
         │              │      │             │
         │ Seedream v4  │      │ PostgreSQL  │
         │ Image Edit   │      │  Database   │
         └──────────────┘      └─────────────┘
```

### Data Flow

#### 1. Image Upload & Job Creation

```
User uploads image + prompt
        │
        ▼
Frontend (HomePage)
        │
        ├─ Validate image (format, size)
        ├─ Create multipart/form-data request
        │
        ▼
JobService
        │
        └─ Calls ApiService
            │
            ▼
Backend (POST /api/jobs)
        │
        ├─ Receive image file
        ├─ Upload to fal.ai storage → Get image URL
        ├─ Create job record in Supabase (status: "pending")
        ├─ Return job_id to frontend
        │
        ▼
Background Task
        │
        ├─ Update status → "processing"
        ├─ Submit to Seedream v4 model
        ├─ Wait for AI processing
        │
        └─ On success:
            ├─ Update status → "completed"
            ├─ Store edited_image_url
            │
        └─ On failure:
            ├─ Update status → "failed"
            ├─ Store error_message
```

#### 2. Real-time Status Polling

```
Frontend starts polling
        │
        ▼
JobService polls every 3 seconds:
        │
        └─ Calls ApiService → GET /api/jobs/{job_id}
            │
            ├─ Check status
            │
            ├─ If "pending" or "processing" → Continue polling
            │
            ├─ If "completed" → Stop polling, display result
            │
            └─ If "failed" → Stop polling, show error

Timeout after 5 minutes → Display timeout message
```

#### 3. Iterative Editing Workflow

```
User selects base image (original or edited)
        │
        ▼
Frontend captures selected image URL
        │
        ├─ User enters new prompt
        ├─ Submits new job with selected image URL
        │
        ▼
JobService → ApiService → Backend creates new job
        │
        ├─ Uses selected image as original_image_url
        ├─ Processes with new prompt
        ├─ Generates new edited result
        │
        ▼
New job added to history
        └─ Can be used as base for further edits
```

### API Endpoints

| Method | Endpoint | Description | Request | Response |
|--------|----------|-------------|---------|----------|
| `GET` | `/` | Health check | - | `{"message": "API is running"}` |
| `POST` | `/api/jobs` | Create editing job | Multipart form or JSON with image URL | `{"job_id": int}` |
| `GET` | `/api/jobs/{job_id}` | Get job details | - | Job object with status |
| `GET` | `/api/jobs?limit={n}` | List all jobs (paginated) | Query param: limit (default: 100) | Array of job objects |

### Component Breakdown

#### Frontend Components

- **[HomePage](frontend/lib/screens/home_page.dart)** (518 lines)
  - Image upload interface
  - Prompt input field
  - Real-time status display
  - Before/After comparison widget
  - Iterative editing controls

- **[HistoryPage](frontend/lib/screens/history_page.dart)** (617 lines)
  - Paginated job grid
  - Detailed job modal
  - Continue editing functionality

- **[BeforeAfterWidget](frontend/lib/widgets/before_after.dart)** (398 lines)
  - Side-by-side image comparison
  - Interactive selection
  - Loading states
  - Download functionality

- **[JobService](frontend/lib/services/job_service.dart)**
  - High-level job operations wrapper
  - Delegates all API calls to ApiService
  - Abstracts job-related business logic

- **[ApiService](frontend/lib/services/api_service.dart)** (227 lines)
  - HTTP request handling
  - Multipart file uploads
  - Error handling
  - Response parsing

#### Backend Components

- **[main.py](backend/app/main.py)** (208 lines)
  - FastAPI application setup
  - CORS configuration
  - Endpoint definitions
  - Background task management

- **[fal_service.py](backend/app/services/fal_service.py)**
  - fal.ai client integration
  - Image upload to fal.ai storage
  - Job submission to Seedream v4
  - Result processing

- **[database.py](backend/app/database.py)**
  - Supabase client initialization
  - CRUD operations for jobs
  - Database queries and updates

## Setup Instructions

### Prerequisites

Before setting up the project, ensure you have the following installed:

- **Flutter SDK** (3.8.1 or higher) - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (^3.8.1) - Comes with Flutter
- **Python** (3.9 or higher, 3.11+ recommended) - [Download Python](https://www.python.org/downloads/)
- **Git** - [Install Git](https://git-scm.com/downloads)

You'll also need accounts and API keys for:

- **[Supabase](https://supabase.com/)** - Free tier available
- **[fal.ai](https://fal.ai/)** - For AI model access
- **[Firebase](https://firebase.google.com/)** (Optional) - For frontend hosting
- **[Vercel](https://vercel.com/)** (Optional) - For backend hosting

### Local Development Setup

#### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/flutter-ai-image-editing-web-app.git
cd flutter-ai-image-editing-web-app
```

#### 2. Backend Setup

Navigate to the backend directory:

```bash
cd backend
```

Create a virtual environment and activate it:

```bash
# Create virtual environment
python -m venv venv

# Activate on macOS/Linux
source venv/bin/activate

# Activate on Windows
venv\Scripts\activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Create a `.env` file from the example:

```bash
cp .env.example .env
```

Update the `.env` file with your credentials:

```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your_supabase_anon_key

# fal.ai API Configuration
FAL_API_KEY=your_fal_api_key
```

**Set up Supabase Database:**

1. Create a new project in [Supabase](https://app.supabase.com/)
2. Go to the SQL Editor and run the following schema:

```sql
-- Create jobs table
CREATE TABLE jobs (
  id SERIAL PRIMARY KEY,
  prompt VARCHAR,
  status VARCHAR(20) DEFAULT 'pending',
  original_image_url VARCHAR,
  edited_image_url VARCHAR,
  error_message VARCHAR,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

```

3. Get your project URL and anon key from Settings > API

**Get fal.ai API Key:**

1. Sign up at [fal.ai](https://fal.ai/)
2. Navigate to your dashboard
3. Generate an API key
4. Add it to your `.env` file

Start the backend server:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The backend will be running at `http://localhost:8000`

#### 3. Frontend Setup

Open a new terminal and navigate to the frontend directory:

```bash
cd frontend
```

Install Flutter dependencies:

```bash
flutter pub get
```

**Configure API Base URL:**

The frontend uses the `Config` class in [lib/config.dart](frontend/lib/config.dart) for configuration. By default, it's set to `http://localhost:8000` for local development.

For a different backend URL, use compile-time configuration:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

Run the Flutter web application:

```bash
flutter run -d chrome
```

The frontend will open in Chrome at `http://localhost:PORT`

**Note:** The `Config` class also contains other application settings like polling intervals (`pollInterval`, `pollTimeout`), image size limits (`maxImageSizeMB`), and supported file types (`supportedImageTypes`).

### Production Deployment

#### Backend Deployment (Vercel)

1. Install Vercel CLI:

```bash
npm install -g vercel
```

2. Create a `vercel.json` in the backend directory:

```json
{
  "version": 2,
  "builds": [
    {
      "src": "app/main.py",
      "use": "@vercel/python"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "app/main.py"
    }
  ]
}
```

3. Deploy to Vercel:

```bash
cd backend
vercel
```

4. Set environment variables in Vercel dashboard:
   - `SUPABASE_URL`
   - `SUPABASE_KEY`
   - `FAL_API_KEY`

5. Note your production URL (e.g., `https://your-app.vercel.app`)

#### Frontend Deployment (Firebase Hosting)

1. Install Firebase CLI:

```bash
npm install -g firebase-tools
```

2. Login to Firebase:

```bash
firebase login
```

3. Initialize Firebase (if not already done):

```bash
cd frontend
firebase init hosting
```

Select:
- Public directory: `build/web`
- Configure as single-page app: `Yes`
- Set up automatic builds: `No`

4. Build the Flutter web app with your production backend URL:

Use the `--dart-define` flag to set the production API URL:

```bash
flutter build web --release --dart-define=API_BASE_URL=https://your-app.vercel.app
```

**Note:** The `Config` class in [lib/config.dart](frontend/lib/config.dart) uses `String.fromEnvironment()` to read the `API_BASE_URL` at compile time, so no code changes are needed.

5. Deploy to Firebase:

```bash
firebase deploy --only hosting
```

Your app will be live at `https://your-project.web.app`

### Environment Variables

#### Backend (.env)

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `SUPABASE_URL` | Your Supabase project URL | Yes | `https://abc123.supabase.co` |
| `SUPABASE_KEY` | Supabase anonymous key | Yes | `eyJhbGc...` |
| `FAL_API_KEY` | fal.ai API key | Yes | `fal_...` |

#### Frontend (--dart-define)

| Variable | Description | Required | Default | Example |
|----------|-------------|----------|---------|---------|
| `API_BASE_URL` | Backend API URL | No | `http://localhost:8000` | `https://your-app.vercel.app` |

**Note:** The frontend configuration is managed by the `Config` class in [lib/config.dart](frontend/lib/config.dart). Additional settings include:
- `pollInterval`: Job status polling interval (default: 3 seconds)
- `pollTimeout`: Maximum polling duration (default: 5 minutes)
- `maxImageSizeMB`: Maximum image upload size (default: 10MB)
- `supportedImageTypes`: Accepted file formats (jpg, jpeg, png, webp)

### Verification

After setup, verify the installation:

1. **Backend Health Check:**
   ```bash
   curl http://localhost:8000/
   # Should return: {"message": "API is running"}
   ```

2. **Frontend Access:**
   - Open `http://localhost:PORT` in your browser
   - You should see the image upload interface

3. **End-to-End Test:**
   - Upload an image
   - Enter a prompt (e.g., "make it look like a painting")
   - Verify job creation and processing
   - Check the History page for the completed job

## Optional Features Implemented

Beyond the core requirements of AI-powered image editing, this application includes several advanced optional features that enhance the user experience and extend functionality:

### 1. Iterative Editing Workflow

**Description:** One of the standout features of this application is the ability to perform iterative editing on images. Users can select either the original or the AI-edited version as the base for subsequent edits, enabling a chain of refinements.

**Implementation:**
- **Selection Interface:** The Before/After comparison widget ([before_after.dart](frontend/lib/widgets/before_after.dart)) allows users to click and select which version (original or edited) to use as the base for the next edit
- **Visual Feedback:** Selected images are highlighted with a border and checkmark indicator
- **Seamless Workflow:** Once an image is selected, the next edit job uses that image's URL as the `original_image_url`, creating a chain of edits
- **History Preservation:** All editing steps are stored in the database, allowing users to review the complete editing history

**User Benefits:**
- Refine AI results progressively without starting from scratch
- Experiment with multiple editing approaches on the same base image
- Build complex edits through simple, sequential prompts
- No need to download and re-upload images between edits

**Example Workflow:**
```
1. Upload photo.jpg → Prompt: "make it sunset" → Get sunset.jpg
2. Select sunset.jpg → Prompt: "add dramatic clouds" → Get clouds.jpg
3. Select clouds.jpg → Prompt: "increase saturation" → Get final.jpg
```

### 2. Gallery & History Management

**Description:** A comprehensive job history system that allows users to browse, review, and manage all their previous image editing jobs in a visually appealing gallery interface.

**Implementation:**
- **Full History View:** Dedicated History page ([history_page.dart](frontend/lib/screens/history_page.dart)) displays all jobs in a responsive grid layout
- **Responsive Design:** Grid adapts from 1 column (mobile) to 2 columns (tablet) to 3 columns (desktop) based on screen width
- **Rich Job Cards:** Each card shows:
  - Original and edited image thumbnails
  - Editing prompt
  - Status badge (Completed/Failed/Processing)
  - Relative timestamp ("Just now", "2 hours ago", etc.)
- **Detailed Modal View:** Click any job to see full details including high-resolution images, complete prompt, status, and timestamps
- **Continue Editing:** Users can load any previous job back into the editor to continue editing from that point
- **Pagination Support:** Backend supports limit/offset parameters for efficient loading of large job lists
- **Refresh Functionality:** Manual refresh button to sync with latest backend data
- **Empty States:** Helpful messaging when no jobs exist

**Database Persistence:**
- All jobs stored in Supabase with indexed queries for fast retrieval

**User Benefits:**
- Never lose editing work - everything is saved automatically
- Easy reference to past edits and prompts
- Learn from successful prompts by reviewing history
- Continue editing sessions across different devices/sessions
- Visual portfolio of all AI editing experiments

### 3. Additional Enhancements

While the two features above are the primary optional implementations, several other enhancements improve the overall experience:

- **Background Job Processing:** Backend uses FastAPI's `BackgroundTasks` to process images asynchronously, keeping the API responsive
- **Robust Error Handling:** Comprehensive error messages for failed jobs with details stored in the database
- **Loading States:** Professional shimmer effects and skeleton loaders during image processing
- **Download Functionality:** One-click download of edited images with timestamped filenames
- **Responsive UI:** Fully responsive design that works seamlessly across desktop, tablet, and mobile devices
- **Material Design 3:** Modern, consistent UI with proper theming and component styling
- **Real-time Status Updates:** Automatic polling every 3 seconds with 5-minute timeout for long-running jobs

## Known Issues & Trade-offs

This section provides an honest assessment of current limitations and architectural decisions that were made during development. Understanding these trade-offs helps set expectations and provides a roadmap for future improvements.

### Current Limitations

#### 1. No Authentication System

**Issue:** The application is currently completely public with no authentication or authorization mechanism in place.

**Impact:**
- Any user can access the application and create editing jobs
- Users can view all jobs in the system, not just their own
- No privacy controls or data isolation between users
- No API rate limiting per user
- Potential for abuse and unauthorized access

**Trade-off Reasoning:**
- Simplified MVP development and deployment
- Faster iteration on core AI editing features
- Reduced infrastructure complexity for initial release

**Future Considerations:**
- Implement user authentication (Firebase Auth, Supabase Auth, or JWT)
- Add user-specific job filtering (`user_id` column in database)
- Consider passkey/API key system for restricted access
- Implement rate limiting per user/IP address

#### 2. Shared Job History (No Session Logic)

**Issue:** Unlike chatbot applications that maintain conversation sessions, all users share a global job history. There's no concept of individual user sessions or workspaces.

**Impact:**
- Users can see every job created by anyone
- No privacy for editing work
- Confusing UX when multiple users are active
- No way to organize jobs into projects or sessions

**Trade-off Reasoning:**
- Avoided complexity of user management in MVP
- Database schema kept simple without user relationships
- Enabled faster feature development

**Future Considerations:**
- Add user accounts with session management
- Implement project/workspace concept for organizing related edits
- Add filters to view only "My Jobs" vs "All Jobs"
- Consider collaborative features (shared workspaces)

#### 3. No Drag-and-Drop Image Upload

**Issue:** The image upload interface uses a traditional file picker button without drag-and-drop functionality.

**Impact:**
- Less intuitive user experience, especially on desktop
- Requires extra clicks to upload images
- Missing a common UX pattern for file uploads

**Trade-off Reasoning:**
- Faster initial implementation with Flutter's standard file picker
- Cross-platform compatibility ensured (web, mobile, desktop)
- Focus on core functionality over UX polish

**Future Considerations:**
- Implement drag-and-drop zone in upload area
- Add visual feedback for drag hover states
- Support multiple file uploads (batch processing)
- Allow paste from clipboard

#### 4. Backend Code Organization

**Issue:** Backend lacks proper folder structure for endpoints and services.

**Current Structure:**
```
backend/app/
├── main.py           # All endpoints in one file
├── services/
│   └── fal_service.py
├── database.py
├── models.py
└── db_models.py
```

**Impact:**
- All API endpoints defined in `main.py` (208 lines)
- Harder to maintain as the application grows
- Unclear separation between routing and business logic
- Difficult to add new features without cluttering `main.py`

**Trade-off Reasoning:**
- Simpler for small MVP with only 4 endpoints
- Faster development without boilerplate routing setup
- Easier to understand for newcomers to the codebase

**Future Considerations:**
- Refactor to proper structure:
  ```
  backend/app/
  ├── api/
  │   ├── routes/
  │   │   ├── jobs.py
  │   │   └── health.py
  │   └── dependencies.py
  ├── services/
  │   ├── fal_service.py
  │   └── job_service.py
  ├── core/
  │   ├── config.py
  │   └── database.py
  └── main.py
  ```

#### 5. Missing Favicon

**Issue:** The application doesn't have a custom favicon, displaying the default Flutter icon.

**Impact:**
- Less professional appearance in browser tabs
- Harder to identify among multiple open tabs
- Missing branding opportunity

**Trade-off Reasoning:**
- Not critical for MVP functionality
- Prioritized features over visual branding
- Easy to add later without affecting functionality

**Future Considerations:**
- Design custom favicon representing AI/image editing
- Add to `web/favicon.png` and `web/icons/` directory
- Update `web/manifest.json` with proper icon references

### Architectural Trade-offs

#### 1. Polling vs WebSockets

**Current Implementation:** Frontend polls backend every 3 seconds for job status.

**Trade-off:**
- ✅ **Pro:** Simple to implement, works everywhere (no WebSocket infrastructure needed)
- ✅ **Pro:** Works behind restrictive firewalls/proxies
- ❌ **Con:** Inefficient (unnecessary HTTP requests)
- ❌ **Con:** 3-second delay in status updates

**Alternative Considered:** WebSocket connection for real-time updates

#### 2. Wide-Open CORS Policy

**Current Implementation:** Backend allows requests from any origin (`allow_origins=["*"]`).

**Security Risk:**
- ⚠️ Any website can call the API
- ⚠️ Enables CSRF attacks if authentication is added later
- ⚠️ No origin validation

**Note in Code:** [backend/app/main.py:21](backend/app/main.py#L21) includes comment: "In production, replace with specific origins"

**Mitigation Needed:**
- Restrict to specific frontend domain in production
- Implement proper CORS configuration with credentials support

## AI Tools Usage

This project was developed with significant assistance from AI coding tools, demonstrating how modern AI assistants can accelerate development workflows. Here's a transparent breakdown of how [Cursor](https://cursor.com/) and [Claude Code](https://claude.ai/product/claude-code) were utilized throughout the development process:

### Development Workflow

The development process followed a structured approach leveraging both AI tools at different stages:

```
Project Initialization → Implementation → Quality Assurance → Documentation
    (Claude Code)        (Cursor)        (Claude Code)       (Claude Code)
```

### 1. Project Initialization & Planning (Claude Code)

**Role:** High-level architecture and project scaffolding

**Tasks Performed:**
- **FastAPI Backend Setup:** Generated initial FastAPI project structure with proper module organization
- **Flutter Frontend Setup:** Initialized Flutter web project with necessary configurations
- **Folder Structure Planning:** Designed the monorepo layout and file organization for both frontend and backend
  - Planned `backend/app/` structure with services, models, and database modules
  - Organized `frontend/lib/` into screens, services, widgets, and models
- **Dependency Selection:** Recommended appropriate packages for both ecosystems
  - Backend: Supabase, fal-client
  - Frontend: http, file_picker, image_picker
- **Architecture Design:** Helped define the three-tier architecture and API contract

**Output:**
- Initial project skeleton with organized folder structure
- Basic configuration files (`pubspec.yaml`, `requirements.txt`, `.env.example`)
- Foundation for subsequent development

### 2. Code Implementation (Cursor)

**Role:** Real-time coding assistant during active development

**Tasks Performed:**
- **API Endpoints:** Assisted in writing FastAPI route handlers in `main.py`
  - `POST /api/jobs` - Image upload and job creation
  - `GET /api/jobs/{job_id}` - Job status retrieval
  - `GET /api/jobs` - Job history listing
- **Service Layer:** Helped implement `fal_service.py` for fal.ai integration
  - Image upload to fal.ai storage
  - Job submission to Seedream v4 model
  - Result processing and error handling
- **Database Operations:** Coded CRUD operations in `database.py` for Supabase
- **Frontend Screens:** Developed UI components
  - `home_page.dart` - Main editing interface with image upload and prompt input
  - `history_page.dart` - Gallery view with responsive grid layout
- **Widgets:** Created reusable components
  - `before_after.dart` - Image comparison with selection functionality
- **Services:** Implemented API communication layer
  - `api_service.dart` - HTTP client for backend communication
  - `job_service.dart` - High-level job operations wrapper
- **State Management:** Coded StatefulWidget logic for reactive UI updates
- **Error Handling:** Added try-catch blocks and user-friendly error messages

**Working Style:**
- Iterative coding with immediate feedback and suggestions
- Code completion and refactoring assistance
- Bug fixing and debugging support
- Real-time syntax and logic corrections

### 3. Code Quality Assurance (Claude Code)

**Role:** Logic validation and code polishing

**Tasks Performed:**
- **Logical Justification Check:** Reviewed the entire codebase for architectural consistency
  - Verified API contract alignment between frontend and backend
  - Checked data flow consistency across components
  - Validated error handling coverage
  - Ensured proper separation of concerns
- **Code Polishing:** Refactored code for better readability and maintainability
  - Improved naming conventions
  - Added comprehensive code comments and documentation
  - Optimized import statements
  - Standardized code formatting
- **Architecture Review:** Analyzed the overall system design
  - Verified three-tier architecture implementation
  - Checked service layer abstraction (JobService → ApiService pattern)
  - Validated database schema design
- **Best Practices:** Ensured adherence to framework conventions
  - FastAPI async/await patterns
  - Flutter widget composition patterns
  - Dart naming conventions

### 4. Documentation (Claude Code)

**Role:** Technical writing and documentation enhancement

**Tasks Performed:**
- **README Enhancement:** Polished and structured this comprehensive README
  - Added visual ASCII diagrams for architecture and data flow
  - Created formatted tables for API endpoints, environment variables, and database schema
  - Organized sections with clear hierarchy and navigation
  - Added code examples and usage snippets
- **Schema Documentation:** Generated SQL schema with proper syntax
  - Database table definitions
- **API Documentation:** Structured endpoint descriptions with request/response formats
- **Setup Instructions:** Wrote detailed step-by-step installation and deployment guides
- **Code Comments:** Enhanced inline documentation throughout the codebase


### Human Contributions

While AI tools were extensively used, the following required human decision-making and expertise:

- **Feature Prioritization:** Deciding which optional features to implement (iterative editing, history)
- **UX Design:** Layout decisions, color schemes, responsive breakpoints
- **Trade-off Analysis:** Choosing between architectural approaches (polling vs WebSockets, sync vs async)
- **Integration Debugging:** Resolving environment-specific issues (CORS, deployment configs)
- **Business Logic:** Defining the iterative editing workflow and selection mechanism
- **Testing:** Manual testing of user flows and edge cases
- **Deployment:** Configuring Vercel and Firebase hosting environments

### Transparency Note

This README includes this AI Tools Usage section to provide transparency about the development process. Approximately **70-80%** of the initial code was AI-assisted, with **100%** human review, testing, and refinement.

---

## License

This project is open source and available under the [MIT License](LICENSE).

---

