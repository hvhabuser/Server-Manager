// Global variables
let socket;
let currentProject = null;
let logUpdateInterval = null;

// Initialize the application
document.addEventListener('DOMContentLoaded', function() {
    initializeSocket();
    initializeTabs();
    initializeUpload();
    initializeTerminal();
    loadFiles();
    loadProcesses();
    
    // Auto-refresh processes every 5 seconds
    setInterval(loadProcesses, 5000);
});

// Socket.IO initialization
function initializeSocket() {
    socket = io();
    
    socket.on('connect', function() {
        console.log('Connected to server');
    });
    
    socket.on('script_output', function(data) {
        // Real-time log updates (if log modal is open for this script)
        if (document.getElementById('logModal').style.display === 'block' && 
            document.getElementById('logModal').getAttribute('data-script-id') === data.script_id) {
            const logContent = document.getElementById('logContent');
            logContent.textContent += data.line + '\n';
            logContent.scrollTop = logContent.scrollHeight;
        }
    });
    
    socket.on('disconnect', function() {
        console.log('Disconnected from server');
    });
}

// Tab functionality
function initializeTabs() {
    const tabBtns = document.querySelectorAll('.tab-btn');
    const tabContents = document.querySelectorAll('.tab-content');
    
    tabBtns.forEach(btn => {
        btn.addEventListener('click', function() {
            const tabId = this.getAttribute('data-tab');
            
            // Remove active class from all tabs and contents
            tabBtns.forEach(b => b.classList.remove('active'));
            tabContents.forEach(c => c.classList.remove('active'));
            
            // Add active class to clicked tab and corresponding content
            this.classList.add('active');
            document.getElementById(tabId).classList.add('active');
            
            // Load data based on active tab
            if (tabId === 'files') {
                loadFiles();
            } else if (tabId === 'processes') {
                loadProcesses();
            }
        });
    });
}

// Upload functionality
function initializeUpload() {
    const uploadArea = document.getElementById('uploadArea');
    const fileInput = document.getElementById('fileInput');
    
    // Click to upload
    uploadArea.addEventListener('click', function() {
        fileInput.click();
    });
    
    // Drag and drop
    uploadArea.addEventListener('dragover', function(e) {
        e.preventDefault();
        uploadArea.classList.add('dragover');
    });
    
    uploadArea.addEventListener('dragleave', function() {
        uploadArea.classList.remove('dragover');
    });
    
    uploadArea.addEventListener('drop', function(e) {
        e.preventDefault();
        uploadArea.classList.remove('dragover');
        
        const files = e.dataTransfer.files;
        handleFileUpload(files);
    });
    
    // File input change
    fileInput.addEventListener('change', function() {
        handleFileUpload(this.files);
    });
}

