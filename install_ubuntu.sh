#!/bin/bash

# ================================
# 🚀 WebPanel Auto-Installer для Ubuntu
# ================================

set -e  # Остановка при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Функция для красивого вывода
print_step() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] ${GREEN}$1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Проверка что скрипт запущен на Ubuntu
if [[ ! -f /etc/os-release ]] || ! grep -q "ubuntu\|debian" /etc/os-release; then
    print_error "Этот скрипт предназначен для Ubuntu/Debian систем"
    exit 1
fi

echo -e "${PURPLE}"
echo "██╗    ██╗███████╗██████╗ ██████╗  █████╗ ███╗   ██╗███████╗██╗     "
echo "██║    ██║██╔════╝██╔══██╗██╔══██╗██╔══██╗████╗  ██║██╔════╝██║     "
echo "██║ █╗ ██║█████╗  ██████╔╝██████╔╝███████║██╔██╗ ██║█████╗  ██║     "
echo "██║███╗██║██╔══╝  ██╔══██╗██╔═══╝ ██╔══██║██║╚██╗██║██╔══╝  ██║     "
echo "╚███╔███╔╝███████╗██████╔╝██║     ██║  ██║██║ ╚████║███████╗███████╗"
echo " ╚══╝╚══╝ ╚══════╝╚═════╝ ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝"
echo -e "${NC}"
echo -e "${CYAN}🚀 Автоматический установщик WebPanel для Ubuntu${NC}"
echo -e "${CYAN}📋 Устанавливает все зависимости и запускает сервер${NC}"
echo ""

# Проверка прав root для установки пакетов
if [[ $EUID -eq 0 ]]; then
    print_info "Запущено от root - будет установлено глобально в /opt/webpanel"
    INSTALL_DIR="/opt/webpanel"
    USE_SUDO=""
else
    print_info "Запущено от пользователя - будет установлено в домашнюю папку"
    INSTALL_DIR="$HOME/webpanel"
    USE_SUDO="sudo"
fi

echo ""
read -p "🚀 Продолжить установку WebPanel? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Установка отменена"
    exit 0
fi

# =====================================
# 📦 УСТАНОВКА СИСТЕМНЫХ ЗАВИСИМОСТЕЙ
# =====================================

print_step "Обновление системы..."
$USE_SUDO apt update && $USE_SUDO apt upgrade -y

print_step "Установка Python и системных пакетов..."
$USE_SUDO apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    git \
    curl \
    wget \
    htop \
    nano \
    tree

# Установка поддержки RAR архивов (пробуем разные варианты)
print_step "Установка поддержки RAR архивов..."
if $USE_SUDO apt install -y unrar 2>/dev/null; then
    print_success "Установлен unrar"
elif $USE_SUDO apt install -y unrar-free 2>/dev/null; then
    print_success "Установлен unrar-free"
elif $USE_SUDO apt install -y p7zip-full 2>/dev/null; then
    print_success "Установлен p7zip-full (альтернатива для RAR)"
else
    print_info "⚠️  RAR поддержка не установлена, но ZIP архивы будут работать"
fi

# =====================================
# 📁 СОЗДАНИЕ СТРУКТУРЫ ПРОЕКТА
# =====================================

print_step "Создание директории проекта: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

print_step "Создание виртуального окружения..."
python3 -m venv venv
source venv/bin/activate

print_step "Создание структуры папок..."
mkdir -p uploads projects logs static/css static/js templates demo

# =====================================
# 📝 СОЗДАНИЕ ФАЙЛОВ ПРОЕКТА
# =====================================

print_step "Создание requirements.txt..."
cat > requirements.txt << 'EOF'
Flask==2.3.2
Flask-SocketIO==5.3.4
psutil==5.9.5
rarfile==4.0
python-socketio==5.8.0
eventlet==0.33.3
python-engineio==4.12.1
simple-websocket==1.1.0
werkzeug==3.1.3
click==8.1.7
blinker==1.9.0
itsdangerous==2.2.0
jinja2==3.1.6
markupsafe==3.0.2
bidict==0.23.1
h11==0.16.0
wsproto==1.2.0
six==1.17.0
dnspython==2.7.0
greenlet==3.2.2
EOF

print_step "Установка Python зависимостей..."
pip install --upgrade pip
pip install -r requirements.txt

print_step "Создание основного серверного файла app.py..."
cat > app.py << 'EOF'
import os
import json
import subprocess
import threading
import time
import uuid
import zipfile
import rarfile
from datetime import datetime
from flask import Flask, render_template, request, jsonify, send_file, redirect, url_for
from flask_socketio import SocketIO, emit
from werkzeug.utils import secure_filename
import psutil

