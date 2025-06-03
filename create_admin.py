#!/usr/bin/env python3

import hashlib
import json
import os
import getpass

def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()

def create_admin_user():
    print("=== Creating Admin User ===")
    
    username = input("Enter admin username (default: admin): ").strip()
    if not username:
        username = "admin"
    
    password = getpass.getpass("Enter admin password: ")
    if not password:
        print("Password cannot be empty!")
        return
    
    confirm_password = getpass.getpass("Confirm admin password: ")
    if password != confirm_password:
        print("Passwords do not match!")
        return
    
    hashed_password = hash_password(password)
    
    admin_data = {
        "username": username,
        "password": hashed_password,
        "created_at": "admin_created",
        "role": "admin"
    }
    
    os.makedirs("data", exist_ok=True)
    
    with open("data/admin.json", "w") as f:
        json.dump(admin_data, f, indent=2)
    
    print(f"Admin user '{username}' created successfully!")
    print("Admin credentials saved to data/admin.json")
    print("\nTo enable authentication, set ENABLE_AUTH=true in environment variables")

if __name__ == "__main__":
    create_admin_user() 