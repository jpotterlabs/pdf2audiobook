# 🔧 Render Backend Deployment Fix

## Issue: Alembic Path Error

**Error Message:**
```
ERROR: alembic.ini not found in /opt/render/project/src/backend
```

**Root Cause:** Render sets the working directory to `backend/`, but `alembic.ini` is in the project root.

---

## ✅ Solution: Use the Simplified Start Script

### Option 1: Use render-start-simple.sh (RECOMMENDED)

This script **skips Alembic** and creates tables directly using SQLAlchemy, which is simpler and more reliable for Render.

#### Update Your Render Backend Service:

1. **Go to Render Dashboard** → Your Backend Service → Settings

2. **Update Start Command:**
   ```bash
   ../render-start-simple.sh
   ```

3. **Save Changes** → Click "Manual Deploy" → "Deploy latest commit"

#### Why This Works:
- ✅ No Alembic path issues
- ✅ Creates tables automatically using SQLAlchemy
- ✅ Checks if tables exist before creating
- ✅ Simpler and more reliable
- ✅ Better error messages

---

### Option 2: Fix the Original Script (Alternative)

If you prefer to use Alembic migrations, use the updated `render-start.sh`:

#### Update Your Render Backend Service:

1. **Go to Render Dashboard** → Your Backend Service → Settings

2. **Verify Start Command:**
   ```bash
   ../render-start.sh
   ```

3. **The updated script now:**
   - Looks for `alembic.ini` in parent directory (`../alembic.ini`)
   - Changes to parent directory before running migrations
   - Changes back to backend directory before starting app

4. **Save Changes** → Click "Manual Deploy" → "Deploy latest commit"

---

## 🧪 Verification Steps

After deploying with either script:

### 1. Check Deployment Logs

Look for these success messages:

**With render-start-simple.sh:**
```
✅ Environment variables verified
✅ Database connection successful
✅ Database tables already exist (5 tables)
   Tables: users, jobs, products, subscriptions, transactions
✅ Database ready
🚀 Starting FastAPI application...
```

**With render-start.sh:**
```
Database tables already exist with correct schema, skipping migrations...
Starting FastAPI application...
```

### 2. Test Health Endpoint

```bash
curl https://your-backend-name.onrender.com/health

# Expected response:
{
  "status": "healthy",
  "dependencies": {
    "database": "healthy",
    "redis": "healthy",
    "s3": "healthy" or "not_configured"
  }
}
```

### 3. Check API Documentation

Visit: `https://your-backend-name.onrender.com/docs`

Should see interactive Swagger documentation.

---

## 🔍 Troubleshooting

### Issue: "Database connection failed"

**Check:**
- Is `DATABASE_URL` set in Render environment variables?
- Is PostgreSQL service running?
- Verify database connection string format

**Fix:**
```bash
# In Render Dashboard → Backend → Environment
# DATABASE_URL should be auto-injected by Render PostgreSQL
# If not, add it manually from PostgreSQL service details
```

### Issue: "Redis connection failed"

**Check:**
- Is `REDIS_URL` set in Render environment variables?
- Is Redis service running?

**Fix:**
```bash
# In Render Dashboard → Backend → Environment
# REDIS_URL should be auto-injected by Render Redis
# Also set:
CELERY_BROKER_URL=$REDIS_URL
CELERY_RESULT_BACKEND=$REDIS_URL
```

### Issue: "SECRET_KEY is not set"

**Fix:**
```bash
# Generate a secure secret key:
python -c "import secrets; print(secrets.token_urlsafe(32))"

# Add to Render environment variables:
SECRET_KEY=<generated-key>
```

### Issue: Still seeing alembic errors

**Solution:** Switch to `render-start-simple.sh`:
1. Go to Render Dashboard → Backend Service → Settings
2. Change Start Command to: `../render-start-simple.sh`
3. Redeploy

---

## 📋 Complete Backend Configuration

### Render Service Settings:

```yaml
Name: pdf2audiobook-api
Environment: Python 3
Root Directory: backend
Branch: main

Build Command:
  ../render-build.sh

Start Command:
  ../render-start-simple.sh    # RECOMMENDED
  # OR
  ../render-start.sh            # If you want Alembic migrations

Instance Type: Starter ($7/month) or Free
```

### Required Environment Variables:

```bash
# Core
ENVIRONMENT=production
DEBUG=false
SECRET_KEY=<generate-with-secrets.token-urlsafe-32>
LOG_LEVEL=WARNING

# Database (auto-injected by Render PostgreSQL)
DATABASE_URL=postgresql://...

# Redis (auto-injected by Render Redis)
REDIS_URL=redis://...
CELERY_BROKER_URL=${REDIS_URL}
CELERY_RESULT_BACKEND=${REDIS_URL}

# Clerk Authentication
CLERK_PEM_PUBLIC_KEY=-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----
CLERK_JWT_ISSUER=https://your-app.clerk.accounts.dev
CLERK_JWT_AUDIENCE=https://your-app.clerk.accounts.dev

# AWS S3
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=us-east-1
S3_BUCKET_NAME=your-bucket-name

# OpenAI (or other TTS provider)
OPENAI_API_KEY=sk-...

# CORS (add your frontend URL)
CORS_ALLOW_ORIGINS=https://your-frontend.onrender.com

# Optional: Paddle
PADDLE_VENDOR_ID=12345
PADDLE_VENDOR_AUTH_CODE=...
PADDLE_ENVIRONMENT=sandbox
```

---

## ✅ Success Checklist

After deployment, verify:

- [ ] Deployment completes without errors
- [ ] Logs show "✅ Database ready"
- [ ] Logs show "🚀 Starting FastAPI application"
- [ ] Health endpoint returns 200 OK
- [ ] API docs accessible at /docs
- [ ] Database shows "healthy" in health check
- [ ] Redis shows "healthy" in health check
- [ ] No critical errors in last 10 minutes of logs

---

## 🚀 Next Steps

Once backend is working:

1. **Test Frontend Connection:**
   - Visit your frontend URL
   - Try to sign up/log in
   - Upload a test PDF

2. **Check Worker Logs:**
   - Verify worker picks up jobs
   - Monitor processing progress

3. **Monitor Performance:**
   - Check response times
   - Monitor memory usage
   - Watch for errors

---

## 📞 Still Having Issues?

### Quick Debug Commands:

```bash
# Check which files exist in deployment
# In Render Shell:
ls -la /opt/render/project/src/
ls -la /opt/render/project/src/backend/

# Test database connection manually
python3 -c "from app.core.database import engine; engine.connect()"

# Check environment variables
env | grep -E '(DATABASE_URL|REDIS_URL|SECRET_KEY)'
```

### Get Help:

1. Check Render logs in dashboard
2. Use Render Shell for live debugging
3. Review environment variables
4. Check GitHub Issues: https://github.com/cdarwin7/pdf2audiobook/issues

---

**Last Updated:** 2025-01-27  
**Recommended Solution:** Use `render-start-simple.sh`