app = Flask(__name__)
app.config['SECRET_KEY'] = 'webpanel-ubuntu-server-2025'
app.config['UPLOAD_FOLDER'] = 'uploads'
app.config['PROJECTS_FOLDER'] = 'projects'
app.config['LOGS_FOLDER'] = 'logs'

socketio = SocketIO(app, cors_allowed_origins="*")

# Создание необходимых папок
for folder in [app.config['UPLOAD_FOLDER'], app.config['PROJECTS_FOLDER'], app.config['LOGS_FOLDER']]:
    os.makedirs(folder, exist_ok=True)

# Глобальные переменные для хранения процессов
running_processes = {}
process_history = []

class ScriptProcess:
    def __init__(self, script_id, name, command, cwd=None):
        self.id = script_id
        self.name = name
        self.command = command
        self.cwd = cwd
        self.process = None
        self.start_time = datetime.now()
        self.end_time = None
        self.status = 'starting'
        self.log_file = os.path.join(app.config['LOGS_FOLDER'], f'{script_id}.log')
        self.output_lines = []
        
    def start(self):
        try:
            with open(self.log_file, 'w', encoding='utf-8') as log:
                env = os.environ.copy()
                env['PYTHONIOENCODING'] = 'utf-8'
                env['LANG'] = 'en_US.UTF-8'
                env['LC_ALL'] = 'en_US.UTF-8'
                
                self.process = subprocess.Popen(
                    self.command,
                    shell=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    cwd=self.cwd,
                    bufsize=1,
                    universal_newlines=True,
                    encoding='utf-8',
                    errors='replace',
                    env=env
                )
                self.status = 'running'
                
                threading.Thread(target=self._monitor_output, daemon=True).start()
                
        except Exception as e:
            self.status = 'error'
            self.end_time = datetime.now()
            with open(self.log_file, 'w', encoding='utf-8') as log:
                log.write(f"Error starting process: {str(e)}")
    
    def _monitor_output(self):
        try:
            with open(self.log_file, 'a', encoding='utf-8') as log:
                for line in iter(self.process.stdout.readline, ''):
                    if line:
                        try:
                            log.write(line)
                            log.flush()
                            self.output_lines.append(line.strip())
                            socketio.emit('script_output', {
                                'script_id': self.id,
                                'line': line.strip()
                            })
                        except UnicodeDecodeError:
                            safe_line = line.encode('utf-8', errors='replace').decode('utf-8')
                            log.write(safe_line)
                            log.flush()
                            self.output_lines.append(safe_line.strip())
                
                self.process.wait()
                self.status = 'completed' if self.process.returncode == 0 else 'failed'
                self.end_time = datetime.now()
                
                if self.id in running_processes:
                    del running_processes[self.id]
                    
        except Exception as e:
            self.status = 'error'
            self.end_time = datetime.now()
    
    def stop(self):
        if self.process and self.process.poll() is None:
            try:
                parent = psutil.Process(self.process.pid)
                children = parent.children(recursive=True)
                for child in children:
                    child.terminate()
                parent.terminate()
                
                time.sleep(2)
                for child in children:
                    if child.is_running():
                        child.kill()
                if parent.is_running():
                    parent.kill()
                    
                self.status = 'stopped'
                self.end_time = datetime.now()
            except:
                pass
    
    def get_logs(self):
        try:
            with open(self.log_file, 'r', encoding='utf-8') as log:
                return log.read()
        except:
            return "No logs available"
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'command': self.command,
            'status': self.status,
            'start_time': self.start_time.strftime('%Y-%m-%d %H:%M:%S'),
            'end_time': self.end_time.strftime('%Y-%m-%d %H:%M:%S') if self.end_time else None,
            'duration': str(self.end_time - self.start_time) if self.end_time else str(datetime.now() - self.start_time)
        }

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file selected'}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400
    
    filename = secure_filename(file.filename)
    filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
    file.save(filepath)
    
    if filename.lower().endswith('.zip'):
        extract_path = os.path.join(app.config['PROJECTS_FOLDER'], filename[:-4])
        os.makedirs(extract_path, exist_ok=True)
        with zipfile.ZipFile(filepath, 'r') as zip_ref:
            zip_ref.extractall(extract_path)
        os.remove(filepath)
        return jsonify({'success': True, 'message': f'Archive extracted to {extract_path}'})
    
    elif filename.lower().endswith('.rar'):
        extract_path = os.path.join(app.config['PROJECTS_FOLDER'], filename[:-4])
        os.makedirs(extract_path, exist_ok=True)
        with rarfile.RarFile(filepath, 'r') as rar_ref:
            rar_ref.extractall(extract_path)
        os.remove(filepath)
        return jsonify({'success': True, 'message': f'Archive extracted to {extract_path}'})
    
    return jsonify({'success': True, 'message': 'File uploaded successfully'})

