"""
Unit tests for API service
"""

import pytest
import json
from unittest.mock import Mock, patch, MagicMock
from fastapi.testclient import TestClient
from app.main import app, validate_token, validate_email_data, publish_to_sqs
from app.main import EmailData, EmailRequest

client = TestClient(app)


@pytest.fixture
def mock_ssm_token():
    """Mock SSM token"""
    return "test-token-12345"


@pytest.fixture
def mock_sqs_queue_url():
    """Mock SQS queue URL"""
    return "https://sqs.us-west-1.amazonaws.com/123456789/test-queue"


@pytest.fixture
def valid_email_data():
    """Valid email data"""
    return {
        "email_subject": "Test Email",
        "email_sender": "test@example.com",
        "email_timestamp": "1693561101",
        "email_content": "This is a test email content"
    }


@pytest.fixture
def valid_request(valid_email_data, mock_ssm_token):
    """Valid request payload"""
    return {
        "data": valid_email_data,
        "token": mock_ssm_token
    }


class TestHealthCheck:
    """Test health check endpoint"""
    
    def test_health_check(self):
        """Test health endpoint returns 200"""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["service"] == "api-service"


class TestTokenValidation:
    """Test token validation"""
    
    @patch('app.main.ssm_client')
    def test_validate_token_success(self, mock_ssm, mock_ssm_token):
        """Test successful token validation"""
        mock_ssm.get_parameter.return_value = {
            'Parameter': {'Value': mock_ssm_token}
        }
        
        result = validate_token(mock_ssm_token)
        assert result is True
    
    @patch('app.main.ssm_client')
    def test_validate_token_failure(self, mock_ssm, mock_ssm_token):
        """Test failed token validation"""
        mock_ssm.get_parameter.return_value = {
            'Parameter': {'Value': 'different-token'}
        }
        
        result = validate_token(mock_ssm_token)
        assert result is False


class TestEmailDataValidation:
    """Test email data validation"""
    
    def test_validate_email_data_success(self, valid_email_data):
        """Test successful email data validation"""
        email_data = EmailData(**valid_email_data)
        is_valid, error = validate_email_data(email_data)
        assert is_valid is True
        assert error is None
    
    def test_validate_email_data_missing_field(self):
        """Test validation with missing field"""
        incomplete_data = {
            "email_subject": "Test",
            "email_sender": "test@example.com",
            "email_timestamp": "1693561101"
            # Missing email_content
        }
        email_data = EmailData(**incomplete_data)
        is_valid, error = validate_email_data(email_data)
        assert is_valid is False
        assert "email_content" in error
    
    def test_validate_email_data_empty_field(self):
        """Test validation with empty field"""
        data_with_empty = {
            "email_subject": "",
            "email_sender": "test@example.com",
            "email_timestamp": "1693561101",
            "email_content": "Content"
        }
        email_data = EmailData(**data_with_empty)
        is_valid, error = validate_email_data(email_data)
        assert is_valid is False
        assert "email_subject" in error


class TestPublishToSQS:
    """Test SQS publishing"""
    
    @patch('app.main.sqs_client')
    def test_publish_to_sqs_success(self, mock_sqs, valid_email_data, mock_sqs_queue_url):
        """Test successful SQS publish"""
        import os
        os.environ['SQS_QUEUE_URL'] = mock_sqs_queue_url
        
        mock_sqs.send_message.return_value = {'MessageId': 'test-msg-id'}
        email_data = EmailData(**valid_email_data)
        
        result = publish_to_sqs(email_data)
        assert result is True
        mock_sqs.send_message.assert_called_once()
    
    @patch('app.main.sqs_client')
    def test_publish_to_sqs_failure(self, mock_sqs, valid_email_data):
        """Test failed SQS publish"""
        import os
        os.environ['SQS_QUEUE_URL'] = "https://sqs.us-west-1.amazonaws.com/123456789/test-queue"
        
        mock_sqs.send_message.side_effect = Exception("SQS error")
        email_data = EmailData(**valid_email_data)
        
        result = publish_to_sqs(email_data)
        assert result is False


class TestEmailAPI:
    """Test email API endpoint"""
    
    @patch('app.main.validate_token')
    @patch('app.main.validate_email_data')
    @patch('app.main.publish_to_sqs')
    def test_post_email_success(
        self, 
        mock_publish, 
        mock_validate_data, 
        mock_validate_token,
        valid_request
    ):
        """Test successful email submission"""
        mock_validate_token.return_value = True
        mock_validate_data.return_value = (True, None)
        mock_publish.return_value = True
        
        response = client.post("/api/email", json=valid_request)
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
    
    @patch('app.main.validate_token')
    def test_post_email_invalid_token(self, mock_validate_token, valid_request):
        """Test email submission with invalid token"""
        mock_validate_token.return_value = False
        
        response = client.post("/api/email", json=valid_request)
        assert response.status_code == 401
        assert "Invalid authentication token" in response.json()["detail"]
    
    @patch('app.main.validate_token')
    @patch('app.main.validate_email_data')
    def test_post_email_invalid_data(
        self, 
        mock_validate_data, 
        mock_validate_token,
        valid_request
    ):
        """Test email submission with invalid data"""
        mock_validate_token.return_value = True
        mock_validate_data.return_value = (False, "Missing required fields")
        
        response = client.post("/api/email", json=valid_request)
        assert response.status_code == 400
    
    def test_post_email_missing_fields(self):
        """Test email submission with missing request fields"""
        incomplete_request = {
            "data": {
                "email_subject": "Test"
            }
        }
        response = client.post("/api/email", json=incomplete_request)
        assert response.status_code == 422  # Validation error


class TestMetrics:
    """Test metrics endpoint"""
    
    def test_metrics_endpoint(self):
        """Test Prometheus metrics endpoint"""
        response = client.get("/metrics")
        assert response.status_code == 200
        assert "text/plain" in response.headers["content-type"]
