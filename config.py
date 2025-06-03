import os

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'your-secret-key-change-in-production'
    UPLOAD_FOLDER = os.environ.get('UPLOAD_FOLDER') or 'uploads'
    MAX_CONTENT_LENGTH = int(os.environ.get('MAX_CONTENT_LENGTH', 100 * 1024 * 1024))
    
    ALLOWED_EXTENSIONS = {'py', 'js', 'sh', 'bat', 'txt', 'exe', 'ps1', 'rb', 'php', 'pl'}
    
    HOST = os.environ.get('HOST') or '0.0.0.0'
    PORT = int(os.environ.get('PORT', 5000))
    DEBUG = os.environ.get('DEBUG', 'False').lower() == 'true'
    
    MAX_PROCESSES = int(os.environ.get('MAX_PROCESSES', 20))
    
    ENABLE_AUTH = os.environ.get('ENABLE_AUTH', 'False').lower() == 'true'
    DEFAULT_USERNAME = os.environ.get('DEFAULT_USERNAME') or 'admin'
    DEFAULT_PASSWORD = os.environ.get('DEFAULT_PASSWORD') or 'admin123'

class DevelopmentConfig(Config):
    DEBUG = True
    
class ProductionConfig(Config):
    DEBUG = False
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'production-secret-key-must-be-changed'
    
class TestingConfig(Config):
    TESTING = True
    UPLOAD_FOLDER = 'test_uploads'

config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
} 