@app.route('/files')
def get_files():
    files = []
    
    for filename in os.listdir(app.config['UPLOAD_FOLDER']):
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        if os.path.isfile(filepath):
            files.append({
                'name': filename,
                'path': filepath.replace('\\', '/'),
                'type': 'file',
                'size': os.path.getsize(filepath)
            })
    
    for dirname in os.listdir(app.config['PROJECTS_FOLDER']):
        dirpath = os.path.join(app.config['PROJECTS_FOLDER'], dirname)
        if os.path.isdir(dirpath):
            files.append({
                'name': dirname,
                'path': dirpath.replace('\\', '/'),
                'type': 'directory',
                'size': 0
            })
    
    return jsonify(files)

@app.route('/project/<path:project_name>')
def get_project_files(project_name):
    project_path = os.path.join(app.config['PROJECTS_FOLDER'], project_name)
    if not os.path.exists(project_path):
        return jsonify({'error': 'Project not found'}), 404
    
    files = []
    for filename in os.listdir(project_path):
        filepath = os.path.join(project_path, filename)
        if os.path.isfile(filepath):
            files.append({
                'name': filename,
                'path': filepath.replace('\\', '/'),
                'type': 'file',
                'size': os.path.getsize(filepath)
            })
    
    return jsonify(files)

@app.route('/execute', methods=['POST'])
def execute_script():
    data = request.json
    command = data.get('command')
    name = data.get('name', 'Unknown')
    cwd = data.get('cwd')
    
    if not command:
        return jsonify({'error': 'No command provided'}), 400
    
    script_id = str(uuid.uuid4())
    process = ScriptProcess(script_id, name, command, cwd)
    
    running_processes[script_id] = process
    process_history.append(process)
    
    process.start()
    
    return jsonify({
        'success': True,
        'script_id': script_id,
        'message': f'Script {name} started'
    })

@app.route('/command', methods=['POST'])
def execute_command():
    data = request.json
    command = data.get('command')
    
    if not command:
        return jsonify({'error': 'No command provided'}), 400
    
    try:
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=30,
            encoding='utf-8',
            errors='replace'
        )
        
        output = result.stdout
        error = result.stderr
        
        return jsonify({
            'success': True,
            'output': output,
            'error': error,
            'return_code': result.returncode
        })
    
    except subprocess.TimeoutExpired:
        return jsonify({
            'success': False,
            'error': 'Command timed out (30s limit)'
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        })

@app.route('/processes')
def get_processes():
    all_processes = running_processes.copy()
    for process in process_history[-50:]:
        if process.id not in all_processes:
            all_processes[process.id] = process
    
    return jsonify([p.to_dict() for p in all_processes.values()])

@app.route('/stop/<script_id>', methods=['POST'])
def stop_script(script_id):
    if script_id in running_processes:
        running_processes[script_id].stop()
        return jsonify({'success': True, 'message': 'Script stopped'})
    
    for process in process_history:
        if process.id == script_id:
            process.stop()
            return jsonify({'success': True, 'message': 'Script stopped'})
    
    return jsonify({'error': 'Script not found'}), 404

@app.route('/delete/<script_id>', methods=['DELETE'])
def delete_script(script_id):
    if script_id in running_processes:
        del running_processes[script_id]
    
    process_history[:] = [p for p in process_history if p.id != script_id]
    
    log_file = os.path.join(app.config['LOGS_FOLDER'], f'{script_id}.log')
    if os.path.exists(log_file):
        os.remove(log_file)
    
    return jsonify({'success': True, 'message': 'Script deleted'})

@app.route('/logs/<script_id>')
def get_logs(script_id):
    if script_id in running_processes:
        logs = running_processes[script_id].get_logs()
        return jsonify({'logs': logs})
    
    for process in process_history:
        if process.id == script_id:
            logs = process.get_logs()
            return jsonify({'logs': logs})
    
    return jsonify({'error': 'Script not found'}), 404

@app.route('/delete-file', methods=['DELETE'])
def delete_file():
    data = request.json
    file_path = data.get('path')
    
    if not file_path:
        return jsonify({'error': 'No file path provided'}), 400
    
    try:
        abs_path = os.path.abspath(file_path)
        upload_path = os.path.abspath(app.config['UPLOAD_FOLDER'])
        projects_path = os.path.abspath(app.config['PROJECTS_FOLDER'])
        
        if not (abs_path.startswith(upload_path) or abs_path.startswith(projects_path)):
            return jsonify({'error': 'Access denied'}), 403
        
        if os.path.isfile(abs_path):
            os.remove(abs_path)
            return jsonify({'success': True, 'message': 'File deleted successfully'})
        elif os.path.isdir(abs_path):
            import shutil
            shutil.rmtree(abs_path)
            return jsonify({'success': True, 'message': 'Directory deleted successfully'})
        else:
            return jsonify({'error': 'File not found'}), 404
            
    except Exception as e:
        return jsonify({'error': f'Failed to delete file: {str(e)}'}), 500

