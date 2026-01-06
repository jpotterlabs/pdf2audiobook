import os
import sys
# Add current directory to path so we can import from app
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.config import settings
from app.core.database import SessionLocal
from app.models import Product
from loguru import logger
from paddle_billing import Client, Environment, Options
from paddle_billing.Resources.Products.Operations import ListProducts

def sync_products():
    """
    Fetches active products from Paddle and syncs them to the local database.
    """
    db = SessionLocal()
    
    # Initialize Paddle Client
    env = Environment.SANDBOX if settings.PADDLE_ENVIRONMENT == "sandbox" else Environment.PRODUCTION
    if not settings.PADDLE_API_KEY:
        logger.error("PADDLE_API_KEY is missing! Cannot sync.")
        return

    client = Client(settings.PADDLE_API_KEY, options=Options(env))
    logger.info(f"Syncing products from Paddle ({settings.PADDLE_ENVIRONMENT})...")

    try:
        # Fetch all products (filtering locally if needed, or using correct SDK params)
        paddle_products = list(client.products.list(ListProducts()))
        
        if not paddle_products:
            logger.warning("No active products found in Paddle!")
            return

        for pp in paddle_products:
            try:
                logger.info(f"Processing Paddle Product: {pp.name} (ID: {pp.id})")
                
                # Determine tier and type based on name or custom data
                tier = "free"
                ptype = "one_time"
                price = 0.0
                credits = 0
                
                name_lower = pp.name.lower()
                if "discover" in name_lower:
                    tier = "free"
                    ptype = "one_time"
                elif "research" in name_lower:
                    tier = "pro"
                    ptype = "subscription"
                    price = 9.99
                    credits = 3
                elif "intelligence" in name_lower:
                    tier = "enterprise"
                    ptype = "subscription"
                    price = 19.99
                    credits = 7
                else:
                     logger.warning(f"Skipping unknown product: {pp.name}")
                     continue

                # Upsert into DB: Prioritise looking up by paddle_product_id to avoid IntegrityErrors
                product = db.query(Product).filter(Product.paddle_product_id == pp.id).first()
                
                if not product:
                    # If not found by ID, check if we have a stale record for this tier
                    product = db.query(Product).filter(Product.subscription_tier == tier).first()
                    if product:
                        logger.info(f"Migrating local product tier '{tier}' to new Paddle ID: {pp.id}")
                    else:
                        logger.info(f"Creating new local product records for tier: {tier}")
                        product = Product(subscription_tier=tier)
                        db.add(product)

                # Update all fields
                product.paddle_product_id = pp.id
                product.name = pp.name
                product.description = pp.description or ""
                product.price = price
                product.currency = "USD"
                product.credits_included = credits
                product.type = ptype
                product.is_active = True
                
                db.flush() # Check for errors locally
                logger.info(f"Synced {tier} tier product: {pp.id}")
                
            except Exception as item_err:
                logger.error(f"Failed to sync product '{pp.name}': {item_err}")
                db.rollback()
                # Continue to next product
                continue
            
        db.commit()
        logger.info("Product sync completed successfully!")

    except Exception as e:
        logger.error(f"Critical failure in product sync: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    sync_products()
