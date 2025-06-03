from flask import Flask, render_template, request, jsonify, send_from_directory
import os
import subprocess

import threading
import time
from werkzeug.utils import secure_filename
from datetime import datetime
import json

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = 'uploads'
app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024

os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

running_processes = {}
process_logs = {}

ALLOWED_EXTENSIONS = {'py', 'js', 'sh', 'bat', 'txt', 'exe'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

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
    
    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(filepath)
        return jsonify({'message': f'File {filename} uploaded successfully', 'filename': filename})
    
    return jsonify({'error': 'File type not allowed'}), 400

@app.route('/files')
def list_files():
    files = []
    for filename in os.listdir(app.config['UPLOAD_FOLDER']):
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        if os.path.isfile(filepath):
            stat = os.stat(filepath)
            files.append({
                'name': filename,
                'size': stat.st_size,
                'modified': datetime.fromtimestamp(stat.st_mtime).strftime('%Y-%m-%d %H:%M:%S')
            })
    return jsonify(files)

@app.route('/execute', methods=['POST'])
def execute_command():
    data = request.json
    command = data.get('command', '')
    
    if not command:
        return jsonify({'error': 'No command provided'}), 400
    
    try:
        process_id = str(int(time.time() * 1000))
        
        def run_process():
            try:
                process = subprocess.Popen(
                    command,
                    shell=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                    cwd=app.config['UPLOAD_FOLDER']
                )
                
                running_processes[process_id] = {
                    'process': process,
                    'command': command,
                    'start_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                    'status': 'running'
                }
                
                stdout, stderr = process.communicate()
                
                process_logs[process_id] = {
                    'stdout': stdout,
                    'stderr': stderr,
                    'return_code': process.returncode,
                    'command': command,
                    'start_time': running_processes[process_id]['start_time'],
                    'end_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                }
                
                if process_id in running_processes:
                    running_processes[process_id]['status'] = 'completed'
                
            except Exception as e:
                process_logs[process_id] = {
                    'error': str(e),
                    'command': command,
                    'start_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                }
                if process_id in running_processes:
                    running_processes[process_id]['status'] = 'error'
        
        thread = threading.Thread(target=run_process)
        thread.daemon = True
        thread.start()
        
        return jsonify({'message': 'Command started', 'process_id': process_id})
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/processes')
def list_processes():
    processes = []
    for pid, info in running_processes.items():
        try:
            if 'process' in info and info['process'].poll() is None:
                status = 'running'
            else:
                status = info.get('status', 'completed')
        except:
            status = 'unknown'
        
        processes.append({
            'id': pid,
            'command': info['command'],
            'start_time': info['start_time'],
            'status': status
        })
    
    return jsonify(processes)

@app.route('/kill/<process_id>', methods=['POST'])
def kill_process(process_id):
    if process_id in running_processes:
        try:
            process = running_processes[process_id]['process']
            if process.poll() is None:
                process.terminate()
                time.sleep(1)
                if process.poll() is None:
                    process.kill()
                running_processes[process_id]['status'] = 'killed'
                return jsonify({'message': 'Process terminated'})
            else:
                return jsonify({'message': 'Process already finished'})
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    else:
        return jsonify({'error': 'Process not found'}), 404

@app.route('/logs/<process_id>')
def get_logs(process_id):
    if process_id in process_logs:
        return jsonify(process_logs[process_id])
    else:
        return jsonify({'error': 'Logs not found'}), 404

@app.route('/delete/<filename>', methods=['DELETE'])
def delete_file(filename):
    try:
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], secure_filename(filename))
        if os.path.exists(filepath):
            os.remove(filepath)
            return jsonify({'message': f'File {filename} deleted successfully'})
        else:
            return jsonify({'error': 'File not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500



if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True) 