@socketio.on('connect')
def handle_connect():
    print('Client connected')

@socketio.on('disconnect')
def handle_disconnect():
    print('Client disconnected')

if __name__ == '__main__':
    import logging
    log = logging.getLogger('werkzeug')
    log.setLevel(logging.ERROR)
    
    print("🚀 WebPanel запущен!")
    print("📍 Откройте браузер: http://localhost:5000")
    print("🔄 Нажмите Ctrl+C для остановки")
    
    socketio.run(app, host='0.0.0.0', port=5000, debug=False)
EOF

print_success "Файл app.py создан"

# Создание остальных файлов проекта (HTML, CSS, JS)
print_step "Создание frontend файлов..."

cat > templates/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WebPanel - Script Manager</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
</head>
<body>
    <div class="container">
        <header class="glass-panel">
            <h1><i class="fas fa-terminal"></i> WebPanel</h1>
            <p>Advanced Script & File Management System</p>
        </header>

        <nav class="nav-tabs">
            <button class="tab-btn active" data-tab="upload"><i class="fas fa-upload"></i> Upload</button>
            <button class="tab-btn" data-tab="files"><i class="fas fa-folder"></i> Files</button>
            <button class="tab-btn" data-tab="processes"><i class="fas fa-cogs"></i> Processes</button>
            <button class="tab-btn" data-tab="terminal"><i class="fas fa-terminal"></i> Terminal</button>
        </nav>

        <div class="tab-content active" id="upload">
            <div class="glass-panel">
                <h2><i class="fas fa-cloud-upload-alt"></i> Upload Files & Scripts</h2>
                <div class="upload-area" id="uploadArea">
                    <i class="fas fa-cloud-upload-alt upload-icon"></i>
                    <p>Drag & Drop files here or click to browse</p>
                    <p class="upload-info">Supports: .py, .js, .sh, .bat, .zip, .rar</p>
                    <input type="file" id="fileInput" multiple accept=".py,.js,.sh,.bat,.zip,.rar">
                </div>
                <div class="upload-progress" id="uploadProgress" style="display: none;">
                    <div class="progress-bar">
                        <div class="progress-fill"></div>
                    </div>
                    <span class="progress-text">Uploading...</span>
                </div>
            </div>
        </div>

        <div class="tab-content" id="files">
            <div class="glass-panel">
                <h2><i class="fas fa-folder-open"></i> File Manager</h2>
                <div class="file-grid" id="fileGrid">
                    <!-- Files will be loaded here -->
                </div>
            </div>
        </div>

        <div class="tab-content" id="processes">
            <div class="glass-panel">
                <h2><i class="fas fa-tasks"></i> Process Manager</h2>
                <div class="process-controls">
                    <button class="btn btn-refresh" onclick="loadProcesses()">
                        <i class="fas fa-sync-alt"></i> Refresh
                    </button>
                </div>
                <div class="process-list" id="processList">
                    <!-- Processes will be loaded here -->
                </div>
            </div>
        </div>

        <div class="tab-content" id="terminal">
            <div class="glass-panel">
                <h2><i class="fas fa-terminal"></i> Terminal</h2>
                <div class="terminal-controls">
                    <button class="btn btn-clear" onclick="clearTerminal()">
                        <i class="fas fa-trash-alt"></i> Clear
                    </button>
                    <button class="btn btn-new" onclick="newTerminalSession()">
                        <i class="fas fa-plus"></i> New Session
                    </button>
                    <button class="btn btn-refresh" onclick="loadTerminalHistory()">
                        <i class="fas fa-history"></i> History
                    </button>
                </div>
                <div class="terminal-container">
                    <div class="terminal-output" id="terminalOutput">Welcome to WebPanel Terminal!
Type 'help' for available commands.

</div>
                    <div class="terminal-input-container">
                        <span class="terminal-prompt">$</span>
                        <input type="text" class="terminal-input" id="terminalInput" placeholder="Enter command...">
                        <button class="btn btn-execute" onclick="executeCommand()">
                            <i class="fas fa-play"></i>
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="modal" id="logModal">
        <div class="modal-content glass-panel">
            <div class="modal-header">
                <h3><i class="fas fa-file-alt"></i> Script Logs</h3>
                <button class="modal-close" onclick="closeModal()">&times;</button>
            </div>
            <div class="modal-body">
                <pre id="logContent"></pre>
            </div>
        </div>
    </div>

    <div class="modal" id="projectModal">
        <div class="modal-content glass-panel">
            <div class="modal-header">
                <h3><i class="fas fa-folder"></i> Project Files</h3>
                <button class="modal-close" onclick="closeProjectModal()">&times;</button>
            </div>
            <div class="modal-body">
                <div class="project-files" id="projectFiles"></div>
            </div>
        </div>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/socket.io/4.0.1/socket.io.js"></script>
    <script src="{{ url_for('static', filename='js/app.js') }}"></script>
