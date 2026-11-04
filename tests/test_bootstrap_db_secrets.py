# Checked whether a secret exists.
# Retrieved existing credentials.
# Generated secure 32-character passwords.
# Generated credentials for three database users.
# Stored credentials in AWS Secrets Manager.
# Validated usernames and passwords.
# Handled invalid JSON.
# Tested the workflow using Python mocks without AWS deployment.



import unittest
from botocore.exceptions import ClientError
from unittest.mock import patch

from scripts import bootstrap_db_secrets as bootstrap


class TestSecretBootstrap(unittest.TestCase):

    @patch.object(bootstrap.secrets_client, "describe_secret")
    def test_secret_exists(self, mock_describe):

        # Simulate AWS successfully finding the secret
        mock_describe.return_value = {"Name": bootstrap.SECRET_NAME}

        result = bootstrap.secret_exists()

        # Verify that the function returns True
        self.assertTrue(result)

    @patch.object(bootstrap.secrets_client, "describe_secret")
    def test_secret_does_not_exist(self, mock_describe):

        # Simulate AWS returning ResourceNotFoundException
        error_response = {
            "Error": {
                "Code": "ResourceNotFoundException"
            }
        }

        mock_describe.side_effect = ClientError(
            error_response,
            "DescribeSecret"
        )

        result = bootstrap.secret_exists()

        # Verify that the function returns False
        self.assertFalse(result)

    @patch.object(bootstrap.secrets_client, "get_random_password")
    def test_generate_password(self, mock_password):

        # Simulate AWS returning a generated password
        mock_password.return_value = {
            "RandomPassword": "TestPassword123!Secure"
        }

        result = bootstrap.generate_password()

        # Verify the generated password
        self.assertEqual(result, "TestPassword123!Secure")

        # Verify AWS was called with the expected length
        mock_password.assert_called_once_with(
            PasswordLength=32,
            ExcludeCharacters='"@/\\'
        )

    @patch.object(bootstrap, "generate_password")
    def test_generate_user_credentials(self, mock_password):

        # Simulate a different password for each call
        mock_password.side_effect = [
            "PasswordForApp123!",
            "PasswordForReadOnly123!",
            "PasswordForOps123!"
        ]

        credentials = bootstrap.generate_user_credentials()

        # Verify all three users are present
        self.assertEqual(len(credentials), 3)

        # Verify usernames and passwords
        for user in bootstrap.DB_USERS:
            self.assertEqual(credentials[user]["username"], user)
            self.assertTrue(credentials[user]["password"])

        # Verify password generation was called three times
        self.assertEqual(mock_password.call_count, 3)

        # Test whether all database credentials are valid
    def test_validate_credentials(self):

        # Create sample credentials for all three database users
        credentials = {
            "app_user": {
                "username": "app_user",
                "password": "test123"
            },
            "readonly_user": {
                "username": "readonly_user",
                "password": "test456"
            },
            "ops_automation": {
                "username": "ops_automation",
                "password": "test789"
            }
        }

        # Call the actual validation function
        result = bootstrap.validate_credentials(credentials)

        # Verify that validation returns True
        self.assertTrue(result)


        # Test validation failure when a password is missing
    def test_validate_credentials_missing_password(self):

        credentials = {
            "app_user": {
                "username": "app_user",
                "password": "test123"
            },
            "readonly_user": {
                "username": "readonly_user",
                "password": ""
            },
            "ops_automation": {
                "username": "ops_automation",
                "password": "test789"
            }
        }

        # Verify that invalid credentials raise a ValueError
        with self.assertRaises(ValueError):
            bootstrap.validate_credentials(credentials)


        # Test whether database credentials are stored in AWS Secrets Manager
    @patch.object(bootstrap.secrets_client, "create_secret")
    def test_create_user_secret(self, mock_create):

        credentials = {
            "app_user": {
                "username": "app_user",
                "password": "test123"
            }
        }

        bootstrap.create_user_secret(credentials)

        mock_create.assert_called_once()

        # Test handling of invalid JSON in AWS Secrets Manager
    @patch.object(bootstrap.secrets_client, "get_secret_value")
    def test_get_existing_secret_invalid_json(self, mock_secret):

        mock_secret.return_value = {
            "SecretString": "This is not valid JSON"
        }

        with self.assertRaisesRegex(
            ValueError,
            "Existing secret contains invalid JSON"
        ):
            bootstrap.get_existing_secret()


if __name__ == "__main__":
    unittest.main()