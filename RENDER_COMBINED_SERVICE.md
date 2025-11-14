# 🔄 Running Backend + Worker on Single Render Service

## Overview

If you can't create a separate Background Worker service on Render, you can run both the backend API and Celery worker on the same Web Service using Supervisor.

---

## ⚙️ Configuration

### Update Your Backend Service:

1. **Go to Render Dashboard** → Your Backend Service → **Settings**

2. **Update Start Command:**
   ```bash
   ../render-start-with-worker.sh
   ```

3. **Save Changes** → Click **"Manual Deploy"** → **"Deploy latest commit"**

---

## 📋 What This Does:

The `render-start-with-worker.sh` script:

1. ✅ Verifies environment variables
2. ✅ Checks database connection
3. ✅ Creates tables if needed
4. ✅ Installs Supervisor (process manager)
5. ✅ Starts **both** processes:
   - **Backend API** (Uvicorn) on port 10000
   - **Celery Worker** (2 concurrent tasks)

---

## 🔍 How It Works:

### Supervisor manages two programs:

```yaml
Program 1: Backend API
  Command: uvicorn backend.main:app --host 0.0.0.0 --port 10000 --workers 2
  Auto-restart: Yes
  Logs: stdout/stderr

Program 2: Celery Worker
  Command: celery -A worker.celery_app worker --loglevel=info --concurrency=2
  Auto-restart: Yes
  Logs: stdout/stderr
```

Both processes run simultaneously and restart automatically if they crash.

---

## ✅ Verify It's Working:

### 1. Check Deployment Logs

Look for these messages:

```
✅ Environment variables verified
✅ Database connection successful
✅ Database ready
📦 Installing supervisor...
✅ Supervisor configuration created
🚀 Starting services with Supervisor...
   - Backend API (Uvicorn on port 10000)
   - Celery Worker (2 concurrent tasks)
```

### 2. Check for Backend Startup:

```
INFO: Started server process [123]
INFO: Waiting for application startup.
INFO: Application startup complete.
INFO: Uvicorn running on http://0.0.0.0:10000
```

### 3. Check for Worker Startup:

```
[2025-11-14 03:15:00,000: INFO/MainProcess] Connected to redis://...
[2025-11-14 03:15:01,000: INFO/MainProcess] celery@hostname ready.
[2025-11-14 03:15:01,000: INFO/MainProcess] 
Registered tasks:
    worker.tasks.cleanup_old_files
    worker.tasks.process_pdf_task
```

### 4. Test Backend API:

```bash
curl https://api.pdf2audiobook.xyz/health
```

Expected:
```json
{
  "status": "healthy",
  "dependencies": {
    "database": "healthy",
    "redis": "healthy",
    "s3": "healthy"
  }
}
```

### 5. Test Worker Processing:

1. Upload a PDF from your frontend
2. Check logs - should see both:
   - API receiving upload request
   - Worker processing the PDF

---

## 📊 Resource Considerations:

### Memory Usage:
- **Backend (Uvicorn):** ~200-300MB
- **Celery Worker:** ~300-500MB
- **Total:** ~500-800MB

**Recommendation:**
- Minimum: **Starter plan** (512MB RAM) - tight but works for light usage
- Recommended: **Standard plan** (2GB RAM) - comfortable for production

### Concurrency:
- Backend: 2 Uvicorn workers
- Celery: 2 concurrent tasks

**For heavier load:**
- Upgrade to Standard plan
- Increase worker concurrency in the script

---

## ⚠️ Limitations:

### Compared to Separate Worker Service:

| Feature | Combined Service | Separate Services |
|---------|-----------------|-------------------|
| **Cost** | $7/month (1 service) | $14/month (2 services) |
| **Scaling** | ❌ Can't scale independently | ✅ Scale each separately |
| **Isolation** | ❌ Share resources | ✅ Independent resources |
| **Monitoring** | ⚠️ Mixed logs | ✅ Separate logs |
| **Debugging** | ⚠️ Harder to isolate issues | ✅ Easier to debug |
| **Reliability** | ⚠️ Both down if one crashes | ✅ Independent failures |

### When Combined Service Works Well:
- ✅ Low to medium traffic (< 1,000 users/day)
- ✅ Small PDF files (< 10MB)
- ✅ Few concurrent uploads (< 5 at once)
- ✅ Budget-conscious MVP/testing

### When You Need Separate Services:
- ❌ High traffic (> 1,000 users/day)
- ❌ Large PDF files (> 20MB)
- ❌ Many concurrent uploads (> 10 at once)
- ❌ Production app with SLA requirements