// Handle file upload
function handleFileUpload(files) {
    if (files.length === 0) return;
    
    const uploadProgress = document.getElementById('uploadProgress');
    const progressFill = uploadProgress.querySelector('.progress-fill');
    const progressText = uploadProgress.querySelector('.progress-text');
    
    uploadProgress.style.display = 'block';
    
    Array.from(files).forEach((file, index) => {
        const formData = new FormData();
        formData.append('file', file);
        
        fetch('/upload', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                showNotification('File uploaded successfully: ' + file.name, 'success');
            } else {
                showNotification('Upload failed: ' + data.error, 'error');
            }
            
            // Update progress
            const progress = ((index + 1) / files.length) * 100;
            progressFill.style.width = progress + '%';
            progressText.textContent = `Uploaded ${index + 1} of ${files.length} files`;
            
            if (index === files.length - 1) {
                setTimeout(() => {
                    uploadProgress.style.display = 'none';
                    loadFiles(); // Refresh file list
                }, 1000);
            }
        })
        .catch(error => {
            showNotification('Upload error: ' + error.message, 'error');
        });
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
                fileGrid.innerHTML = '<p style="text-align: center; color: #8b949e;">No files uploaded yet</p>';
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

// Create file item element
function createFileItem(file) {
    const div = document.createElement('div');
    div.className = 'file-item';
    
    const icon = file.type === 'directory' ? 'fas fa-folder' : getFileIcon(file.name);
    const size = file.type === 'file' ? formatFileSize(file.size) : 'Directory';
    
    div.innerHTML = `
        <i class="${icon}"></i>
        <h3>${file.name}</h3>
        <p>${size}</p>
        <div class="file-actions">
            ${file.type === 'directory' ? 
                `<button class="btn" onclick="openProject('${file.name}')">
                    <i class="fas fa-folder-open"></i> Open
                </button>
                <button class="btn btn-delete" onclick="deleteFile('${file.path}')">
                    <i class="fas fa-trash"></i> Delete
                </button>` :
                `<button class="btn" onclick="executeFile('${file.path}', '${file.name}')">
                    <i class="fas fa-play"></i> Run
                </button>
                <button class="btn btn-delete" onclick="deleteFile('${file.path}')">
                    <i class="fas fa-trash"></i> Delete
                </button>`
            }
        </div>
    `;
    
    return div;
}

// Get file icon based on extension
function getFileIcon(filename) {
    const ext = filename.split('.').pop().toLowerCase();
    const iconMap = {
        'py': 'fab fa-python',
        'js': 'fab fa-js-square',
        'sh': 'fas fa-terminal',
        'bat': 'fas fa-terminal',
        'zip': 'fas fa-file-archive',
        'rar': 'fas fa-file-archive'
    };
    return iconMap[ext] || 'fas fa-file';
}

// Format file size
function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// Execute file
function executeFile(filepath, filename) {
    const command = getExecuteCommand(filepath, filename);
    const cwd = filepath.includes('/projects/') ? filepath.substring(0, filepath.lastIndexOf('/')) : null;
    
    fetch('/execute', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            command: command,
            name: filename,
            cwd: cwd
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
    })
    .catch(error => {
        showNotification('Error: ' + error.message, 'error');
    });
}

// Get execute command based on file type
function getExecuteCommand(filepath, filename) {
    const ext = filename.split('.').pop().toLowerCase();
    // Нормализуем путь для Windows
    const normalizedPath = filepath.replace(/\\/g, '/');
    const commands = {
        'py': `python "${normalizedPath}"`,
        'js': `node "${normalizedPath}"`,
        'sh': `bash "${normalizedPath}"`,
        'bat': `"${normalizedPath}"`
    };
    return commands[ext] || `"${normalizedPath}"`;
}

// Open project
function openProject(projectName) {
    currentProject = projectName;
    
    fetch(`/project/${projectName}`)
        .then(response => response.json())
        .then(files => {
            const projectFiles = document.getElementById('projectFiles');
            projectFiles.innerHTML = '';
            
            files.forEach(file => {
                const fileItem = createProjectFileItem(file, projectName);
                projectFiles.appendChild(fileItem);
            });
            
            document.getElementById('projectModal').style.display = 'block';
        })
        .catch(error => {
            showNotification('Error loading project: ' + error.message, 'error');
        });
}

// Create project file item
function createProjectFileItem(file, projectName) {
    const div = document.createElement('div');
    div.className = 'project-file-item';
    
    const icon = file.type === 'directory' ? 'fas fa-folder' : getFileIcon(file.name);
    const size = file.type === 'file' ? formatFileSize(file.size) : 'Directory';
    
    div.innerHTML = `
        <i class="${icon}"></i>
        <h4>${file.name}</h4>
        <p>${size}</p>
        ${file.type === 'file' ? 
            `<button class="btn" onclick="executeProjectFile('${file.path}', '${file.name}', '${projectName}')">
                <i class="fas fa-play"></i> Run
            </button>` : ''
        }
    `;
    
    return div;
}

