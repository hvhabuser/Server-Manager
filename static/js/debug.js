// Диагностика для веб-панели
console.log('🔧 Debug script loaded');

// Проверка загрузки DOM
document.addEventListener('DOMContentLoaded', function() {
    console.log('✅ DOM loaded');
    
    // Проверка наличия элементов
    const elements = [
        'upload', 'files', 'processes', 'terminal',
        'uploadArea', 'fileGrid', 'processList', 'terminalOutput'
    ];
    
    elements.forEach(id => {
        const element = document.getElementById(id);
        if (element) {
            console.log(`✅ Element found: ${id}`);
        } else {
            console.error(`❌ Element missing: ${id}`);
        }
    });
    
    // Проверка кнопок табов
    const tabBtns = document.querySelectorAll('.tab-btn');
    console.log(`📋 Found ${tabBtns.length} tab buttons`);
    
    // Проверка Socket.IO
    if (typeof io !== 'undefined') {
        console.log('✅ Socket.IO loaded');
    } else {
        console.error('❌ Socket.IO not loaded');
    }
    
    // Принудительная активация вкладки Files
    setTimeout(() => {
        console.log('🔄 Force activating Files tab');
        const filesTab = document.querySelector('[data-tab="files"]');
        const filesContent = document.getElementById('files');
        
        if (filesTab && filesContent) {
            // Убираем активный класс со всех
            document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
            
            // Активируем Files
            filesTab.classList.add('active');
            filesContent.classList.add('active');
            
            console.log('✅ Files tab activated');
            
            // Загружаем файлы
            fetch('/files')
                .then(response => response.json())
                .then(files => {
                    console.log('📁 Files loaded:', files);
                    const fileGrid = document.getElementById('fileGrid');
                    if (fileGrid) {
                        fileGrid.innerHTML = '<p style="color: #00ff87;">Файлы найдены: ' + files.length + '</p>';
                    }
                })
                .catch(error => {
                    console.error('❌ Error loading files:', error);
                });
        }
    }, 1000);
}); 