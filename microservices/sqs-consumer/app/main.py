"""
SQS Consumer Service - Microservice 2
Polls SQS messages and uploads them to S3
"""

import os
import json
import logging
import time
from datetime import datetime
from typing import Optional
import boto3
from botocore.exceptions import ClientError
from prometheus_client import Counter, Histogram, Gauge, start_http_server, generate_latest
from prometheus_client.core import CollectorRegistry

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Environment variables
SQS_QUEUE_URL = os.getenv('SQS_QUEUE_URL')
S3_BUCKET_NAME = os.getenv('S3_BUCKET_NAME')
SQS_POLL_INTERVAL = int(os.getenv('SQS_POLL_INTERVAL', '30'))
AWS_REGION = os.getenv('AWS_REGION', 'us-west-1')

# AWS clients (initialized lazily to allow testing)
sqs_client = None
s3_client = None


def get_sqs_client():
    """Get or create SQS client"""
    global sqs_client
    if sqs_client is None:
        sqs_client = boto3.client('sqs', region_name=AWS_REGION)
    return sqs_client


def get_s3_client():
    """Get or create S3 client"""
    global s3_client
    if s3_client is None:
        s3_client = boto3.client('s3', region_name=AWS_REGION)
    return s3_client

# Prometheus metrics
REGISTRY = CollectorRegistry()

MESSAGES_PROCESSED = Counter(
    'sqs_messages_processed_total',
    'Total number of messages processed',
    registry=REGISTRY
)

MESSAGES_FAILED = Counter(
    'sqs_messages_failed_total',
    'Total number of messages that failed processing',
    registry=REGISTRY
)

S3_UPLOADS_SUCCESS = Counter(
    's3_uploads_success_total',
    'Total number of successful S3 uploads',
    registry=REGISTRY
)

S3_UPLOADS_FAILED = Counter(
    's3_uploads_failed_total',
    'Total number of failed S3 uploads',
    registry=REGISTRY
)

PROCESSING_DURATION = Histogram(
    'message_processing_duration_seconds',
    'Time taken to process a message',
    registry=REGISTRY
)

QUEUE_MESSAGES_VISIBLE = Gauge(
    'sqs_queue_messages_visible',
    'Number of visible messages in queue',
    registry=REGISTRY
)


def generate_s3_key(email_data: dict) -> str:
    """
    Generate S3 key for storing email data
    Format: emails/YYYY/MM/DD/email-{timestamp}-{sender_hash}.json
    """
    try:
        timestamp = email_data.get('email_timestamp', str(int(time.time())))
        sender = email_data.get('email_sender', 'unknown')
        
        # Create date-based path
        dt = datetime.fromtimestamp(int(timestamp))
        date_path = dt.strftime('%Y/%m/%d')
        
        # Create unique filename
        sender_hash = hash(sender) % 10000
        filename = f"email-{timestamp}-{sender_hash}.json"
        
        return f"emails/{date_path}/{filename}"
    except Exception as e:
        logger.error(f"Error generating S3 key: {e}")
        # Fallback to timestamp-based key
        timestamp = str(int(time.time()))
        return f"emails/{timestamp}/email-{timestamp}.json"


def upload_to_s3(data: dict, s3_key: str) -> bool:
    """
    Upload email data to S3 bucket
    """
    try:
        # Convert data to JSON string
        json_data = json.dumps(data, indent=2)
        
        # Upload to S3
        get_s3_client().put_object(
            Bucket=S3_BUCKET_NAME,
            Key=s3_key,
            Body=json_data.encode('utf-8'),
            ContentType='application/json',
            ServerSideEncryption='AES256'
        )
        
        logger.info(f"Successfully uploaded to S3: s3://{S3_BUCKET_NAME}/{s3_key}")
        S3_UPLOADS_SUCCESS.inc()
        return True
    except ClientError as e:
        logger.error(f"Error uploading to S3: {e}")
        S3_UPLOADS_FAILED.inc()
        return False
    except Exception as e:
        logger.error(f"Unexpected error uploading to S3: {e}")
        S3_UPLOADS_FAILED.inc()
        return False