</body>
</html>
EOF

print_info "📄 HTML шаблон создан"

# Создание упрощенного CSS для автоустановки
cat > static/css/style.css << 'EOF'
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    background: linear-gradient(135deg, #0c0e12 0%, #1a1d23 100%);
    color: #c9d1d9;
    min-height: 100vh;
    overflow-x: hidden;
}

.container {
    max-width: 1400px;
    margin: 0 auto;
    padding: 20px;
}

.glass-panel {
    background: rgba(22, 27, 34, 0.4);
    backdrop-filter: blur(20px);
    border: 1px solid rgba(0, 255, 135, 0.1);
    border-radius: 16px;
    padding: 24px;
    margin-bottom: 24px;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
    transition: all 0.3s ease;
}

header h1 {
    font-size: 2.5rem;
    font-weight: 700;
    color: #00ff87;
    margin-bottom: 8px;
}

.nav-tabs {
    display: flex;
    gap: 12px;
    margin-bottom: 24px;
    flex-wrap: wrap;
}

.tab-btn {
    background: rgba(22, 27, 34, 0.6);
    border: 1px solid rgba(0, 255, 135, 0.2);
    border-radius: 12px;
    padding: 12px 20px;
    color: #8b949e;
    cursor: pointer;
    transition: all 0.3s ease;
    font-weight: 500;
    display: flex;
    align-items: center;
    gap: 8px;
}

.tab-btn.active {
    background: rgba(0, 255, 135, 0.15);
    border-color: #00ff87;
    color: #00ff87;
}

.tab-content {
    display: none;
}

.tab-content.active {
    display: block;
    animation: fadeIn 0.3s ease;
}

.upload-area {
    border: 2px dashed rgba(0, 255, 135, 0.3);
    border-radius: 12px;
    padding: 40px;
    text-align: center;
    cursor: pointer;
    transition: all 0.3s ease;
}

.upload-icon {
    font-size: 3rem;
    color: #00ff87;
    margin-bottom: 16px;
}

.file-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
    gap: 16px;
}

.file-item {
    background: rgba(22, 27, 34, 0.5);
    border: 1px solid rgba(0, 255, 135, 0.1);
    border-radius: 12px;
    padding: 20px;
    text-align: center;
    transition: all 0.3s ease;
}

.file-actions {
    display: flex;
    gap: 8px;
    margin-top: 12px;
    justify-content: center;
    flex-wrap: wrap;
}

.btn {
    background: rgba(0, 255, 135, 0.1);
    border: 1px solid rgba(0, 255, 135, 0.3);
    border-radius: 8px;
    padding: 8px 16px;
    color: #00ff87;
    cursor: pointer;
    transition: all 0.3s ease;
    font-size: 0.9rem;
    display: inline-flex;
    align-items: center;
    gap: 6px;
}

.btn:hover {
    background: rgba(0, 255, 135, 0.2);
    transform: translateY(-1px);
}

.btn-delete {
    background: rgba(255, 49, 38, 0.1);
    border-color: rgba(255, 49, 38, 0.3);
    color: #ff6b7a;
}

.btn-delete:hover {
    background: rgba(255, 49, 38, 0.2);
    border-color: rgba(255, 49, 38, 0.5);
}

.process-item {
    background: rgba(22, 27, 34, 0.5);
    border: 1px solid rgba(0, 255, 135, 0.1);
    border-radius: 12px;
    padding: 20px;
    margin-bottom: 16px;
}

.process-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 12px;
}

.process-status {
    padding: 4px 12px;
    border-radius: 16px;
    font-size: 0.8rem;
    font-weight: 600;
}

.status-running {
    background: rgba(0, 255, 135, 0.2);
    color: #00ff87;
}

.status-completed {
    background: rgba(33, 186, 69, 0.2);
    color: #21ba45;
}

.status-failed {
    background: rgba(255, 49, 38, 0.2);
    color: #ff3126;
}

.terminal-controls {
    display: flex;
    gap: 12px;
    margin-bottom: 16px;
    flex-wrap: wrap;
}

.terminal-container {
    background: #010409;
    border: 1px solid rgba(0, 255, 135, 0.2);
    border-radius: 12px;
    overflow: hidden;
}

.terminal-output {
    padding: 20px;
    height: 300px;
    overflow-y: auto;
    font-family: 'Consolas', 'Monaco', monospace;
    font-size: 14px;
    white-space: pre-wrap;
}