---

## 🐛 Troubleshooting:

### Issue 1: "supervisor: command not found"

**Cause:** Supervisor failed to install

**Fix:** The script installs it automatically, but if it fails:
```bash
# Add to your requirements.txt:
supervisor>=4.2.5

# Then rebuild
```

### Issue 2: Port Already in Use

**Symptoms:** Backend won't start, port conflict

**Fix:** Render automatically assigns the port via `$PORT` environment variable. The script uses this automatically.

### Issue 3: Worker Not Processing Jobs

**Check Logs For:**
```
celery@hostname ready.
```

**If missing:**
- Verify `REDIS_URL` is set
- Check Redis service is running
- Restart the service

### Issue 4: Out of Memory (OOM)

**Symptoms:** Service crashes randomly

**Cause:** 512MB RAM not enough for both processes

**Fix:**
1. Upgrade to **Standard plan** (2GB RAM)
2. Or reduce concurrency:
   ```bash
   # Edit render-start-with-worker.sh
   # Change from:
   --workers 2  # backend
   --concurrency=2  # worker
   
   # To:
   --workers 1  # backend
   --concurrency=1  # worker
   ```

### Issue 5: Mixed Logs (Hard to Debug)

**Problem:** Backend and worker logs mixed together

**Workaround:**
- Worker logs have `[INFO/MainProcess]` prefix
- Backend logs have `backend.main` prefix
- Use log filtering: `grep "celery" logs.txt`

---

## 📈 Monitoring:

### Check Service Health:

```bash
# API Health
curl https://api.pdf2audiobook.xyz/health

# Check if worker is processing
# Upload a PDF and monitor logs for:
[INFO/ForkPoolWorker-1] Starting PDF processing for job X
```

### Key Metrics to Watch:

1. **Memory Usage** (Render Dashboard → Metrics)
   - Should stay < 80% of available RAM
   - If consistently high, upgrade plan

2. **Response Times**
   - API should respond < 500ms
   - If slow, processes competing for CPU

3. **Job Queue Length**
   - Monitor Redis for queued tasks
   - If queue grows, need separate worker

---

## 🔄 Migration Path:

### When to Split Services:

**Scenario:** Your app is growing, need better performance

**Steps:**
1. Keep current combined service running
2. Create new Background Worker service
3. Update backend start command to: `../render-start-simple.sh`
4. Worker service uses: `celery -A worker.celery_app worker --loglevel=info`
5. Test both services work
6. Delete old combined setup

**Zero downtime migration!**

---

## 💰 Cost Comparison:

### Combined Service (This Guide):
- **1 Web Service** (Starter): $7/month
- **PostgreSQL** (Starter): $7/month
- **Redis** (Starter): $7/month
- **Total:** $21/month

### Separate Services:
- **1 Web Service** (Starter): $7/month
- **1 Background Worker** (Starter): $7/month
- **PostgreSQL** (Starter): $7/month
- **Redis** (Starter): $7/month
- **Total:** $28/month

**Savings:** $7/month with combined service

---

## ✅ Success Checklist:

After deployment, verify:

- [ ] Service deploys successfully
- [ ] Logs show "Starting services with Supervisor"
- [ ] Backend logs show "Uvicorn running on..."
- [ ] Worker logs show "celery@hostname ready"
- [ ] Health endpoint returns 200 OK
- [ ] Database shows "healthy"
- [ ] Redis shows "healthy"
- [ ] Can upload PDF from frontend
- [ ] Worker processes PDF (check logs)
- [ ] Audio file is generated
- [ ] Can download audio file

---

## 🎯 Recommended Setup:

**For MVP/Testing:**
✅ Use combined service with Starter plan ($7/month)
✅ Monitor memory usage
✅ Test with real PDFs

**For Production:**
✅ Split into separate services
✅ Use Standard plans for both
✅ Set up proper monitoring
✅ Configure auto-scaling

---

## 🚀 Quick Start:

1. **Update Start Command:**
   ```bash
   ../render-start-with-worker.sh
   ```

2. **Redeploy Service**

3. **Check Logs** for:
   - ✅ Supervisor started
   - ✅ Backend running
   - ✅ Worker ready

4. **Test Upload** from frontend

5. **Monitor** performance

---

**Last Updated:** 2025-01-27

**Status:** Production-ready for MVP/small-scale apps

**Recommendation:** Start with combined service, split when needed