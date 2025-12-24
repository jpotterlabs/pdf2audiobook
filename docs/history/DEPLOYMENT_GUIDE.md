# 🚀 Deployment Guide: PDF2AudioBook SaaS Platform

This guide covers deploying your PDF2AudioBook platform using the recommended **split architecture**:
- **Frontend (Next.js)** → Vercel
- **Backend + Workers + Databases** → Render

---

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Option 1: Vercel + Render (Recommended)](#option-1-vercel--render-recommended)
4. [Option 2: Railway (All-in-One)](#option-2-railway-all-in-one)
5. [Option 3: Self-Hosted (Docker)](#option-3-self-hosted-docker)
6. [Environment Variables](#environment-variables)
7. [Post-Deployment Setup](#post-deployment-setup)
8. [Monitoring & Maintenance](#monitoring--maintenance)
9. [Troubleshooting](#troubleshooting)

---

## 🏗️ Architecture Overview

### Deployment Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                         USERS                                │
└─────────────────────┬───────────────────────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        │                           │
        ▼                           ▼
┌───────────────┐           ┌──────────────┐
│   VERCEL      │           │   RENDER     │
│  (Frontend)   │◄─────────►│  (Backend)   │
│               │   API     │              │
│  - Next.js    │  Calls    │  - FastAPI   │
│  - React      │           │  - Celery    │
│  - Clerk Auth │           │  - Workers   │
└───────────────┘           └──────┬───────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
                    ▼              ▼              ▼
            ┌──────────┐   ┌──────────┐   ┌──────────┐
            │PostgreSQL│   │  Redis   │   │  AWS S3  │
            │(Database)│   │ (Cache)  │   │(Storage) │
            └──────────┘   └──────────┘   └──────────┘
```

### Why This Architecture?

| Component | Reason |
|-----------|--------|
| **Vercel for Frontend** | ✅ Perfect Next.js support, global CDN, automatic deployments, serverless |
| **Render for Backend** | ✅ Supports long-running processes, workers, managed databases |
| **Split Architecture** | ✅ Independent scaling, better performance, easier debugging |

---

## ✅ Prerequisites

### Required Accounts

1. **GitHub** - Code repository (✅ Already done)
2. **Vercel** - Frontend hosting
3. **Render** - Backend hosting
4. **Clerk** - Authentication
5. **AWS** - S3 file storage
6. **Paddle** - Payment processing (optional for MVP)
7. **OpenAI** - TTS provider (at least one TTS provider required)

### Local Setup Verification

```bash
# Verify your local setup works
cd pdf2audiobook

# Backend
cd backend
python -c "from main import app; print('✅ Backend OK')"

# Frontend
cd ../frontend
npm install
npm run build
```

---

## 🌟 Option 1: Vercel + Render (Recommended)

### Step 1: Deploy Backend to Render

#### 1.1 Create Render Account
- Go to https://render.com
- Sign up with GitHub
- Connect your `pdf2audiobook` repository

#### 1.2 Create PostgreSQL Database

1. **In Render Dashboard:**
   - Click "New +" → "PostgreSQL"
   - **Name:** `pdf2audiobook-db`
   - **Database:** `pdf2audiobook`
   - **User:** `pdf2audiobook_user`
   - **Region:** Choose closest to users (e.g., Oregon, Ohio, Frankfurt)
   - **Plan:** Free (for testing) or Starter ($7/month)

2. **Save Connection Details:**
   - Copy the **Internal Database URL** (for backend)
   - Format: `postgresql://user:password@host:5432/dbname`

#### 1.3 Create Redis Instance

1. **In Render Dashboard:**
   - Click "New +" → "Redis"
   - **Name:** `pdf2audiobook-redis`
   - **Region:** Same as database
   - **Plan:** Free (for testing) or Starter ($7/month)

2. **Save Connection Details:**
   - Copy the **Internal Redis URL**
   - Format: `redis://red-xxxxx:6379`

#### 1.4 Deploy Backend API

1. **In Render Dashboard:**
   - Click "New +" → "Web Service"
   - Connect to `pdf2audiobook` repository
   - **Settings:**
     ```
     Name: pdf2audiobook-api
     Region: Same as database
     Branch: main
     Root Directory: backend
     Runtime: Python 3
     Build Command: ../render-build.sh
     Start Command: ../render-start.sh
     Plan: Starter ($7/month) or higher
     ```

2. **Environment Variables:**
   ```bash
   # Core
   ENVIRONMENT=production
   DEBUG=false
   SECRET_KEY=<generate-256-bit-key>
   
   # Database (from step 1.2)
   DATABASE_URL=<internal-postgres-url>
   
   # Redis (from step 1.3)
   REDIS_URL=<internal-redis-url>
   CELERY_BROKER_URL=<internal-redis-url>
   CELERY_RESULT_BACKEND=<internal-redis-url>
   
   # Clerk Authentication
   CLERK_PEM_PUBLIC_KEY=<your-clerk-public-key>
   CLERK_JWT_ISSUER=<your-clerk-issuer>
   CLERK_JWT_AUDIENCE=<your-clerk-audience>
   
   # AWS S3
   AWS_ACCESS_KEY_ID=<your-aws-key>
   AWS_SECRET_ACCESS_KEY=<your-aws-secret>
   AWS_REGION=us-east-1
   S3_BUCKET_NAME=<your-bucket-name>
   
   # OpenAI (at least one TTS provider required)
   OPENAI_API_KEY=<your-openai-key>
   
   # Paddle (optional for MVP)
   PADDLE_VENDOR_ID=<your-paddle-id>
   PADDLE_VENDOR_AUTH_CODE=<your-paddle-auth>
   PADDLE_ENVIRONMENT=sandbox
   
   # CORS (important!)
   CORS_ALLOW_ORIGINS=https://your-app.vercel.app
   ```

3. **Generate SECRET_KEY:**
   ```bash
   python -c "import secrets; print(secrets.token_urlsafe(32))"
   ```

4. **Deploy:**
   - Click "Create Web Service"
   - Wait for build to complete (~5 minutes)
   - Note your API URL: `https://pdf2audiobook-api.onrender.com`

#### 1.5 Deploy Celery Worker

1. **In Render Dashboard:**
   - Click "New +" → "Background Worker"
   - Connect to `pdf2audiobook` repository
   - **Settings:**
     ```
     Name: pdf2audiobook-worker
     Region: Same as database
     Branch: main
     Root Directory: .
     Runtime: Python 3
     Build Command: pip install -r requirements.txt
     Start Command: celery -A worker.celery_app worker --loglevel=info
     Plan: Starter ($7/month) or higher
     ```

2. **Environment Variables:**
   - Use the **same environment variables** as the Backend API (Step 1.4.2)
   - Copy/paste all environment variables

3. **Deploy:**
   - Click "Create Background Worker"
   - Worker will start processing PDF jobs

#### 1.6 Run Database Migrations

After backend is deployed:

```bash
# Connect to Render shell (or use Render Dashboard > Shell)
# In Render Dashboard: Select your backend service → Shell

cd backend
python -m alembic upgrade head
```

Or add to your `render-start.sh` (already included):
```bash
# Migrations run automatically on startup
```

### Step 2: Deploy Frontend to Vercel

#### 2.1 Create Vercel Account
- Go to https://vercel.com
- Sign up with GitHub
- Import `pdf2audiobook` repository

#### 2.2 Configure Frontend Deployment

1. **In Vercel Dashboard:**
   - Click "Add New..." → "Project"
   - Import `pdf2audiobook` repository
   - **Framework Preset:** Next.js
   - **Root Directory:** `frontend`
   - **Build Command:** `npm run build`
   - **Output Directory:** `.next`

2. **Environment Variables:**
   ```bash
   # Clerk Authentication (Public)
   NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=<your-clerk-publishable-key>
   NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
   NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
   NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/upload
   NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/upload
   
   # Clerk (Private - Server Side)
   CLERK_SECRET_KEY=<your-clerk-secret-key>
   
   # Backend API URL (from Step 1.4)
   NEXT_PUBLIC_API_URL=https://pdf2audiobook-api.onrender.com
   
   # Environment
   NODE_ENV=production
   ```

3. **Deploy:**
   - Click "Deploy"
   - Wait for build (~2-3 minutes)
   - Your frontend URL: `https://your-app.vercel.app`

#### 2.3 Update CORS in Backend

1. Go back to Render Dashboard → Backend API → Environment
2. Update `CORS_ALLOW_ORIGINS`:
   ```bash
   CORS_ALLOW_ORIGINS=https://your-app.vercel.app
   ```
3. Redeploy backend

### Step 3: Configure External Services

#### 3.1 Set Up Clerk Authentication

1. **Create Clerk Application:**
   - Go to https://clerk.com
   - Create new application
   - **Name:** PDF2AudioBook
   - **Authentication:** Email + Social (Google, GitHub)

2. **Configure URLs:**
   - **Home URL:** `https://your-app.vercel.app`
   - **Sign-in URL:** `https://your-app.vercel.app/sign-in`
   - **Sign-up URL:** `https://your-app.vercel.app/sign-up`

3. **Get API Keys:**
   - Go to "API Keys" in Clerk Dashboard
   - Copy **Publishable Key** (for frontend)
   - Copy **Secret Key** (for frontend server-side)
   - Copy **PEM Public Key** (for backend JWT verification)
   - Copy **Issuer** and **Audience** from JWT Template

4. **Update Environment Variables:**
   - Add to Vercel (frontend)
   - Add to Render (backend)

#### 3.2 Set Up AWS S3

1. **Create S3 Bucket:**
   ```bash
   # Using AWS CLI
   aws s3 mb s3://pdf2audiobook-files --region us-east-1
   
   # Enable CORS
   aws s3api put-bucket-cors --bucket pdf2audiobook-files --cors-configuration file://s3-cors.json
   ```

2. **CORS Configuration** (`s3-cors.json`):
   ```json
   {
     "CORSRules": [
       {
         "AllowedOrigins": ["https://your-app.vercel.app"],
         "AllowedMethods": ["GET", "PUT", "POST"],
         "AllowedHeaders": ["*"],
         "MaxAgeSeconds": 3000
       }
     ]
   }
   ```

3. **Create IAM User:**
   - Go to AWS IAM Console
   - Create user: `pdf2audiobook-app`
   - Attach policy: `AmazonS3FullAccess` (or custom restrictive policy)
   - Save Access Key ID and Secret Access Key

4. **Update Environment Variables:**
   - Add AWS credentials to Render (backend + worker)

#### 3.3 Set Up Paddle (Optional)

1. **Create Paddle Account:**
   - Go to https://paddle.com
   - Sign up for Sandbox account

2. **Create Products:**
   - **Pro Subscription:** $29.99/month
   - **Enterprise Subscription:** $99.99/month
   - **Credit Packs:** Various pricing

3. **Configure Webhook:**
   - **Webhook URL:** `https://pdf2audiobook-api.onrender.com/api/v1/webhooks/paddle`
   - **Events:** Subscribe to all transaction and subscription events

4. **Get API Keys:**
   - Vendor ID
   - Vendor Auth Code
   - Public Key (for webhook verification)

5. **Update Environment Variables:**
   - Add to Render (backend)

---

## 🚂 Option 2: Railway (All-in-One)

Railway is simpler if you want everything in one place.

### Step 1: Create Railway Account
- Go to https://railway.app
- Sign up with GitHub
- Connect `pdf2audiobook` repository

### Step 2: Deploy from Template

1. **Create New Project:**
   - Click "New Project"
   - Choose "Deploy from GitHub repo"
   - Select `pdf2audiobook`

2. **Add Services:**

   **PostgreSQL:**
   ```bash
   # Railway automatically provisions
   # DATABASE_URL is auto-injected
   ```

   **Redis:**
   ```bash
   # Add Redis service
   # REDIS_URL is auto-injected
   ```

   **Backend API:**
   ```yaml
   # railway.toml already exists in backend/
   ```

   **Worker:**
   ```bash
   Start Command: celery -A worker.celery_app worker --loglevel=info
   ```

   **Frontend:**
   ```bash
   Build Command: npm run build
   Start Command: npm start
   Root Directory: frontend
   ```

3. **Environment Variables:**
   - Add all variables from Render guide above
   - Railway auto-injects DATABASE_URL and REDIS_URL

### Step 3: Deploy Frontend to Vercel
- Same as Option 1, Step 2
- Point NEXT_PUBLIC_API_URL to Railway backend URL

---

## 🐳 Option 3: Self-Hosted (Docker)

For complete control, deploy on your own VPS.

### Requirements
- VPS with 4GB+ RAM (DigitalOcean, Linode, AWS EC2)
- Docker & Docker Compose installed
- Domain name with DNS configured

### Deployment

```bash
# On your VPS
git clone https://github.com/cdarwin7/pdf2audiobook.git
cd pdf2audiobook

# Create .env file
cp .env.example .env
nano .env  # Add all environment variables

# Deploy
docker-compose up -d

# Check logs
docker-compose logs -f

# Run migrations
docker-compose exec backend alembic upgrade head
```

### Configure Nginx (Reverse Proxy)

```nginx
# /etc/nginx/sites-available/pdf2audiobook
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### SSL with Let's Encrypt

```bash
sudo certbot --nginx -d yourdomain.com -d api.yourdomain.com
```

---

## 🔐 Environment Variables

### Complete Environment Variable List

#### Backend (Render/Railway)

```bash
# === CORE SETTINGS ===
ENVIRONMENT=production
DEBUG=false
SECRET_KEY=<generate-with-secrets-token-urlsafe-32>
LOG_LEVEL=WARNING

# === DATABASE ===
DATABASE_URL=postgresql://user:pass@host:5432/dbname

# === REDIS/CELERY ===
REDIS_URL=redis://host:6379/0
CELERY_BROKER_URL=redis://host:6379/0
CELERY_RESULT_BACKEND=redis://host:6379/0

# === CLERK AUTHENTICATION ===
CLERK_PEM_PUBLIC_KEY=-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----
CLERK_JWT_ISSUER=https://your-clerk-id.clerk.accounts.dev
CLERK_JWT_AUDIENCE=https://your-clerk-id.clerk.accounts.dev

# === AWS S3 ===
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_REGION=us-east-1
S3_BUCKET_NAME=pdf2audiobook-files

# === TTS PROVIDERS (at least one required) ===
OPENAI_API_KEY=sk-...
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json  # Optional
AZURE_SPEECH_KEY=...  # Optional
AZURE_SPEECH_REGION=eastus  # Optional
ELEVEN_LABS_API_KEY=...  # Optional

# === PADDLE PAYMENTS (optional) ===
PADDLE_VENDOR_ID=12345
PADDLE_VENDOR_AUTH_CODE=...
PADDLE_PUBLIC_KEY=...
PADDLE_ENVIRONMENT=sandbox  # or production

# === CORS ===
CORS_ALLOW_ORIGINS=https://your-app.vercel.app,https://www.yourdomain.com

# === FILE UPLOAD LIMITS ===
MAX_FILE_SIZE_MB=50
ALLOWED_FILE_TYPES=application/pdf

# === RATE LIMITING ===
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW_MINUTES=1
```

#### Frontend (Vercel)

```bash
# === CLERK (PUBLIC) ===
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/upload
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/upload

# === CLERK (PRIVATE) ===
CLERK_SECRET_KEY=sk_test_...

# === API ===
NEXT_PUBLIC_API_URL=https://pdf2audiobook-api.onrender.com

# === ENVIRONMENT ===
NODE_ENV=production
```

### How to Generate SECRET_KEY

```bash
# Python
python -c "import secrets; print(secrets.token_urlsafe(32))"

# OpenSSL
openssl rand -base64 32

# Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

---

## ✅ Post-Deployment Setup

### 1. Verify Deployments

#### Check Backend Health
```bash
curl https://pdf2audiobook-api.onrender.com/health

# Expected response:
{
  "status": "healthy",
  "dependencies": {
    "database": "healthy",
    "redis": "healthy",
    "s3": "healthy"
  }
}
```

#### Check Frontend
```bash
curl https://your-app.vercel.app

# Should return HTML
```

### 2. Test API Endpoints

```bash
# Get API documentation
open https://pdf2audiobook-api.onrender.com/docs

# Test authentication (requires Clerk token)
curl -X GET https://pdf2audiobook-api.onrender.com/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 3. Run Database Migrations

```bash
# If not run automatically
# In Render Shell:
cd backend
python -m alembic upgrade head

# Verify tables created
python -c "from app.core.database import engine; from sqlalchemy import inspect; print(inspect(engine).get_table_names())"
```

### 4. Create Test User

```bash
# Sign up through frontend
open https://your-app.vercel.app/sign-up

# Or use Clerk Dashboard to create test users
```

### 5. Test PDF Upload

1. Go to `https://your-app.vercel.app/upload`
2. Upload a test PDF
3. Check Render logs to verify worker processing:
   ```bash
   # In Render Dashboard → Worker → Logs
   ```

### 6. Monitor Worker Status

```bash
# In Render Shell (Worker):
celery -A worker.celery_app inspect active
celery -A worker.celery_app inspect stats
```

---

## 📊 Monitoring & Maintenance

### Health Checks

Add to your monitoring tool (UptimeRobot, Pingdom, etc.):
- **Backend:** `https://pdf2audiobook-api.onrender.com/health`
- **Frontend:** `https://your-app.vercel.app`

### Log Monitoring

**Render:**
- Dashboard → Services → Logs
- Real-time log streaming

**Vercel:**
- Dashboard → Deployments → Function Logs

### Performance Monitoring

**Recommended Tools:**
- **Sentry** - Error tracking
- **LogRocket** - Session replay
- **New Relic** - APM
- **DataDog** - Infrastructure monitoring

### Database Backups

**Render:**
- Automatic daily backups on Starter plan+
- Manual backups: Dashboard → Database → Backups

**Railway:**
- Automatic backups
- Point-in-time recovery

### Cost Estimation

#### Render Free Tier (Good for Testing)
- ✅ PostgreSQL: Free (1GB, auto-sleep)
- ✅ Redis: Free (25MB)
- ❌ Web Service: Free (750 hours/month, cold starts)
- ❌ Worker: Not available on free tier

#### Render Paid (Recommended for Production)
- PostgreSQL Starter: $7/month (256MB RAM)
- Redis Starter: $7/month (25MB)
- Web Service Starter: $7/month (512MB RAM)
- Worker Starter: $7/month (512MB RAM)
- **Total: ~$28/month**

#### Vercel (Frontend)
- Hobby (Free): 100GB bandwidth, unlimited deployments
- Pro: $20/month (team features)

#### AWS S3
- ~$0.023/GB storage
- ~$0.09/GB transfer
- Estimate: $5-20/month depending on usage

**Total Estimated Cost: $28-50/month** (production-ready)

---

## 🔧 Troubleshooting

### Common Issues

#### 1. CORS Errors

**Symptom:** Frontend can't connect to backend
```
Access to fetch at '...' has been blocked by CORS policy
```

**Solution:**
```bash
# In Render, update CORS_ALLOW_ORIGINS
CORS_ALLOW_ORIGINS=https://your-app.vercel.app

# Redeploy backend
```

#### 2. Database Connection Failed

**Symptom:** Backend health check shows database unhealthy

**Solution:**
```bash
# Verify DATABASE_URL is correct
# Check if database is running in Render dashboard
# Verify IP allowlist if using external database
```

#### 3. Celery Worker Not Processing

**Symptom:** Jobs stuck in "pending" status

**Solution:**
```bash
# Check worker logs in Render
# Verify REDIS_URL matches between backend and worker
# Restart worker service
```

#### 4. File Upload Fails

**Symptom:** 403 or 500 error on file upload

**Solution:**
```bash
# Verify AWS credentials are correct
# Check S3 bucket CORS configuration
# Verify S3 bucket exists and is in correct region
# Check backend logs for detailed error
```

#### 5. Authentication Not Working

**Symptom:** "Unauthorized" errors

**Solution:**
```bash
# Verify Clerk keys are correct in both frontend and backend
# Check CLERK_PEM_PUBLIC_KEY format (must include \n for newlines)
# Verify JWT issuer and audience match Clerk dashboard
```

#### 6. Cold Starts on Free Tier

**Symptom:** First request takes 30+ seconds

**Solution:**
- Upgrade to paid plan ($7/month)
- Or use a cron job to ping your service every 10 minutes:
```bash
# Use cron-job.org or similar
curl https://pdf2audiobook-api.onrender.com/health
```

### Debug Mode

Enable debug logging temporarily:

```bash
# In Render environment variables
DEBUG=true
LOG_LEVEL=DEBUG

# Redeploy
# Check logs for detailed information
# Don't forget to disable afterwards!
```

### Getting Help

1. **Check Logs:**
   - Render: Dashboard → Service → Logs
   - Vercel: Dashboard → Deployment → Function Logs

2. **Test Locally:**
   ```bash
   docker-compose up
   # Replicate production environment
   ```

3. **GitHub Issues:**
   - https://github.com/cdarwin7/pdf2audiobook/issues

4. **Platform Support:**
   - Render: https://render.com/docs
   - Vercel: https://vercel.com/docs
   - Railway: https://docs.railway.app

---

## 🎉 Deployment Checklist

### Pre-Deployment
- [ ] GitHub repository is up to date
- [ ] All environment variables documented
- [ ] External services configured (Clerk, AWS, Paddle)
- [ ] Database migrations tested locally
- [ ] Frontend builds successfully
- [ ] Backend tests pass

### Backend Deployment (Render)
- [ ] PostgreSQL database created
- [ ] Redis instance created
- [ ] Backend API deployed and healthy
- [ ] Celery worker deployed and running
- [ ] Database migrations run successfully
- [ ] Environment variables configured
- [ ] CORS configured for frontend domain

### Frontend Deployment (Vercel)
- [ ] Project imported from GitHub
- [ ] Environment variables configured
- [ ] Custom domain configured (optional)
- [ ] SSL certificate active
- [ ] API endpoint configured correctly

### External Services
- [ ] Clerk authentication working
- [ ] AWS S3 file uploads working
- [ ] Paddle webhooks configured (optional)
- [ ] OpenAI API key working

### Testing
- [ ] Health check endpoints return healthy
- [ ] User can sign up and log in
- [ ] PDF upload works
- [ ] PDF processing completes successfully
- [ ] Audio file downloads successfully
- [ ] Payment flow works (if implemented)

### Monitoring
- [ ] Uptime monitoring configured
- [ ] Error tracking set up (Sentry)
- [ ] Log aggregation working
- [ ] Backup strategy in place

### Documentation
- [ ] README updated with production URLs
- [ ] Environment variables documented
- [ ] Deployment process documented
- [ ] Runbook created for common issues

---

## 🚀 Next Steps After Deployment

1. **Custom Domain:**
   - Purchase domain (e.g., pdf2audiobook.com)
   - Configure DNS in Vercel
   - Update CORS_ALLOW_ORIGINS

2. **Monitoring:**
   - Set up Sentry for error tracking
   - Configure UptimeRobot for uptime monitoring
   - Set up log aggregation

3. **Performance:**
   - Enable Vercel Analytics
   - Configure CDN for assets
   - Optimize database queries
   - Add Redis caching

4. **CI/CD:**
   - Set up GitHub Actions
   - Automated testing on PR
   - Automated deployment on merge

5. **Scale:**
   - Upgrade Render plans as needed
   - Add more worker instances
   - Implement queue monitoring
   - Set up autoscaling

---

**Deployment Guide Last Updated:** 2025-01-27

**Need Help?** Open an issue at https://github.com/cdarwin7/pdf2audiobook/issues