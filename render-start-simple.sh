#!/bin/bash
set -e

echo "🚀 Starting PDF2AudioBook backend..."
echo "Working directory: $(pwd)"

# Set Python path
export PYTHONPATH="${PYTHONPATH}:/opt/render/project/src:/opt/render/project/src/backend"

# Verify required environment variables
if [ -z "$DATABASE_URL" ]; then
    echo "❌ ERROR: DATABASE_URL is not set"
    exit 1
fi

if [ -z "$REDIS_URL" ]; then
    echo "❌ ERROR: REDIS_URL is not set"
    exit 1
fi

if [ -z "$SECRET_KEY" ]; then
    echo "❌ ERROR: SECRET_KEY is not set"
    exit 1
fi

echo "✅ Environment variables verified"
echo "DATABASE_URL: ${DATABASE_URL:0:30}..."
echo "REDIS_URL: ${REDIS_URL:0:30}..."

# Check database connection
echo "🔍 Checking database connection..."
python3 -c "
from sqlalchemy import create_engine, text
import sys
import os

try:
    engine = create_engine('$DATABASE_URL')
    with engine.connect() as conn:
        conn.execute(text('SELECT 1'))
    print('✅ Database connection successful')
except Exception as e:
    print(f'❌ Database connection failed: {e}')
    sys.exit(1)
"

# Create tables if they don't exist (without Alembic)
echo "🔍 Checking if database tables exist..."
python3 << 'EOF'
import sys
import os

# Add backend to path
sys.path.insert(0, '/opt/render/project/src/backend')
sys.path.insert(0, '/opt/render/project/src')

from app.core.database import engine
from app.models import Base
from sqlalchemy import inspect

try:
    inspector = inspect(engine)
    tables = inspector.get_table_names()

    if 'users' in tables:
        print(f"✅ Database tables already exist ({len(tables)} tables)")
        print(f"   Tables: {', '.join(tables[:5])}...")
    else:
        print("📦 Creating database tables...")
        Base.metadata.create_all(bind=engine)

        # Verify creation
        inspector = inspect(engine)
        tables = inspector.get_table_names()
        print(f"✅ Created {len(tables)} tables successfully")
        print(f"   Tables: {', '.join(tables)}")

except Exception as e:
    print(f"❌ Error setting up database: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
EOF

if [ $? -ne 0 ]; then
    echo "❌ Database setup failed"
    exit 1
fi

echo "✅ Database ready"

# Start the application
echo "🚀 Starting FastAPI application..."
echo "   Host: 0.0.0.0"
echo "   Port: ${PORT:-8000}"
echo "   Workers: 2"
echo ""

# Use the PORT environment variable that Render provides
exec uvicorn backend.main:app --host 0.0.0.0 --port ${PORT:-8000} --workers 2
