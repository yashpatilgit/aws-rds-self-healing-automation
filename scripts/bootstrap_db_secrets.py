import boto3
import json
from botocore.exceptions import ClientError

#AWS configuration
AWS_REGION = "ap-south-1"

#Secret Manager configuration
SECRET_NAME = "aws-rds-self-healing/dev/database-users"

#Database Users
DB_USERS = [
    "app_user",
    "readonly_user",
    "ops_automation"
]

#Create Secret Manager Client
secrets_client = boto3.client(
    "secretsmanager", 
    region_name = AWS_REGION
)


#Check whether secret exists or not
def secret_exists():
    try:
        secrets_client.describe_secret(
            SecretId=SECRET_NAME
        )
        print("Secret already exists")
        return True

    
    except ClientError as error:
        error_code=error.response["Error"]["Code"]

        if error_code=="ResourceNotFoundException":
            print("Secret does not exist")
            return False
        else:
            raise 


# return False- Return a value and exit the function
# print(error)-	Display the error but continue execution
# raise error-	Stop normal execution and propagate the error


#reteive the existing credentials from secret manager
def get_existing_secret():
    try:
        response = secrets_client.get_secret_value(
            SecretId=SECRET_NAME
        )
        secret_data = json.loads(response["SecretString"])
        return secret_data
    
    except json.JSONDecodeError as error:
        raise ValueError("Existing secret contains invalid JSON") from error

#Function to validate the credentials retrieved from AWS secret manager
def validate_credentials(credentials):

    for user in DB_USERS:

        #check whether the current user exists in credentials dictionary
        #if user is missing, raise an error
        if user not in credentials:
            raise ValueError(f"Missing credentials for {user}")

        #check whether the username field exists and contains a value
        #.get() returns None if the key does not exists
        if not credentials[user].get("username"):
            raise ValueError(f"Missing username for {user}")

        #check whether the password field exists and contains a value
        if not credentials[user].get("password"):
            raise ValueError(f"Missing password for {user}")


    #Return true to indicate that validation was successfull
    return True
    





#generate a passoword
def generate_password():
    response = secrets_client.get_random_password(
        PasswordLength=32,
        ExcludeCharacters='"@/\\'
    )

    password = response["RandomPassword"]
    return password


#generate an user credentials - template for user creation
def generate_user_credentials():
    credentials = {}
    for user in DB_USERS:

        credentials[user] = {
            "username": user,
            "password": generate_password()
        }
    return credentials


#store generated credentials in AWS secret manager
def create_user_secret(credentials):

    secrets_client.create_secret(
        Name=SECRET_NAME,
        Description="Database User credentials for rds self-healing automation",
        SecretString=json.dumps(credentials)
    )
    
    print("Database user credentials stored successfully")


#connecting whole work flow
#exists or not? if yes, retrieve the creds! if no, generate and store

def main():
    if secret_exists():
        credentials = get_existing_secret()
        validate_credentials(credentials)
        print("Using existing database credentials")

    else:
        credentials = generate_user_credentials()
        validate_credentials(credentials)
        create_user_secret(credentials)

    print("Credentials bootstrap completed successfully")

if __name__ == "__main__":
    main()