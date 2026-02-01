"""
API Service - Microservice 1
Receives email data via REST API, validates token and data, then publishes to SQS
"""

import os
import logging
import json
from typing import Optional
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field, ValidationError
import boto3
from botocore.exceptions import ClientError
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Email API Service",
    description="REST API service for receiving and processing email data",
    version="1.0.0"
)

# Prometheus metrics
REQUEST_COUNT = Counter(
    'api_requests_total',
    'Total number of API requests',
    ['method', 'endpoint', 'status']
)

REQUEST_DURATION = Histogram(
    'api_request_duration_seconds',
    'API request duration in seconds',
    ['method', 'endpoint']
)

VALIDATION_ERROR_COUNT = Counter(
    'api_validation_errors_total',
    'Total number of validation errors',
    ['error_type']
)

# AWS clients
sqs_client = boto3.client('sqs', region_name=os.getenv('AWS_REGION', 'us-west-1'))
ssm_client = boto3.client('ssm', region_name=os.getenv('AWS_REGION', 'us-west-1'))

# Environment variables
SQS_QUEUE_URL = os.getenv('SQS_QUEUE_URL')
SSM_TOKEN_PARAMETER = os.getenv('SSM_TOKEN_PARAMETER', '/devops-exam/prod/api/token')
AWS_REGION = os.getenv('AWS_REGION', 'us-west-1')

# Cache for SSM auth value (refresh every 5 minutes); no secrets in code
_auth_cache = None
_auth_cache_time = 0
AUTH_CACHE_TTL = 300  # 5 minutes


class EmailData(BaseModel):
    """Email data model with validation"""
    email_subject: str = Field(..., min_length=1, description="Email subject")
    email_sender: str = Field(..., min_length=1, description="Email sender")
    email_timestamp: str = Field(..., min_length=1, description="Email timestamp")
    email_content: str = Field(..., min_length=1, description="Email content")


class EmailRequest(BaseModel):
    """Request model for email API"""
    data: EmailData
    token: str = Field(..., min_length=1, description="Auth value (must match SSM)")


def get_token_from_ssm() -> Optional[str]:
    """
    Retrieve auth value from SSM Parameter Store with caching (value set in AWS Console/CLI).
    """
    global _auth_cache, _auth_cache_time
    import time

    current_time = time.time()

    if _auth_cache and (current_time - _auth_cache_time) < AUTH_CACHE_TTL:
        return _auth_cache

    try:
        logger.info(f"Fetching auth value from SSM: {SSM_TOKEN_PARAMETER}")
        response = ssm_client.get_parameter(
            Name=SSM_TOKEN_PARAMETER,
            WithDecryption=True
        )
        _auth_cache = response['Parameter']['Value']
        _auth_cache_time = current_time
        logger.info("Auth value retrieved from SSM")
        return _auth_cache
    except ClientError as e:
        logger.error(f"Error retrieving auth value from SSM: {e}")
        raise HTTPException(
            status_code=500,
            detail="Failed to retrieve authentication value"
        )


def validate_token(token: str) -> bool:
    """
    Validate the provided value against SSM Parameter Store (no secrets in code).
    """
    try:
        expected = get_token_from_ssm()
        return token == expected
    except Exception as e:
        logger.error(f"Auth validation error: {e}")
        return False


def validate_email_data(data: EmailData) -> tuple[bool, Optional[str]]:
    """
    Validate that email data has all required fields
    Returns (is_valid, error_message)
    """
    required_fields = ['email_subject', 'email_sender', 'email_timestamp', 'email_content']
    data_dict = data.dict()
    
    missing_fields = []
    for field in required_fields:
        if field not in data_dict or not data_dict[field] or not str(data_dict[field]).strip():
            missing_fields.append(field)
    
    if missing_fields:
        return False, f"Missing or empty required fields: {', '.join(missing_fields)}"
    
    return True, None


def publish_to_sqs(data: EmailData) -> bool:
    """
    Publish email data to SQS queue
    """
    if not SQS_QUEUE_URL:
        logger.error("SQS_QUEUE_URL not configured")
        return False
    
    try:
        message_body = json.dumps(data.dict())
        response = sqs_client.send_message(
            QueueUrl=SQS_QUEUE_URL,
            MessageBody=message_body,
            MessageAttributes={
                'email_sender': {
                    'StringValue': data.email_sender,
                    'DataType': 'String'
                },
                'email_subject': {
                    'StringValue': data.email_subject,
                    'DataType': 'String'
                }
            }
        )
        logger.info(f"Message published to SQS: {response['MessageId']}")
        return True
    except ClientError as e:
        logger.error(f"Error publishing to SQS: {e}")
        return False


@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    """Middleware for Prometheus metrics"""
    import time
    start_time = time.time()
    
    response = await call_next(request)
    
    duration = time.time() - start_time
    REQUEST_DURATION.labels(
        method=request.method,
        endpoint=request.url.path
    ).observe(duration)
    
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    
    return response


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "api-service",
        "version": "1.0.0"
    }


@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.post("/api/email")
async def receive_email(request: EmailRequest):
    """
    Receive email data, validate token and data, then publish to SQS
    """
    # Validate auth value (from SSM; no secrets in code)
    if not validate_token(request.token):
        VALIDATION_ERROR_COUNT.labels(error_type='invalid_token').inc()
        logger.warning("Invalid auth value provided")
        raise HTTPException(
            status_code=401,
            detail="Invalid authentication value"
        )
    
    # Validate email data
    is_valid, error_message = validate_email_data(request.data)
    if not is_valid:
        VALIDATION_ERROR_COUNT.labels(error_type='invalid_data').inc()
        logger.warning(f"Invalid email data: {error_message}")
        raise HTTPException(
            status_code=400,
            detail=error_message
        )
    
    # Publish to SQS
    if not publish_to_sqs(request.data):
        logger.error("Failed to publish message to SQS")
        raise HTTPException(
            status_code=500,
            detail="Failed to process email data"
        )
    
    logger.info(f"Email data processed successfully: {request.data.email_subject}")
    return {
        "status": "success",
        "message": "Email data received and queued successfully",
        "email_subject": request.data.email_subject
    }


@app.exception_handler(ValidationError)
async def validation_exception_handler(request: Request, exc: ValidationError):
    """Handle Pydantic validation errors"""
    VALIDATION_ERROR_COUNT.labels(error_type='pydantic_validation').inc()
    return JSONResponse(
        status_code=422,
        content={
            "detail": "Validation error",
            "errors": exc.errors()
        }
    )


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
