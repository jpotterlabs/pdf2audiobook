# Worker Service Fix Guide

**Date**: 2025-11-14 08:30 UTC  
**Status**: Worker service suspended and failing to start  
**Error**: `Could not parse SQLAlchemy URL from given URL string`

---

## 🚨 CURRENT ISSUE

The worker service (`srv-d4ba08juibrs739obsfg`) is:
- ❌ **Status**: Suspended (manually suspended by user)
- ❌ **Error**: Database URL parsing error on startup
- ❌ **Last Deploy**: Failed at 04:25 UTC

### Error Details

```
sqlalchemy.exc.ArgumentError: Could not parse SQLAlchemy URL from given URL string
```

This error occurs in `backend/app/core/database.py` when the worker tries to import database modules:
```python
# worker/tasks.py line 11
from app.core.database import SessionLocal, engine

# backend/app/core/database.py line 8
engine = create_engine(
    settings.DATABASE_URL,  # ← This is invalid/empty!
    ...
)
```

---

## 🔍 ROOT CAUSE

The worker service **does not have the `DATABASE_URL` environment variable configured**, or it's set to an invalid value.

When Celery starts, it tries to import the task modules, which import the database configuration. Since `DATABASE_URL` is missing or invalid, SQLAlchemy cannot parse it and crashes.

---

## ✅ SOLUTION

### Step 1: Resume the Worker Service

The service is currently suspended and won't auto-deploy even with fixes pushed.

**Action**: Go to the Render dashboard and resume the service:
1. Navigate to: https://dashboard.render.com/worker/srv-d4ba08juibrs739obsfg
2. Click the "Resume" button (or similar action to unsuspend)

### Step 2: Add Required Environment Variables

The worker needs these environment variables to function:

#### **Critical Variables** (Required for startup):

1. **`DATABASE_URL`** (REQUIRED)
   - Description: PostgreSQL connection string
   - Format: `postgresql://username:password@host:port/database`
   - Source: Copy from backend service or use Render's database connection string
   - Example: `postgresql://postgres_ndt4_user:xxxx@dpg-d4b9hv3uibrs739o31g0-a.oregon-postgres.render.com/postgres_ndt4`

2. **`REDIS_URL`** (REQUIRED)
   - Description: Redis connection string for Celery broker
   - Format: `redis://host:port/db` or `rediss://...` for TLS
   - Example: `redis://red-xxxxx:6379/0`

#### **Operational Variables** (Required for job processing):

3. **`AWS_ACCESS_KEY_ID`** (REQUIRED for S3)
   - Description: AWS access key for S3 uploads
   - Get from: AWS IAM console

4. **`AWS_SECRET_ACCESS_KEY`** (REQUIRED for S3)
   - Description: AWS secret key for S3 uploads
   - Get from: AWS IAM console

5. **`AWS_S3_BUCKET_NAME`** (REQUIRED for S3)
   - Description: S3 bucket name for PDF and audio files
   - Example: `pdf2audiobook-files`

6. **`AWS_REGION`** (REQUIRED for S3)
   - Description: AWS region for S3 bucket
   - Example: `us-east-1`

7. **`OPENAI_API_KEY`** (REQUIRED for TTS)
   - Description: OpenAI API key for text-to-speech
   - Get from: https://platform.openai.com/api-keys

#### **Optional Variables**:

8. **`CELERY_BROKER_URL`** (Optional - defaults to REDIS_URL)
   - Usually same as `REDIS_URL`

9. **`CELERY_RESULT_BACKEND`** (Optional - defaults to REDIS_URL)
   - Usually same as `REDIS_URL`

### Step 3: How to Add Environment Variables in Render

1. **Go to Worker Service Dashboard**:
   https://dashboard.render.com/worker/srv-d4ba08juibrs739obsfg

2. **Navigate to Environment Tab**:
   - Click "Environment" in the left sidebar

3. **Add Each Variable**:
   - Click "Add Environment Variable"
   - Enter the key (e.g., `DATABASE_URL`)
   - Enter the value
   - Click "Save Changes"

4. **Important**: After adding all variables, trigger a new deployment:
   - Click "Manual Deploy" button
   - Select "Clear build cache & deploy" if there are issues

### Step 4: Get DATABASE_URL from Backend Service

If you don't have the `DATABASE_URL`:

**Option A: Copy from Backend Service**
1. Go to backend service: https://dashboard.render.com/web/srv-d4b9b56r433s7397n9q0
2. Click "Environment" tab
3. Find `DATABASE_URL` and copy its value
4. Paste into worker service environment variables

**Option B: Get from Database Service**
1. Go to database dashboard: https://dashboard.render.com/d/dpg-d4b9hv3uibrs739o31g0-a
2. Click "Connect" button
3. Copy the "Internal Database URL" (starts with `postgresql://`)
4. Add to worker service