.terminal-input-container {
    display: flex;
    align-items: center;
    padding: 16px 20px;
    border-top: 1px solid rgba(0, 255, 135, 0.1);
}

.terminal-prompt {
    color: #00ff87;
    font-weight: bold;
    margin-right: 12px;
    font-family: 'Consolas', 'Monaco', monospace;
}

.terminal-input {
    flex: 1;
    background: transparent;
    border: none;
    color: #c9d1d9;
    font-family: 'Consolas', 'Monaco', monospace;
    outline: none;
}

.modal {
    display: none;
    position: fixed;
    z-index: 1000;
    left: 0;
    top: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.8);
}

.modal-content {
    position: relative;
    margin: 5% auto;
    width: 90%;
    max-width: 800px;
}

.modal-close {
    background: none;
    border: none;
    color: #8b949e;
    font-size: 1.5rem;
    cursor: pointer;
    float: right;
}

.notification {
    position: fixed;
    top: 20px;
    right: 20px;
    background: rgba(22, 27, 34, 0.9);
    border: 1px solid rgba(0, 255, 135, 0.3);
    border-radius: 12px;
    padding: 16px 20px;
    color: #c9d1d9;
    z-index: 1100;
}

@keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
}
EOF

print_info "🎨 CSS стили созданы"

# Создание базового JavaScript
cat > static/js/app.js << 'EOF'
// WebPanel Basic JavaScript
let socket;
let currentProject = null;

// Initialize when page loads
document.addEventListener('DOMContentLoaded', function() {
    initializeSocket();
    initializeTabs();
    initializeUpload();
    initializeTerminal();
    loadFiles();
    loadProcesses();
});

// Socket.IO initialization
function initializeSocket() {
    socket = io();
    
    socket.on('connect', function() {
        console.log('Connected to server');
    });
    
    socket.on('script_output', function(data) {
        const terminalOutput = document.getElementById('terminalOutput');
        if (terminalOutput) {
            terminalOutput.textContent += data.line + '\n';
            terminalOutput.scrollTop = terminalOutput.scrollHeight;
        }
    });
}

// Tab functionality
function initializeTabs() {
    const tabBtns = document.querySelectorAll('.tab-btn');
    const tabContents = document.querySelectorAll('.tab-content');
    
    tabBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            const targetTab = btn.getAttribute('data-tab');
            
            tabBtns.forEach(b => b.classList.remove('active'));
            tabContents.forEach(c => c.classList.remove('active'));
            
            btn.classList.add('active');
            document.getElementById(targetTab).classList.add('active');
            
            if (targetTab === 'files') loadFiles();
            if (targetTab === 'processes') loadProcesses();
        });
    });
}

// File upload functionality
function initializeUpload() {
    const uploadArea = document.getElementById('uploadArea');
    const fileInput = document.getElementById('fileInput');
    
    uploadArea.addEventListener('click', () => fileInput.click());
    
    uploadArea.addEventListener('dragover', (e) => {
        e.preventDefault();
        uploadArea.classList.add('dragover');
    });
    
    uploadArea.addEventListener('dragleave', () => {
        uploadArea.classList.remove('dragover');
    });
    
    uploadArea.addEventListener('drop', (e) => {
        e.preventDefault();
        uploadArea.classList.remove('dragover');
        handleFileUpload(e.dataTransfer.files);
    });
    
    fileInput.addEventListener('change', (e) => {
        handleFileUpload(e.target.files);
    });
}

// Handle file upload
function handleFileUpload(files) {
    const formData = new FormData();
    
    Array.from(files).forEach(file => {
        formData.append('file', file);
    });
    
    fetch('/upload', {
        method: 'POST',
        body: formData
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showNotification('Files uploaded successfully', 'success');
            loadFiles();
        } else {
            showNotification('Upload failed: ' + data.error, 'error');
        }
    })
    .catch(error => {
        showNotification('Upload error: ' + error.message, 'error');
    });
}

// Load files
function loadFiles() {
    fetch('/files')
        .then(response => response.json())
        .then(files => {
            const fileGrid = document.getElementById('fileGrid');
            fileGrid.innerHTML = '';
            
            if (files.length === 0) {
                fileGrid.innerHTML = '<p style="text-align: center;">No files uploaded yet</p>';
                return;
            }
            
            files.forEach(file => {
                const fileItem = createFileItem(file);
                fileGrid.appendChild(fileItem);
            });
        })
        .catch(error => {
            showNotification('Error loading files: ' + error.message, 'error');
        });
}

