# Database Migration Fix

## Problem

When attempting to upload a PDF, the application returned a 500 error with the message:

```
relation "users" does not exist
```

This indicated that the database tables were never created, meaning Alembic migrations failed to run during deployment.

## Root Cause

The `render-start.sh` script was attempting to run migrations, but Alembic couldn't find the migration scripts. The error in the logs showed:

```
FAILED: No 'script_location' key found in configuration.
Database migration failed - this might be normal if tables already exist
Continuing with application startup...
```

The issue was that the script was trying to run Alembic from the wrong directory. The script was:
1. Starting in `/opt/render/project/src/backend` (because `rootDir: ./backend`)
2. Setting `ALEMBIC_CONFIG=../alembic.ini`
3. Running `cd .. && alembic upgrade head`

However, Alembic needs to run from the directory where `alembic.ini` is located (the project root), not from a subdirectory.

## Solution

### Updated `render-start.sh`

The script was simplified to:

1. Check if tables already exist (skip migrations if they do)
2. If tables don't exist, change to the parent directory (project root)
3. Run `alembic upgrade head` from the correct location
4. Change back to the backend directory
5. Start the application

Key changes:
```bash
# Change to parent directory where alembic.ini is located
cd ..

# Run migrations from the parent directory
alembic upgrade head

# Change back to backend directory
cd backend
```

### Why This Works

- `alembic.ini` specifies `script_location = alembic`
- This is a relative path from where `alembic.ini` is located
- When we run Alembic from the project root, it can find the `alembic/` directory
- The migrations then run successfully and create all necessary database tables

## Verification

After the fix is deployed, you can verify migrations ran by checking:

1. **Application Logs**: Look for `Database migrations completed successfully`
2. **Upload Test**: Try uploading a PDF - it should work without the "users does not exist" error
3. **Database Query**: Connect to the database and run:
   ```sql
   SELECT tablename FROM pg_tables WHERE schemaname = 'public';
   ```
   You should see tables like `users`, `jobs`, `products`, `subscriptions`, etc.

## Manual Migration Script

A standalone migration script is available at `run-migrations.sh` for manual execution if needed:

```bash
# From your local machine with DATABASE_URL set
export DATABASE_URL="postgresql://..."
./run-migrations.sh
```

This script will:
- Check if DATABASE_URL is set
- Verify alembic.ini exists
- Show current database state
- Ask for confirmation before running migrations
- Run migrations and verify success

## Files Modified

- `render-start.sh` - Simplified migration logic and fixed directory handling
- `run-migrations.sh` - New script for manual migration execution (created)
- `MIGRATION_FIX.md` - This documentation

## Next Steps

1. Wait for the new deployment to complete (2-3 minutes)
2. Check the deployment logs for "Database migrations completed successfully"
3. Test PDF upload functionality
4. Monitor for any remaining errors

## Deployment Status

Commit: `c7c9ffe` - "Fix: Simplify migrations script and run from correct directory"

Expected behavior:
- First deployment: Migrations run, tables created
- Subsequent deployments: Tables exist check passes, migrations skipped