### Step 5: Verify Configuration

After adding environment variables and deploying:

1. **Check Build Logs**:
   - Should complete successfully (install dependencies)

2. **Check Startup Logs**:
   - Look for: `celery@hostname ready.`
   - Should NOT see: `Could not parse SQLAlchemy URL`

3. **Check Worker Status**:
   - Worker should show as "Running" in dashboard
   - No crash loops or restart attempts

---

## 🧪 TESTING AFTER FIX

Once worker is running successfully:

### Test 1: Worker is Alive
```bash
# Check worker logs for startup message
# Should see:
# [timestamp] [Worker-1] celery@hostname ready.
```

### Test 2: Worker Can Connect to Database
```bash
# Worker should not crash on startup
# Check logs - no SQLAlchemy errors
```

### Test 3: Worker Can Process Jobs
1. Upload a PDF via frontend: https://pdf2audiobook.xyz
2. Check backend logs - job should be created
3. Check worker logs - job should be picked up
4. Job should process and complete

---

## 📋 ENVIRONMENT VARIABLE CHECKLIST

Before deploying worker, verify you have:

- [ ] `DATABASE_URL` - PostgreSQL connection string
- [ ] `REDIS_URL` - Redis connection string for Celery
- [ ] `AWS_ACCESS_KEY_ID` - AWS access key
- [ ] `AWS_SECRET_ACCESS_KEY` - AWS secret key
- [ ] `AWS_S3_BUCKET_NAME` - S3 bucket name
- [ ] `AWS_REGION` - AWS region (e.g., us-east-1)
- [ ] `OPENAI_API_KEY` - OpenAI API key for TTS
- [ ] Worker service is **NOT suspended**

---

## 🔧 WORKER SERVICE CONFIGURATION

Current worker configuration:

```yaml
Service ID: srv-d4ba08juibrs739obsfg
Type: Background Worker
Runtime: Python 3.14
Root Directory: . (project root)
Build Command: pip install -r requirements.txt
Start Command: celery -A worker.celery_app worker --loglevel=info
Auto-Deploy: Yes
Branch: main
```

**Note**: The worker runs from the project root, so it can access both `worker/` and `backend/` directories.

---

## 🚨 COMMON ERRORS AND FIXES

### Error: "Could not parse SQLAlchemy URL"
**Cause**: `DATABASE_URL` is missing, empty, or invalid  
**Fix**: Add valid `DATABASE_URL` environment variable

### Error: "No module named 'worker'"
**Cause**: Start command or root directory is wrong  
**Fix**: Ensure start command is `celery -A worker.celery_app worker --loglevel=info` and root directory is `.` (project root)

### Error: Celery can't connect to broker
**Cause**: `REDIS_URL` is missing or invalid  
**Fix**: Add valid `REDIS_URL` environment variable

### Error: Worker restarts continuously
**Cause**: Database connection fails, or other startup error  
**Fix**: Check logs for specific error, ensure all required environment variables are set

### Error: Jobs created but not processed
**Cause**: Worker is not running or not connected to same Redis as backend  
**Fix**: Verify worker is running and both backend and worker use the same `REDIS_URL`

---

## 📊 DEPLOYMENT TIMELINE

| Time (UTC) | Event | Status |
|------------|-------|--------|
| 04:24 | Worker deployed (commit 1718056) | ✅ Build succeeded |
| 04:25 | Worker crashed on startup | ❌ Database URL error |
| 04:25 | Worker suspended by user | 🔴 Suspended |
| 08:20 | Backend fixed and deployed | ✅ Backend live |
| **NOW** | **Worker needs env vars + resume** | ⏳ **Pending** |

---

## 🎯 QUICK FIX SUMMARY

1. **Resume worker service** in Render dashboard
2. **Add `DATABASE_URL`** environment variable (copy from backend service)
3. **Add `REDIS_URL`** environment variable
4. **Add AWS credentials** (ACCESS_KEY, SECRET_KEY, BUCKET, REGION)
5. **Add `OPENAI_API_KEY`** for TTS processing
6. **Manually trigger deployment**
7. **Verify worker starts successfully** (check logs for "ready")
8. **Test PDF upload** to verify end-to-end workflow

---

## 📞 SERVICE LINKS

- **Worker Dashboard**: https://dashboard.render.com/worker/srv-d4ba08juibrs739obsfg
- **Backend Dashboard**: https://dashboard.render.com/web/srv-d4b9b56r433s7397n9q0
- **Database Dashboard**: https://dashboard.render.com/d/dpg-d4b9hv3uibrs739o31g0-a
- **Redis Dashboard**: (If using Render Redis, check your services)

---

**Priority**: 🔴 **HIGH** - Worker must be fixed for PDF processing to work

**Next Action**: Add environment variables in Render dashboard and resume service