// Create file item
function createFileItem(file) {
    const div = document.createElement('div');
    div.className = 'file-item';
    
    const icon = file.type === 'directory' ? 'fas fa-folder' : 'fas fa-file';
    
    div.innerHTML = `
        <i class="${icon}"></i>
        <h3>${file.name}</h3>
        <p>${file.type === 'file' ? formatFileSize(file.size) : 'Directory'}</p>
        <div class="file-actions">
            <button class="btn" onclick="executeFile('${file.path}', '${file.name}')">
                <i class="fas fa-play"></i> Run
            </button>
            <button class="btn btn-delete" onclick="deleteFile('${file.path}')">
                <i class="fas fa-trash"></i> Delete
            </button>
        </div>
    `;
    
    return div;
}

// Execute file
function executeFile(filepath, filename) {
    const command = `python3 "${filepath}"`;
    
    fetch('/execute', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            command: command,
            name: filename
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showNotification('Script started successfully', 'success');
            loadProcesses();
        } else {
            showNotification('Failed to start script: ' + data.error, 'error');
        }
    });
}

// Delete file
function deleteFile(filepath) {
    if (!confirm('Are you sure you want to delete this file?')) return;
    
    fetch('/delete-file', {
        method: 'DELETE',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            path: filepath
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showNotification('File deleted successfully', 'success');
            loadFiles();
        } else {
            showNotification('Delete failed: ' + data.error, 'error');
        }
    });
}

// Load processes
function loadProcesses() {
    fetch('/processes')
        .then(response => response.json())
        .then(processes => {
            const processList = document.getElementById('processList');
            processList.innerHTML = '';
            
            if (processes.length === 0) {
                processList.innerHTML = '<p style="text-align: center;">No processes running</p>';
                return;
            }
            
            processes.forEach(process => {
                const processItem = createProcessItem(process);
                processList.appendChild(processItem);
            });
        });
}

// Create process item
function createProcessItem(process) {
    const div = document.createElement('div');
    div.className = 'process-item';
    
    div.innerHTML = `
        <div class="process-header">
            <div class="process-name">${process.name}</div>
            <div class="process-status status-${process.status}">${process.status}</div>
        </div>
        <div class="process-info">
            <p><strong>Command:</strong> ${process.command}</p>
            <p><strong>Started:</strong> ${process.start_time}</p>
            <p><strong>Duration:</strong> ${process.duration}</p>
        </div>
        <div class="process-actions">
            <button class="btn" onclick="viewLogs('${process.id}')">Logs</button>
            ${process.status === 'running' ? 
                `<button class="btn" onclick="stopScript('${process.id}')">Stop</button>` : ''
            }
            <button class="btn btn-delete" onclick="deleteScript('${process.id}')">Delete</button>
        </div>
    `;
    
    return div;
}

// Terminal functionality
function initializeTerminal() {
    const terminalInput = document.getElementById('terminalInput');
    
    terminalInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            executeCommand();
        }
    });
}

// Execute terminal command
function executeCommand() {
    const terminalInput = document.getElementById('terminalInput');
    const terminalOutput = document.getElementById('terminalOutput');
    const command = terminalInput.value.trim();
    
    if (!command) return;
    
    if (command === 'clear') {
        clearTerminal();
        terminalInput.value = '';
        return;
    }
    
    terminalOutput.textContent += `$ ${command}\n`;
    terminalInput.value = '';
    
    fetch('/command', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ command: command })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            terminalOutput.textContent += data.output;
            if (data.error) {
                terminalOutput.textContent += data.error;
            }
        } else {
            terminalOutput.textContent += `Error: ${data.error}\n`;
        }
        terminalOutput.textContent += '\n';
        terminalOutput.scrollTop = terminalOutput.scrollHeight;
    });
}

// Clear terminal
function clearTerminal() {
    const terminalOutput = document.getElementById('terminalOutput');
    terminalOutput.textContent = 'Terminal cleared.\n\n';
}

// New terminal session
function newTerminalSession() {
    const terminalOutput = document.getElementById('terminalOutput');
    terminalOutput.textContent = 'Welcome to WebPanel Terminal!\nType commands below.\n\n';
}

// Load terminal history
function loadTerminalHistory() {
    showNotification('History feature coming soon', 'info');
}

// View logs (placeholder)
function viewLogs(scriptId) {
    showNotification('Logs viewer coming soon', 'info');
}

// Stop script
function stopScript(scriptId) {
    fetch(`/stop/${scriptId}`, {
        method: 'POST'
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showNotification('Script stopped', 'success');
            loadProcesses();
        }
    });
}

// Delete script
function deleteScript(scriptId) {
    if (!confirm('Delete this script record?')) return;
    
    fetch(`/delete/${scriptId}`, {
        method: 'DELETE'
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showNotification('Script deleted', 'success');
            loadProcesses();
        }
    });
}

// Utility functions
function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

