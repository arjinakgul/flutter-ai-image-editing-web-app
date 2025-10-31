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

This README includes this AI Tools Usage section to provide transparency about the development process and to help others understand how modern AI coding assistants can be effectively integrated into software development workflows. Approximately **70-80%** of the initial code was AI-assisted, with **100%** human review, testing, and refinement.

---

## License

This project is open source and available under the [MIT License](LICENSE).

---








