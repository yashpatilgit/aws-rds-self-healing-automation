# structure:
# Connect to RDS MySQL
# Detect Long Running queries
# Detect Database Connection utilization
# Identify Blocking sessions and optionally remediate them

# we will use pymysql for database connectivity
# and boto3 for retrieval of credentials from AWS secret manager


import pymysql
import boto3
import json
import logging
import os
from datetime import datetime, timezone

#AWS configuration
AWS_REGION = "ap-south-1"

#AWS secret manager configuration
MASTER_SECRET_NAME="aws-rds-self-healing/dev/rds-master"

#Database Configuration
DB_HOST=os.environ.get("DB_HOST")
DB_PORT=3306
DB_NAME="automation_db"

#Monitoring Configuration
LONG_QUERY_THRESHOLD = 60
CONNECTION_THRESHOLD = 80

# Allowed database users for automated remediation
ALLOWED_BLOCKER_USERS = {"app_user"}


#Prevent automatic termination during initial testing
#Monitoring mode
DRY_RUN = True


#Create AWS secret manager Client
secret_client = boto3.client(
    "secretsmanager",
    region_name=AWS_REGION
)

# Retrieve RDS master credentials
def get_db_credentials():
    response = secret_client.get_secret_value(
        SecretId=MASTER_SECRET_NAME
    )

    credentials=json.loads(response["SecretString"])

    return credentials


#Connect to RDS MYSQL
def get_db_connection():
    credentials=get_db_connection()

    connection=pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=credentials["username"],
        password=credentials["password"],
        database=DB_NAME,
        connect_timeout=10,
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True
    )
    return connection


#Detect Long running queries
def detect_long_running_queries(connection):
    query="""
        SELECT
            ID,
            USER,
            HOST,
            DB,
            COMMAND,
            TIME,
            STATE,
            INFO
        FROM information_schema.PROCESSLIST
        WHERE COMMAND != 'Sleep'
            AND TIME >= %s
            AND ID != CONNECTION_ID()
    """

    with connection.cursor() as cursor:
        cursor.execute(query, (LONG_QUERY_THRESHOLD,))
        long_queries = cursor.fetchall()


    if long_queries:
        logging.warning(
            "Detected %s long-running queries",
            len(long_queries)
        )

        for process in long_queries:
                logging.warning(
                    "Query ID: %s | User: %s | Duration %s seconds",
                    process["ID"],
                    process["USER"],
                    process["TIME"]
                )
    else:
         logging.info("No long-running queries detected")

    return long_queries

#Monitor database connection utilization
def check_connection_utilization(connection):
     query="""
        SHOW GLOBAL STATUS LIKE 'Thread_connected'
    """

     with connection.cursor() as cursor:
          cursor.execute(query)
          current_connections=int(cursor.fetchall()["Value"])

          cursor.execute("SHOW VARIABLES LIKE 'max_connections'")
          max_connections = int(cursor.fetchall()["Value"])

     utilization = (current_connection/max_connection) * 100

     logging.info(
          "Database connection : %s/%s (%.2f%%)",
          current_connections,
          max_connections,
          utilization
     )

     if utilization>=CONNECTION_THRESHOLD:
          logging.waining("High Database connection utilization detected")


     return utilization


#Detect Database blocking sessions
def detect_blocking_sessions(connection):
     query="""
        SELECT
            waiting_pid,
            blocking_pid,
            wait_age,
            locked_table,
            waiting_query,
            blocking_query
        FROM sys.innodb_lock_waits
    """

     with connection.cursor() as cursor:
          cursor.execute(query)
          blocking_sessions = cursor.fetchall()

     if blocking_sessions:
          logging.warning(
               "Detected %s database lock waits",
               len(blocking_sessions)
          )

          for session in blocking_sessions:
               logging.warning(
                    "Waiting PID: %s | Blocking PID: %s | Wait: %s seconds",
                    session["waiting_pid"],
                    session["blocking_pid"],
                    session["wait_age"]
               )

     else:
          logging.info("No Database lock waits detected")


     return blocking_sessions 




# Safely remediate blocking sessions
def remediate_blockers(connection, blocking_sessions):

    for session in blocking_sessions:

        blocking_pid = session["blocking_pid"]

        with connection.cursor() as cursor:

            cursor.execute(
                """
                SELECT ID, USER
                FROM information_schema.PROCESSLIST
                WHERE ID = %s
                """,
                (blocking_pid,)
            )

            blocker = cursor.fetchone()

            if not blocker:
                logging.warning(
                    "Blocking session %s no longer exists",
                    blocking_pid
                )
                continue

            blocker_user = blocker["USER"]

            # Check whether the blocker is approved for remediation
            if blocker_user not in ALLOWED_BLOCKER_USERS:
                logging.warning(
                    "Skipping blocker %s: user %s is not allowlisted",
                    blocking_pid,
                    blocker_user
                )
                continue

            # Dry-run prevents actual termination
            if DRY_RUN:
                logging.warning(
                    "DRY RUN: Would terminate blocking session %s",
                    blocking_pid
                )
                continue

            # Terminate the blocking session using RDS procedure
            cursor.execute(
                "CALL mysql.rds_kill(%s)",
                (blocking_pid,)
            )

            logging.warning(
                "Remediation executed for blocking session %s",
                blocking_pid
            )


# Configure application logging
def setup_logging():

     logging.basicConfig(
          level=logging.INFO,
          format="%(asctime)s | %(levelname)s | %(message)s",
          handlers=[
               logging.FileHandler(
                    "/opt/rds-automation/logs/db-monitor.log"
               ),
               logging.StreamHandler()
          ]
     )



# Main monitoring workflow

def main():
     setup_logging()

     connection = None

     try:
          logging.info("Starting RDS self-healing monitoring")
          connection = get_db_connection()
          long_queries = detect_long_running_queries(connection)
          check_connection_utilization(connection)
          blocking_sessions = detect_blocking_sessions(connection)

          if blocking_sessions:
               remediate_blockers(connection, blocking_sessions)

          logging.info("Monitoring cycle completed successfully")

     except Exception:
          logging.exception("Monitoring cycle failed")

     finally:
          if connection:
               connection.close()
               logging.info("Database connection closed")


if __name__ == "__main__":
     main()    