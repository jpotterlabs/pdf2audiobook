from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from typing import List, Optional
from sqlalchemy.orm import Session
from app.core.database import get_db

from app.services.payment import PaymentService, PaddleCheckoutRequest
from app.schemas import Job, Product, User
from app.services.auth import get_current_user
from app.models import User, Product as ProductModel
from app.core.database import get_db

router = APIRouter()


@router.get(
    "/products",
    response_model=List[Product],
    summary="List All Available Products",
    description="Retrieves a list of all active products and subscription plans.",
)
async def get_products(db: Session = Depends(get_db)):
    """
    Fetches all active products available for purchase.
    """
    return db.query(ProductModel).filter(ProductModel.is_active == True).all()


class CheckoutURLRequest(BaseModel):
    product_id: int = Field(
        ..., json_schema_extra={"example": 1}, description="The internal ID of the product to purchase."
    )


class CheckoutURLResponse(BaseModel):
    checkout_url: str = Field(
        ...,
        json_schema_extra={"example": "https://sandbox-vendors.paddle.com/checkout/user/123/hash?redirect_url=..."},
        description="The generated Paddle checkout URL.",
    )


@router.post(
    "/checkout-url",
    response_model=CheckoutURLResponse,
    summary="Generate a Payment Checkout URL",
    description="Creates a unique Paddle checkout URL for a specific product and the currently authenticated user.",
)
async def create_checkout_url(
    request: CheckoutURLRequest, current_user: User = Depends(get_current_user)
):
    """
    Generates a Paddle checkout URL for the authenticated user to purchase a product.

    - **product_id**: The ID of the product (subscription or credit pack) to buy.
    """
    payment_service = PaymentService()
    checkout_request = PaddleCheckoutRequest(
        product_id=request.product_id, customer_email=current_user.email
    )

    checkout_url = payment_service.generate_checkout_url(checkout_request)
    return CheckoutURLResponse(checkout_url=checkout_url)
