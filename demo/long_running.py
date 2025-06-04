#!/usr/bin/env python3
"""
Долго выполняющийся скрипт для тестирования функции остановки
"""

import time
import sys
from datetime import datetime

def main():
    print("🕐 Запуск долго выполняющегося скрипта...")
    print("Нажмите Stop в веб-панели для остановки")
    print("=" * 50)
    
    counter = 0
    start_time = datetime.now()
    
    try:
        while True:
            counter += 1
            current_time = datetime.now()
            elapsed = current_time - start_time
            
            print(f"[{counter:04d}] {current_time.strftime('%H:%M:%S')} - "
                  f"Работаю уже {elapsed.total_seconds():.1f} секунд")
            
            # Выводим статистику каждые 10 итераций
            if counter % 10 == 0:
                print(f"  📊 Статистика: выполнено {counter} итераций")
                print(f"  ⏱️  Среднее время на итерацию: {elapsed.total_seconds()/counter:.2f} сек")
            
            time.sleep(2)  # Пауза 2 секунды между итерациями
            
    except KeyboardInterrupt:
        print(f"\n⚠️  Скрипт остановлен после {counter} итераций")
        print(f"🕐 Общее время работы: {elapsed}")
        sys.exit(0)

if __name__ == "__main__":
    main() 