// Execute project file
function executeProjectFile(filepath, filename, projectName) {
    const command = getExecuteCommand(filepath, filename);
    const cwd = `projects/${projectName}`;
    
    fetch('/execute', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            command: command,
            name: `${projectName}/${filename}`,
            cwd: cwd
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showNotification('Script started successfully', 'success');
            closeProjectModal();
            loadProcesses();
        } else {
            showNotification('Failed to start script: ' + data.error, 'error');
        }
    })
    .catch(error => {
        showNotification('Error: ' + error.message, 'error');
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
                processList.innerHTML = '<p style="text-align: center; color: #8b949e;">No processes running</p>';
                return;
            }
            
            processes.forEach(process => {
                const processItem = createProcessItem(process);
                processList.appendChild(processItem);
            });
        })
        .catch(error => {
            showNotification('Error loading processes: ' + error.message, 'error');
        });
}

// Create process item element
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
            ${process.end_time ? `<p><strong>Ended:</strong> ${process.end_time}</p>` : ''}
            <p><strong>Duration:</strong> ${process.duration}</p>
        </div>
        <div class="process-actions">
            <button class="btn" onclick="viewLogs('${process.id}')">
                <i class="fas fa-file-alt"></i> Logs
            </button>
            ${process.status === 'running' ? 
                `<button class="btn btn-warning" onclick="stopScript('${process.id}')">
                    <i class="fas fa-stop"></i> Stop
                </button>` : ''
            }
            <button class="btn btn-danger" onclick="deleteScript('${process.id}')">
                <i class="fas fa-trash"></i> Delete
            </button>
        </div>
    `;
    
    return div;
}

// View logs
function viewLogs(scriptId) {
    fetch(`/logs/${scriptId}`)
        .then(response => response.json())
        .then(data => {
            const logContent = document.getElementById('logContent');
            logContent.textContent = data.logs || 'No logs available';
            
            const logModal = document.getElementById('logModal');
            logModal.setAttribute('data-script-id', scriptId);
            logModal.style.display = 'block';
            
            // Auto-scroll to bottom
            logContent.scrollTop = logContent.scrollHeight;
        })
        .catch(error => {
            showNotification('Error loading logs: ' + error.message, 'error');
        });
}

// Stop script
function stopScript(scriptId) {
    if (!confirm('Are you sure you want to stop this script?')) return;
    
    fetch(`/stop/${scriptId}`, {
        method: 'POST'
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showNotification('Script stopped successfully', 'success');
            loadProcesses();
        } else {
            showNotification('Failed to stop script: ' + data.error, 'error');
        }
    })
    .catch(error => {
        showNotification('Error: ' + error.message, 'error');
    });
}

// Delete script
function deleteScript(scriptId) {
    if (!confirm('Are you sure you want to delete this script record?')) return;
    
    fetch(`/delete/${scriptId}`, {
        method: 'DELETE'
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showNotification('Script deleted successfully', 'success');
            loadProcesses();
        } else {
            showNotification('Failed to delete script: ' + data.error, 'error');
        }
    })
    .catch(error => {
        showNotification('Error: ' + error.message, 'error');
    });
}

// Delete file
function deleteFile(filepath) {
    if (!confirm('Вы уверены, что хотите удалить этот файл?')) {
        return;
    }
    
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
            showNotification(data.message, 'success');
            loadFiles();
        } else {
            showNotification('Ошибка удаления: ' + data.error, 'error');
        }
    })
    .catch(error => {
        showNotification('Ошибка: ' + error.message, 'error');
    });
}

// Terminal functionality
function initializeTerminal() {
    const terminalInput = document.getElementById('terminalInput');
    
    // Load history from storage
    loadHistoryFromStorage();
    
    terminalInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            executeCommand();
        }
    });
    
    // Add history navigation with arrow keys
    terminalInput.addEventListener('keydown', function(e) {
        if (e.key === 'ArrowUp') {
            e.preventDefault();
            if (historyIndex > 0) {
                historyIndex--;
                terminalInput.value = commandHistory[historyIndex] || '';
            }
        } else if (e.key === 'ArrowDown') {
            e.preventDefault();
            if (historyIndex < commandHistory.length) {
                historyIndex++;
                terminalInput.value = commandHistory[historyIndex] || '';
            }
        }
    });
}

// Execute terminal command
function executeCommand() {
    const terminalInput = document.getElementById('terminalInput');
    const terminalOutput = document.getElementById('terminalOutput');
    const command = terminalInput.value.trim();
    
    if (!command) return;
    
    // Handle built-in commands
    if (command === 'clear') {
        clearTerminal();
        terminalInput.value = '';
        return;
    }
    
    if (command === 'help') {
        terminalOutput.textContent += `$ ${command}\n`;
        terminalOutput.textContent += `Available commands:
  help     - Show this help message
  clear    - Clear terminal output
  ls       - List files
  pwd      - Show current directory
  python   - Run Python scripts
  
