#!/bin/bash
set -e

export PYTHONPATH="${PYTHONPATH}:backend"

echo "Starting PDF2AudioBook deployment..."

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
    echo "ERROR: DATABASE_URL environment variable is not set"
    exit 1
fi

# Ensure we are in the project root (where alembic.ini is)
if [ -f "../alembic.ini" ]; then
    echo "Changing to project root directory..."
    cd ..
fi

echo "Current working directory: $(pwd)"
export PYTHONPATH=$PYTHONPATH:$(pwd)

# Verify Alembic configuration exists
if [ ! -f "alembic.ini" ]; then
    echo "ERROR: alembic.ini not found in $(pwd)"
    exit 1
fi

echo "DATABASE_URL is set, proceeding with migrations..."
echo "DATABASE_URL: ${DATABASE_URL:0:20}..."

# Check if we need to run migrations
    # Run migrations
    echo "Running database migrations..."
    # Clean up any existing ENUM types that might have been created from failed migrations if needed
    # (Optional: keep if you suspect ENUM issues, otherwise safe to remove if handled by alembic)

    echo "Running: alembic upgrade head"
    alembic upgrade head

    if [ $? -eq 0 ]; then
        echo "Database migrations completed successfully"
    else
        echo "ERROR: Database migration failed"
        echo "This is a critical error - the application cannot start without database tables"
        exit 1
    fi

# Start the application
echo "Starting FastAPI application..."
# Use 1 worker to fit within Render's 512MB memory limit
exec uv run uvicorn backend.main:app --host 0.0.0.0 --port $PORT --workers 1