def process_message(message: dict) -> bool:
    """
    Process a single SQS message
    Returns True if successful, False otherwise
    """
    start_time = time.time()
    
    try:
        # Parse message body
        body = json.loads(message['Body'])
        
        # Generate S3 key
        s3_key = generate_s3_key(body)
        
        # Upload to S3
        success = upload_to_s3(body, s3_key)
        
        if success:
            duration = time.time() - start_time
            PROCESSING_DURATION.observe(duration)
            MESSAGES_PROCESSED.inc()
            logger.info(f"Message processed successfully: {message['MessageId']}")
            return True
        else:
            MESSAGES_FAILED.inc()
            logger.error(f"Failed to process message: {message['MessageId']}")
            return False
            
    except json.JSONDecodeError as e:
        logger.error(f"Error parsing message body: {e}")
        MESSAGES_FAILED.inc()
        return False
    except Exception as e:
        logger.error(f"Error processing message: {e}")
        MESSAGES_FAILED.inc()
        return False


def delete_message(receipt_handle: str) -> bool:
    """
    Delete processed message from SQS queue
    """
    try:
        get_sqs_client().delete_message(
            QueueUrl=SQS_QUEUE_URL,
            ReceiptHandle=receipt_handle
        )
        return True
    except ClientError as e:
        logger.error(f"Error deleting message from SQS: {e}")
        return False


def get_queue_attributes() -> dict:
    """
    Get SQS queue attributes for monitoring
    """
    try:
        response = get_sqs_client().get_queue_attributes(
            QueueUrl=SQS_QUEUE_URL,
            AttributeNames=['ApproximateNumberOfMessages']
        )
        return response.get('Attributes', {})
    except ClientError as e:
        logger.error(f"Error getting queue attributes: {e}")
        return {}


def poll_sqs() -> list:
    """
    Poll SQS queue for messages
    Returns list of messages
    """
    try:
        response = get_sqs_client().receive_message(
            QueueUrl=SQS_QUEUE_URL,
            MaxNumberOfMessages=10,
            WaitTimeSeconds=20,  # Long polling
            MessageAttributeNames=['All']
        )
        
        messages = response.get('Messages', [])
        if messages:
            logger.info(f"Received {len(messages)} messages from SQS")
        
        return messages
    except ClientError as e:
        logger.error(f"Error receiving messages from SQS: {e}")
        return []
    except Exception as e:
        logger.error(f"Unexpected error polling SQS: {e}")
        return []


def process_messages():
    """
    Main processing loop: poll SQS, process messages, upload to S3
    """
    # Validate required environment variables
    if not SQS_QUEUE_URL:
        raise ValueError("SQS_QUEUE_URL environment variable is required")
    if not S3_BUCKET_NAME:
        raise ValueError("S3_BUCKET_NAME environment variable is required")
    
    logger.info("Starting SQS consumer service")
    logger.info(f"SQS Queue URL: {SQS_QUEUE_URL}")
    logger.info(f"S3 Bucket: {S3_BUCKET_NAME}")
    logger.info(f"Poll Interval: {SQS_POLL_INTERVAL} seconds")
    
    while True:
        try:
            # Update queue metrics
            queue_attrs = get_queue_attributes()
            visible_messages = int(queue_attrs.get('ApproximateNumberOfMessages', 0))
            QUEUE_MESSAGES_VISIBLE.set(visible_messages)
            
            # Poll for messages
            messages = poll_sqs()
            
            if messages:
                for message in messages:
                    # Process message
                    success = process_message(message)
                    
                    # Delete message if processed successfully
                    if success:
                        delete_message(message['ReceiptHandle'])
                    else:
                        # If processing failed, message will become visible again after visibility timeout
                        logger.warning(f"Message processing failed, will retry: {message['MessageId']}")
            
            # Wait before next poll
            time.sleep(SQS_POLL_INTERVAL)
            
        except KeyboardInterrupt:
            logger.info("Received interrupt signal, shutting down...")
            break
        except Exception as e:
            logger.error(f"Unexpected error in processing loop: {e}")
            time.sleep(SQS_POLL_INTERVAL)


def start_metrics_server():
    """
    Start Prometheus metrics server
    """
    try:
        metrics_port = int(os.getenv('METRICS_PORT', '9090'))
        start_http_server(metrics_port, registry=REGISTRY)
        logger.info(f"Prometheus metrics server started on port {metrics_port}")
    except Exception as e:
        logger.error(f"Error starting metrics server: {e}")


if __name__ == "__main__":
    # Start metrics server in a separate thread
    import threading
    metrics_thread = threading.Thread(target=start_metrics_server, daemon=True)
    metrics_thread.start()
    
    # Start processing messages
    process_messages()