Use system commands as normal.

`;
        terminalInput.value = '';
        terminalOutput.scrollTop = terminalOutput.scrollHeight;
        return;
    }
    
    // Add command to output and history
    terminalOutput.textContent += `$ ${command}\n`;
    addToHistory(command);
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
    })
    .catch(error => {
        terminalOutput.textContent += `Error: ${error.message}\n\n`;
        terminalOutput.scrollTop = terminalOutput.scrollHeight;
    });
}

// Clear terminal output
function clearTerminal() {
    const terminalOutput = document.getElementById('terminalOutput');
    terminalOutput.textContent = 'Terminal cleared.\n\n';
    showNotification('Терминал очищен', 'success');
}

// Create new terminal session
function newTerminalSession() {
    const terminalOutput = document.getElementById('terminalOutput');
    terminalOutput.textContent = `Welcome to WebPanel Terminal!
Type 'help' for available commands.

=== New Terminal Session Started ===

`;
    clearHistory();
    showNotification('Новая сессия терминала запущена', 'success');
}

// Terminal history management
let commandHistory = [];
let historyIndex = -1;

function addToHistory(command) {
    commandHistory.push(command);
    if (commandHistory.length > 100) {
        commandHistory.shift(); // Keep only last 100 commands
    }
    historyIndex = commandHistory.length;
    saveHistoryToStorage();
}

function clearHistory() {
    commandHistory = [];
    historyIndex = -1;
    saveHistoryToStorage();
}

function loadTerminalHistory() {
    const terminalOutput = document.getElementById('terminalOutput');
    if (commandHistory.length === 0) {
        terminalOutput.textContent += 'No command history available.\n\n';
    } else {
        terminalOutput.textContent += `Command History (last ${Math.min(10, commandHistory.length)} commands):
${commandHistory.slice(-10).map((cmd, i) => `${i + 1}. ${cmd}`).join('\n')}

`;
    }
    terminalOutput.scrollTop = terminalOutput.scrollHeight;
    showNotification('История команд загружена', 'success');
}

function saveHistoryToStorage() {
    try {
        localStorage.setItem('webpanel_terminal_history', JSON.stringify(commandHistory));
    } catch (e) {
        console.warn('Failed to save terminal history to localStorage');
    }
}

function loadHistoryFromStorage() {
    try {
        const saved = localStorage.getItem('webpanel_terminal_history');
        if (saved) {
            commandHistory = JSON.parse(saved);
            historyIndex = commandHistory.length;
        }
    } catch (e) {
        console.warn('Failed to load terminal history from localStorage');
    }
}

// Modal functions
function closeModal() {
    document.getElementById('logModal').style.display = 'none';
}

function closeProjectModal() {
    document.getElementById('projectModal').style.display = 'none';
}

// Close modals when clicking outside
window.addEventListener('click', function(e) {
    const logModal = document.getElementById('logModal');
    const projectModal = document.getElementById('projectModal');
    
    if (e.target === logModal) {
        closeModal();
    }
    if (e.target === projectModal) {
        closeProjectModal();
    }
});

// Show notification
function showNotification(message, type = 'success') {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.remove();
    }, 4000);
} 