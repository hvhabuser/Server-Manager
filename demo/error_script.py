#!/usr/bin/env python3
"""
Скрипт с ошибкой для тестирования обработки ошибок
"""

import time
import sys

def main():
    print("🔥 Скрипт с ошибкой запущен")
    print("Этот скрипт намеренно завершится с ошибкой")
    print("=" * 50)
    
    print("Шаг 1: Инициализация...")
    time.sleep(1)
    
    print("Шаг 2: Проверка системы...")
    time.sleep(1)
    
    print("Шаг 3: Загрузка данных...")
    time.sleep(1)
    
    print("🚨 ОШИБКА: Произошла критическая ошибка!")
    print("Детали ошибки:")
    print("  - Файл не найден: /path/to/nonexistent/file.txt")
    print("  - Код ошибки: 404")
    print("  - Рекомендация: Проверьте наличие файла")
    
    # Имитируем ошибку
    raise FileNotFoundError("Тестовая ошибка: файл не найден")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"❌ Фатальная ошибка: {e}")
        sys.exit(1) 