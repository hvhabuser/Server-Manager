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
app.config['SECRET_KEY'] = 'your-secret-key-here'
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
            with open(self.log_file, 'w') as log:
                self.process = subprocess.Popen(
                    self.command,
                    shell=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    cwd=self.cwd,
                    bufsize=1,
                    universal_newlines=True
                )
                self.status = 'running'
                
                # Запуск мониторинга вывода в отдельном потоке
                threading.Thread(target=self._monitor_output, daemon=True).start()
                
        except Exception as e:
            self.status = 'error'
            self.end_time = datetime.now()
            with open(self.log_file, 'w') as log:
                log.write(f"Error starting process: {str(e)}")
    
    def _monitor_output(self):
        try:
            with open(self.log_file, 'a') as log:
                for line in iter(self.process.stdout.readline, ''):
                    if line:
                        log.write(line)
                        log.flush()
                        self.output_lines.append(line.strip())
                        # Отправка в реальном времени через WebSocket
                        socketio.emit('script_output', {
                            'script_id': self.id,
                            'line': line.strip()
                        })
                
                self.process.wait()
                self.status = 'completed' if self.process.returncode == 0 else 'failed'
                self.end_time = datetime.now()
                
                # Удаление из running_processes
                if self.id in running_processes:
                    del running_processes[self.id]
                    
        except Exception as e:
            self.status = 'error'
            self.end_time = datetime.now()
    
    def stop(self):
        if self.process and self.process.poll() is None:
            try:
                # Попытка корректно завершить процесс
                parent = psutil.Process(self.process.pid)
                children = parent.children(recursive=True)
                for child in children:
                    child.terminate()
                parent.terminate()
                
                # Ждем немного и потом принудительно завершаем
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
            with open(self.log_file, 'r') as log:
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
    
    # Если это архив, распаковываем его
    if filename.lower().endswith('.zip'):
        extract_path = os.path.join(app.config['PROJECTS_FOLDER'], filename[:-4])
        os.makedirs(extract_path, exist_ok=True)
        with zipfile.ZipFile(filepath, 'r') as zip_ref:
            zip_ref.extractall(extract_path)
        os.remove(filepath)  # Удаляем архив после распаковки
        return jsonify({'success': True, 'message': f'Archive extracted to {extract_path}'})
    
    elif filename.lower().endswith('.rar'):
        extract_path = os.path.join(app.config['PROJECTS_FOLDER'], filename[:-4])
        os.makedirs(extract_path, exist_ok=True)
        with rarfile.RarFile(filepath, 'r') as rar_ref:
            rar_ref.extractall(extract_path)
        os.remove(filepath)  # Удаляем архив после распаковки
        return jsonify({'success': True, 'message': f'Archive extracted to {extract_path}'})
    
    return jsonify({'success': True, 'message': 'File uploaded successfully'})

@app.route('/files')
def get_files():
    files = []
    
    # Загруженные файлы
    for filename in os.listdir(app.config['UPLOAD_FOLDER']):
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        if os.path.isfile(filepath):
            files.append({
                'name': filename,
                'path': filepath,
                'type': 'file',
                'size': os.path.getsize(filepath)
            })
    
    # Проекты (папки)
    for dirname in os.listdir(app.config['PROJECTS_FOLDER']):
        dirpath = os.path.join(app.config['PROJECTS_FOLDER'], dirname)
        if os.path.isdir(dirpath):
            files.append({
                'name': dirname,
                'path': dirpath,
                'type': 'directory'
            })
    
    return jsonify(files)

@app.route('/project/<path:project_name>')
def get_project_files(project_name):
    project_path = os.path.join(app.config['PROJECTS_FOLDER'], project_name)
    if not os.path.exists(project_path):
        return jsonify({'error': 'Project not found'}), 404
    
    files = []
    for item in os.listdir(project_path):
        item_path = os.path.join(project_path, item)
        files.append({
            'name': item,
            'path': item_path,
            'type': 'directory' if os.path.isdir(item_path) else 'file',
            'size': os.path.getsize(item_path) if os.path.isfile(item_path) else 0
        })
    
    return jsonify(files)

@app.route('/execute', methods=['POST'])
def execute_script():
    data = request.json
    command = data.get('command')
    cwd = data.get('cwd', None)
    name = data.get('name', 'Script')
    
    if not command:
        return jsonify({'error': 'No command provided'}), 400
    
    script_id = str(uuid.uuid4())
    script_process = ScriptProcess(script_id, name, command, cwd)
    
    running_processes[script_id] = script_process
    process_history.append(script_process)
    
    script_process.start()
    
    return jsonify({
        'success': True,
        'script_id': script_id,
        'message': 'Script started successfully'
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
            timeout=30
        )
        
        return jsonify({
            'success': True,
            'output': result.stdout,
            'error': result.stderr,
            'returncode': result.returncode
        })
    except subprocess.TimeoutExpired:
        return jsonify({'error': 'Command timed out'}), 408
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/processes')
def get_processes():
    processes = []
    
    # Добавляем запущенные процессы
    for process in running_processes.values():
        processes.append(process.to_dict())
    
    # Добавляем завершенные процессы
    for process in process_history:
        if process.id not in running_processes:
            processes.append(process.to_dict())
    
    return jsonify(processes)

@app.route('/stop/<script_id>', methods=['POST'])
def stop_script(script_id):
    if script_id in running_processes:
        running_processes[script_id].stop()
        return jsonify({'success': True, 'message': 'Script stopped'})
    
    # Поиск в истории
    for process in process_history:
        if process.id == script_id:
            process.stop()
            return jsonify({'success': True, 'message': 'Script stopped'})
    
    return jsonify({'error': 'Script not found'}), 404

@app.route('/delete/<script_id>', methods=['DELETE'])
def delete_script(script_id):
    # Удаление из running_processes
    if script_id in running_processes:
        running_processes[script_id].stop()
        del running_processes[script_id]
    
    # Удаление из истории
    global process_history
    process_history = [p for p in process_history if p.id != script_id]
    
    # Удаление лог файла
    log_file = os.path.join(app.config['LOGS_FOLDER'], f'{script_id}.log')
    if os.path.exists(log_file):
        os.remove(log_file)
    
    return jsonify({'success': True, 'message': 'Script deleted'})

@app.route('/logs/<script_id>')
def get_logs(script_id):
    # Поиск в запущенных процессах
    if script_id in running_processes:
        return jsonify({
            'logs': running_processes[script_id].get_logs(),
            'status': running_processes[script_id].status
        })
    
    # Поиск в истории
    for process in process_history:
        if process.id == script_id:
            return jsonify({
                'logs': process.get_logs(),
                'status': process.status
            })
    
    return jsonify({'error': 'Script not found'}), 404

@socketio.on('connect')
def handle_connect():
    print('Client connected')

@socketio.on('disconnect')
def handle_disconnect():
    print('Client disconnected')

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)