"""
Unit tests for SQS Consumer service
"""

import pytest
import json
import time
from unittest.mock import Mock, patch, MagicMock
from app.main import (
    generate_s3_key,
    upload_to_s3,
    process_message,
    delete_message,
    poll_sqs
)


@pytest.fixture
def sample_email_data():
    """Sample email data"""
    return {
        "email_subject": "Test Email",
        "email_sender": "test@example.com",
        "email_timestamp": "1693561101",
        "email_content": "This is a test email content"
    }


@pytest.fixture
def sample_sqs_message(sample_email_data):
    """Sample SQS message"""
    return {
        "MessageId": "test-message-id",
        "ReceiptHandle": "test-receipt-handle",
        "Body": json.dumps(sample_email_data)
    }


class TestGenerateS3Key:
    """Test S3 key generation"""
    
    def test_generate_s3_key(self, sample_email_data):
        """Test S3 key generation with valid data"""
        key = generate_s3_key(sample_email_data)
        assert key.startswith("emails/")
        assert key.endswith(".json")
        assert "1693561101" in key
    
    def test_generate_s3_key_missing_timestamp(self):
        """Test S3 key generation with missing timestamp"""
        data = {
            "email_sender": "test@example.com"
        }
        key = generate_s3_key(data)
        assert key.startswith("emails/")
        assert key.endswith(".json")
    
    def test_generate_s3_key_missing_sender(self):
        """Test S3 key generation with missing sender"""
        data = {
            "email_timestamp": "1693561101"
        }
        key = generate_s3_key(data)
        assert key.startswith("emails/")


class TestUploadToS3:
    """Test S3 upload functionality"""
    
    @patch('app.main.s3_client')
    def test_upload_to_s3_success(self, mock_s3, sample_email_data):
        """Test successful S3 upload"""
        import os
        os.environ['S3_BUCKET_NAME'] = 'test-bucket'
        
        mock_s3.put_object.return_value = {}
        
        result = upload_to_s3(sample_email_data, "emails/test/key.json")
        assert result is True
        mock_s3.put_object.assert_called_once()
    
    @patch('app.main.s3_client')
    def test_upload_to_s3_failure(self, mock_s3, sample_email_data):
        """Test failed S3 upload"""
        import os
        os.environ['S3_BUCKET_NAME'] = 'test-bucket'
        
        from botocore.exceptions import ClientError
        mock_s3.put_object.side_effect = ClientError(
            {'Error': {'Code': 'AccessDenied'}},
            'PutObject'
        )
        
        result = upload_to_s3(sample_email_data, "emails/test/key.json")
        assert result is False


class TestProcessMessage:
    """Test message processing"""
    
    @patch('app.main.upload_to_s3')
    @patch('app.main.generate_s3_key')
    def test_process_message_success(
        self,
        mock_generate_key,
        mock_upload,
        sample_sqs_message
    ):
        """Test successful message processing"""
        mock_generate_key.return_value = "emails/test/key.json"
        mock_upload.return_value = True
        
        result = process_message(sample_sqs_message)
        assert result is True
        mock_upload.assert_called_once()
    
    def test_process_message_invalid_json(self):
        """Test processing message with invalid JSON"""
        invalid_message = {
            "MessageId": "test-id",
            "Body": "invalid json {"
        }
        
        result = process_message(invalid_message)
        assert result is False


class TestDeleteMessage:
    """Test message deletion"""
    
    @patch('app.main.sqs_client')
    def test_delete_message_success(self, mock_sqs):
        """Test successful message deletion"""
        import os
        os.environ['SQS_QUEUE_URL'] = 'https://sqs.us-west-1.amazonaws.com/123456789/test-queue'
        
        mock_sqs.delete_message.return_value = {}
        
        result = delete_message("test-receipt-handle")
        assert result is True
        mock_sqs.delete_message.assert_called_once()
    
    @patch('app.main.sqs_client')
    def test_delete_message_failure(self, mock_sqs):
        """Test failed message deletion"""
        import os
        os.environ['SQS_QUEUE_URL'] = 'https://sqs.us-west-1.amazonaws.com/123456789/test-queue'
        
        from botocore.exceptions import ClientError
        mock_sqs.delete_message.side_effect = ClientError(
            {'Error': {'Code': 'InvalidReceiptHandle'}},
            'DeleteMessage'
        )
        
        result = delete_message("invalid-receipt-handle")
        assert result is False


class TestPollSQS:
    """Test SQS polling"""
    
    @patch('app.main.sqs_client')
    def test_poll_sqs_with_messages(self, mock_sqs, sample_sqs_message):
        """Test polling SQS with messages"""
        import os
        os.environ['SQS_QUEUE_URL'] = 'https://sqs.us-west-1.amazonaws.com/123456789/test-queue'
        
        mock_sqs.receive_message.return_value = {
            'Messages': [sample_sqs_message]
        }
        
        messages = poll_sqs()
        assert len(messages) == 1
        assert messages[0]['MessageId'] == 'test-message-id'
    
    @patch('app.main.sqs_client')
    def test_poll_sqs_no_messages(self, mock_sqs):
        """Test polling SQS with no messages"""
        import os
        os.environ['SQS_QUEUE_URL'] = 'https://sqs.us-west-1.amazonaws.com/123456789/test-queue'
        
        mock_sqs.receive_message.return_value = {}
        
        messages = poll_sqs()
        assert len(messages) == 0
    
    @patch('app.main.sqs_client')
    def test_poll_sqs_error(self, mock_sqs):
        """Test polling SQS with error"""
        import os
        os.environ['SQS_QUEUE_URL'] = 'https://sqs.us-west-1.amazonaws.com/123456789/test-queue'
        
        from botocore.exceptions import ClientError
        mock_sqs.receive_message.side_effect = ClientError(
            {'Error': {'Code': 'AccessDenied'}},
            'ReceiveMessage'
        )
        
        messages = poll_sqs()
        assert len(messages) == 0
