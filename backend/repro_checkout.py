
import sys
import os
# Add current directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.config import settings
from paddle_billing import Client, Environment, Options
from paddle_billing.Resources.Prices.Operations import ListPrices
from loguru import logger

def test_paddle_listing():
    api_key = settings.PADDLE_API_KEY or "d80a1337"
    print(f"Testing Paddle listing with API Key: {api_key[:5]}...")
    
    env = Environment.SANDBOX if settings.PADDLE_ENVIRONMENT == "sandbox" else Environment.PRODUCTION
    client = Client(api_key, options=Options(env))

    try:
        print("Attempting client.prices.list(ListPrices())...")
        # This is the exact line from payment.py
        all_prices = list(client.prices.list(ListPrices()))
        print(f"Success! Found {len(all_prices)} prices.")
        
        # Simulate the filtering
        price_id = "pri_01jk2..." # Dummy
        prices = [p for p in all_prices if p.product_id == price_id]
        print("Filtering logic works.")
        
    except Exception as e:
        print(f"CRASHED: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_paddle_listing()
