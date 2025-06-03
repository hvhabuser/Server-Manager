#!/usr/bin/env python3

import time
import signal
import sys
from datetime import datetime

class LongRunningScript:
    def __init__(self):
        self.running = True
        self.counter = 0
        
    def signal_handler(self, signum, frame):
        print(f"\nReceived signal {signum}. Shutting down gracefully...")
        self.running = False
        
    def run(self):
        signal.signal(signal.SIGTERM, self.signal_handler)
        signal.signal(signal.SIGINT, self.signal_handler)
        
        print("=== Long Running Script Started ===")
        print(f"Started at: {datetime.now()}")
        print("Press Ctrl+C or send SIGTERM to stop gracefully")
        print("---")
        
        try:
            while self.running:
                self.counter += 1
                current_time = datetime.now().strftime("%H:%M:%S")
                print(f"[{current_time}] Iteration #{self.counter} - Still running...")
                
                time.sleep(5)
                
                if self.counter % 10 == 0:
                    print(f"Milestone reached: {self.counter} iterations completed")
                    
        except KeyboardInterrupt:
            print("\nKeyboard interrupt received. Stopping...")
            
        finally:
            print(f"\n=== Script Stopped ===")
            print(f"Total iterations: {self.counter}")
            print(f"Stopped at: {datetime.now()}")

if __name__ == "__main__":
    script = LongRunningScript()
    script.run() 