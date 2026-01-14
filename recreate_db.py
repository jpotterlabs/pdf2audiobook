import sys
import os

# Add backend directory to sys.path
sys.path.append(os.path.join(os.path.dirname(__file__), "backend"))

from app.core.database import engine, Base
from app.models import Job, User  # Import models so they are registered in Base

def recreate_db():
    print(f"Connecting to database: {engine.url}")
    
    # SQLite-specific cleanup
    if engine.url.drivername == "sqlite":
        db_path = engine.url.database
        if db_path and os.path.exists(db_path):
            print(f"Removing existing SQLite database: {db_path}")
            try:
                os.remove(db_path)
            except Exception as e:
                print(f"Warning: Could not remove {db_path}: {e}")

    print("Creating database tables...")
    Base.metadata.create_all(bind=engine)
    print("Tables created successfully!")

if __name__ == "__main__":
    recreate_db()