function showNotification(message, type = 'success') {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.remove();
    }, 4000);
}

// Modal functions (placeholders)
function closeModal() {
    // Placeholder
}

function closeProjectModal() {
    // Placeholder  
}
EOF

print_info "⚡ Базовый JavaScript создан"
print_info "📦 Все основные файлы готовы"

# =====================================
# 🎯 СОЗДАНИЕ ДЕМО ФАЙЛОВ
# =====================================

print_step "Создание демо скриптов..."

cat > demo/test_script.py << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time
import random

print("🚀 WebPanel Demo Script Started!")
print("📋 Testing script execution on Ubuntu...")

for i in range(1, 6):
    print(f"⏳ Step {i}/5: Processing...")
    time.sleep(random.uniform(0.5, 1.5))
    
    if i == 3:
        print("🔄 Halfway done!")

print("✅ Demo script completed successfully!")
print("🎉 WebPanel is working correctly on Ubuntu!")
EOF

cat > demo/long_running.py << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time

print("🔄 Long running script started...")
print("⏰ This script will run for 60 seconds")

for i in range(60):
    print(f"⏳ Second {i+1}/60 - Still running...")
    time.sleep(1)

print("✅ Long running script completed!")
EOF

chmod +x demo/*.py

# =====================================
# 🔧 НАСТРОЙКА СЛУЖБЫ (опционально)
# =====================================

if [[ $EUID -eq 0 ]]; then
    print_step "Создание systemd службы..."
    
    cat > /etc/systemd/system/webpanel.service << EOF
[Unit]
Description=WebPanel - Script Manager
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$INSTALL_DIR
Environment=PATH=$INSTALL_DIR/venv/bin
Environment=PYTHONIOENCODING=utf-8
Environment=LANG=en_US.UTF-8
Environment=LC_ALL=en_US.UTF-8
ExecStart=$INSTALL_DIR/venv/bin/python app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    chown -R www-data:www-data "$INSTALL_DIR"
    chmod -R 755 "$INSTALL_DIR"
    chmod -R 777 "$INSTALL_DIR"/{uploads,projects,logs}
    
    systemctl daemon-reload
    systemctl enable webpanel
    
    print_success "Служба webpanel настроена"
fi

# =====================================
# 🌐 НАСТРОЙКА FIREWALL
# =====================================

print_step "Настройка firewall..."
if command -v ufw >/dev/null 2>&1; then
    $USE_SUDO ufw allow 5000/tcp
    print_success "Порт 5000 открыт в firewall"
fi

# =====================================
# 🎉 ЗАВЕРШЕНИЕ УСТАНОВКИ
# =====================================

print_success "✅ Установка WebPanel завершена!"
echo ""
echo -e "${GREEN}📍 Расположение: ${YELLOW}$INSTALL_DIR${NC}"
echo -e "${GREEN}📦 Что установлено:${NC}"
echo -e "${CYAN}   ✅ Python Flask сервер (app.py)${NC}"
echo -e "${CYAN}   ✅ Веб-интерфейс (HTML/CSS/JS)${NC}"
echo -e "${CYAN}   ✅ Все зависимости (requirements.txt)${NC}"
echo -e "${CYAN}   ✅ Демо скрипты для тестирования${NC}"
echo -e "${CYAN}   ✅ Виртуальное окружение${NC}"
echo ""
echo -e "${GREEN}🚀 Для запуска сервера:${NC}"
echo -e "${CYAN}   cd $INSTALL_DIR${NC}"
echo -e "${CYAN}   source venv/bin/activate${NC}"
echo -e "${CYAN}   python app.py${NC}"
echo ""

if [[ $EUID -eq 0 ]]; then
    echo -e "${GREEN}🔧 Управление службой:${NC}"
    echo -e "${CYAN}   sudo systemctl start webpanel${NC}"
    echo -e "${CYAN}   sudo systemctl stop webpanel${NC}"
    echo -e "${CYAN}   sudo systemctl status webpanel${NC}"
    echo ""
fi

echo -e "${GREEN}🌐 После запуска откройте:${NC}"
echo -e "${CYAN}   http://localhost:5000${NC}"
echo -e "${CYAN}   http://$(hostname -I | awk '{print $1}'):5000${NC}"
echo ""

read -p "🚀 Запустить WebPanel сейчас? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "Запуск WebPanel..."
    cd "$INSTALL_DIR"
    source venv/bin/activate
    
    if [[ $EUID -eq 0 ]]; then
        systemctl start webpanel
        print_success "WebPanel запущен как служба"
        print_info "Статус: sudo systemctl status webpanel"
    else
        print_info "Запуск в режиме разработки..."
        python app.py
    fi
else
    print_info "Для запуска используйте команды выше"
fi

print_success "🎉 WebPanel готов к работе!" 