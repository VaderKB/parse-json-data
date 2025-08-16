import json
import random
import string
from datetime import datetime, timedelta
import uuid
import boto3

# Helper functions
def random_string(length=8):
    return ''.join(random.choices(string.ascii_letters, k=length))

def random_email():
    return f"{random_string(5).lower()}@{random_string(5).lower()}.com"

def random_date(start_year=1990, end_year=2023):
    start = datetime(start_year, 1, 1)
    end = datetime(end_year, 12, 31)
    return (start + timedelta(days=random.randint(0, (end - start).days))).strftime("%Y-%m-%d")

def random_phone():
    return f"+1-{random.randint(200,999)}-{random.randint(100,999)}-{random.randint(1000,9999)}"

def random_language_list():
    languages = ["English", "French", "Spanish", "German", "Hindi", "Chinese", "Arabic", "Russian"]
    levels = ["Basic", "Intermediate", "Fluent", "Native"]
    return [
        {
            "language": random.choice(languages),
            "level": random.choice(levels),
            "certifications": [
                {
                    "cert_name": f"{random.choice(languages)}_Cert_{random.randint(1,5)}",
                    "issued_by": random_string(6),
                    "issue_date": random_date(2000, 2024)
                }
                for _ in range(random.randint(0, 2))
            ]
        }
        for _ in range(random.randint(1, 4))
    ]

def random_address():
    return {
        "street": f"{random.randint(1, 9999)} {random_string(6)} St",
        "city": random_string(6),
        "state": random_string(2).upper(),
        "zip": f"{random.randint(10000, 99999)}",
        "coordinates": {
            "lat": round(random.uniform(-90, 90), 6),
            "lon": round(random.uniform(-180, 180), 6)
        }
    }

def random_purchase_history():
    return [
        {
            "purchase_id": str(uuid.uuid4()),
            "item": random_string(10),
            "category": random.choice(["Electronics", "Clothing", "Books", "Sports"]),
            "price": round(random.uniform(5, 500), 2),
            "purchase_date": random_date(2015, 2025),
            "reviews": [
                {
                    "rating": random.randint(1, 5),
                    "comment": random_string(30),
                    "review_date": random_date(2015, 2025)
                }
                for _ in range(random.randint(0, 3))
            ]
        }
        for _ in range(random.randint(1, 5))
    ]

# Generate random user JSON
def generate_user_json(num_users=5):
    users = []
    for _ in range(num_users):
        user = {
            "user_id": str(uuid.uuid4()),
            "first_name": random_string(6),
            "last_name": random_string(8),
            "email": random_email(),
            "phone": random_phone(),
            "dob": random_date(1970, 2005),
            "is_active": random.choice([True, False]),
            "addresses": [random_address() for _ in range(random.randint(1, 3))],
            "spoken_languages": random_language_list(),
            "purchase_history": random_purchase_history(),
            "preferences": {
                "newsletter": random.choice([True, False]),
                "categories": random.sample(["Electronics", "Clothing", "Books", "Sports"], k=random.randint(1, 4)),
                "payment_methods": [
                    {
                        "type": random.choice(["Credit Card", "Debit Card", "PayPal", "Bank Transfer"]),
                        "last4": str(random.randint(1000, 9999))
                    }
                    for _ in range(random.randint(1, 3))
                ]
            }
        }
        users.append(user)
    return users

def lambda_handler(event, context):
    # TODO implement
    # Generate and save JSON
    
    data = generate_user_json(3)  # Change number for more users
    json_str = json.dumps(data, indent=4)
    print(json_str)

    # Create a hash of the JSON content (SHA256)
    hash_value = str(uuid.uuid4()).replace("-", "_")

    # Save file with hash as the filename
    filename = f"{hash_value}.json"
    # Save to file

    # --- AWS S3 configuration ---
    s3_bucket = "snowflake-user-data-vader-k"      # replace with your bucket name
    s3_key = f"source_user_data/{filename}"       # optional folder path in bucket

    # Initialize S3 client (ensure AWS credentials are configured)
    s3 = boto3.client('s3')

    # Upload JSON to S3
    s3.put_object(
        Bucket=s3_bucket,
        Key=s3_key,
        Body=json_str,
        ContentType='application/json'
    )

    print(f"JSON saved to S3 at: s3://{s3_bucket}/{s3_key}")