#!/usr/bin/env python3

import time
import sys
import random

def main():
    print("=== Test Script Started ===")
    print(f"Python version: {sys.version}")
    print(f"Script arguments: {sys.argv[1:] if len(sys.argv) > 1 else 'None'}")
    
    print("\n--- Processing data ---")
    for i in range(5):
        progress = (i + 1) * 20
        print(f"Progress: {progress}% - Processing item {i+1}")
        time.sleep(2)
    
    print("\n--- Generating random numbers ---")
    numbers = [random.randint(1, 100) for _ in range(10)]
    print(f"Generated numbers: {numbers}")
    print(f"Sum: {sum(numbers)}")
    print(f"Average: {sum(numbers)/len(numbers):.2f}")
    
    print("\n--- Testing error output ---")
    print("This is normal output", file=sys.stdout)
    print("This is error output", file=sys.stderr)
    
    print("\n=== Test Script Completed Successfully ===")
    return 0

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code) 