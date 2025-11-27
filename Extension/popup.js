// Universal Browser Extension - Popup Script
class UniversalBrowserPopup {
    constructor() {
        this.currentTab = null;
        this.profiles = [];
        this.settings = {
            monitorInterval: 30,
            autoRecovery: true,
            notifications: true,
            debugMode: false
        };
        
        this.init();
    }

    async init() {
        await this.loadSettings();
        await this.loadProfiles();
        await this.getCurrentTab();
        
        this.setupEventListeners();
        this.updateUI();
        this.startStatUpdates();
    }

    async getCurrentTab() {
        try {
            const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
            this.currentTab = tab;
        } catch (error) {
            console.error('Error getting current tab:', error);
        }
    }

    async loadSettings() {
        try {
            const result = await chrome.storage.sync.get('settings');
            if (result.settings) {
                this.settings = { ...this.settings, ...result.settings };
            }
        } catch (error) {
            console.error('Error loading settings:', error);
        }
    }

    async loadProfiles() {
        try {
            const result = await chrome.storage.sync.get('profiles');
            this.profiles = result.profiles || [];
        } catch (error) {
            console.error('Error loading profiles:', error);
            this.profiles = [];
        }
    }

    async saveSettings() {
        try {
            await chrome.storage.sync.set({ settings: this.settings });
        } catch (error) {
            console.error('Error saving settings:', error);
        }
    }

    async saveProfiles() {
        try {
            await chrome.storage.sync.set({ profiles: this.profiles });
        } catch (error) {
            console.error('Error saving profiles:', error);
        }
    }

    setupEventListeners() {
        // Tab switching
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.switchTab(e.target.dataset.tab);
            });
        });

        // Monitor tab events
        document.getElementById('add-profile').addEventListener('click', () => {
            this.addCurrentSiteProfile();
        });

        document.getElementById('toggle-monitor').addEventListener('click', () => {
            this.toggleMonitoring();
        });

        // Profile tab events
        document.getElementById('new-profile').addEventListener('click', () => {
            this.showNewProfileDialog();
        });

        document.querySelectorAll('.quick-profile').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.addPredefinedProfile(e.target.closest('.quick-profile').dataset.profile);
            });
        });

        // Settings tab events
        document.getElementById('monitor-interval').addEventListener('change', (e) => {
            this.settings.monitorInterval = parseInt(e.target.value);
            this.saveSettings();
        });

        document.getElementById('auto-recovery').addEventListener('change', (e) => {
            this.settings.autoRecovery = e.target.checked;
            this.saveSettings();
        });

        document.getElementById('notifications').addEventListener('change', (e) => {
            this.settings.notifications = e.target.checked;
            this.saveSettings();
        });

        document.getElementById('debug-mode').addEventListener('change', (e) => {
            this.settings.debugMode = e.target.checked;
            this.saveSettings();
        });

        document.getElementById('export-profiles').addEventListener('click', () => {
            this.exportProfiles();
        });

        document.getElementById('import-profiles').addEventListener('click', () => {
            this.importProfiles();
        });
    }

    switchTab(tabName) {
        // Update tab buttons
        document.querySelectorAll('.tab-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');

        // Update tab content
        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.remove('active');
        });
        document.getElementById(tabName).classList.add('active');

        // Refresh content if needed
        if (tabName === 'profiles') {
            this.updateProfilesList();
        } else if (tabName === 'settings') {
            this.updateSettingsForm();
        }
    }

    updateUI() {
        this.updateCurrentSite();
        this.updateProfilesList();
        this.updateSettingsForm();
    }

    updateCurrentSite() {
        const urlElement = document.getElementById('current-url');
        const statusElement = document.getElementById('current-status');

        if (this.currentTab) {
            urlElement.textContent = new URL(this.currentTab.url).hostname;
            
            const isMonitored = this.profiles.some(p => 
                this.currentTab.url.includes(new URL(p.url).hostname)
            );

            if (isMonitored) {
                statusElement.innerHTML = '<span class="status-dot"></span><span>Monitorando</span>';
            } else {
                statusElement.innerHTML = '<span class="status-dot" style="background:#ffc107"></span><span>Não monitorado</span>';
            }
        } else {
            urlElement.textContent = 'Nenhuma aba ativa';
            statusElement.innerHTML = '<span class="status-dot" style="background:#6c757d"></span><span>Inativo</span>';
        }
    }

    updateProfilesList() {
        const container = document.getElementById('profiles-list');
        
        if (this.profiles.length === 0) {
            container.innerHTML = '<p style="text-align:center;color:#6c757d;padding:20px;">Nenhum perfil salvo</p>';
            return;
        }

        container.innerHTML = this.profiles.map(profile => `
            <div class="profile-item">
                <div class="profile-info">
                    <h5>${profile.name}</h5>
                    <span>${new URL(profile.url).hostname}</span>
                </div>
                <div class="profile-actions">
                    <button class="btn btn-small btn-primary" onclick="popup.openProfile('${profile.id}')">Abrir</button>
                    <button class="btn btn-small btn-secondary" onclick="popup.deleteProfile('${profile.id}')">×</button>
                </div>
            </div>
        `).join('');
    }

    updateSettingsForm() {
        document.getElementById('monitor-interval').value = this.settings.monitorInterval;
        document.getElementById('auto-recovery').checked = this.settings.autoRecovery;
        document.getElementById('notifications').checked = this.settings.notifications;
        document.getElementById('debug-mode').checked = this.settings.debugMode;
    }

    async addCurrentSiteProfile() {
        if (!this.currentTab) {
            this.showNotification('Nenhuma aba ativa encontrada');
            return;
        }

        const url = new URL(this.currentTab.url);
        const name = prompt('Nome do perfil:', url.hostname);
        
        if (!name) return;

        const profile = {
            id: Date.now().toString(),
            name: name.trim(),
            url: this.currentTab.url,
            domain: url.hostname,
            monitorInterval: this.settings.monitorInterval,
            enabled: true,
            created: new Date().toISOString()
        };

        this.profiles.push(profile);
        await this.saveProfiles();
        
        // Send to background script
        chrome.runtime.sendMessage({
            action: 'addProfile',
            profile: profile
        });

        this.updateProfilesList();
        this.showNotification(`Perfil "${name}" adicionado!`);
    }

    async addPredefinedProfile(profileType) {
        const predefinedProfiles = {
            ifood: {
                name: 'iFood Gestor',
                url: 'https://gestordepedidos.ifood.com.br',
                domain: 'gestordepedidos.ifood.com.br'
            },
            whatsapp: {
                name: 'WhatsApp Web',
                url: 'https://web.whatsapp.com',
                domain: 'web.whatsapp.com'
            },
            gmail: {
                name: 'Gmail',
                url: 'https://mail.google.com',
                domain: 'mail.google.com'
            },
            office365: {
                name: 'Office 365',
                url: 'https://portal.office.com',
                domain: 'portal.office.com'
            }
        };

        const template = predefinedProfiles[profileType];
        if (!template) return;

        const profile = {
            id: Date.now().toString(),
            ...template,
            monitorInterval: this.settings.monitorInterval,
            enabled: true,
            created: new Date().toISOString()
        };

        this.profiles.push(profile);
        await this.saveProfiles();

        chrome.runtime.sendMessage({
            action: 'addProfile',
            profile: profile
        });

        this.updateProfilesList();
        this.showNotification(`Perfil "${template.name}" adicionado!`);
    }

    async openProfile(profileId) {
        const profile = this.profiles.find(p => p.id === profileId);
        if (!profile) return;

        try {
            await chrome.tabs.create({ url: profile.url });
            window.close();
        } catch (error) {
            console.error('Error opening profile:', error);
            this.showNotification('Erro ao abrir perfil');
        }
    }

    async deleteProfile(profileId) {
        if (!confirm('Tem certeza que deseja excluir este perfil?')) return;

        this.profiles = this.profiles.filter(p => p.id !== profileId);
        await this.saveProfiles();

        chrome.runtime.sendMessage({
            action: 'removeProfile',
            profileId: profileId
        });

        this.updateProfilesList();
        this.showNotification('Perfil removido');
    }

    async toggleMonitoring() {
        const btn = document.getElementById('toggle-monitor');
        const icon = btn.querySelector('.icon');
        const text = btn.querySelector('span:last-child') || btn;

        try {
            const response = await chrome.runtime.sendMessage({ action: 'toggleMonitoring' });
            
            if (response.enabled) {
                icon.textContent = '⏸️';
                text.textContent = 'Pausar Monitor';
                this.showNotification('Monitoramento ativado');
            } else {
                icon.textContent = '▶️';
                text.textContent = 'Iniciar Monitor';
                this.showNotification('Monitoramento pausado');
            }
        } catch (error) {
            console.error('Error toggling monitoring:', error);
            this.showNotification('Erro ao alterar monitoramento');
        }
    }

    exportProfiles() {
        const data = {
            profiles: this.profiles,
            settings: this.settings,
            exported: new Date().toISOString()
        };

        const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        
        const a = document.createElement('a');
        a.href = url;
        a.download = 'universal-browser-profiles.json';
        a.click();
        
        URL.revokeObjectURL(url);
        this.showNotification('Perfis exportados');
    }

    importProfiles() {
        const input = document.createElement('input');
        input.type = 'file';
        input.accept = '.json';
        
        input.onchange = async (e) => {
            const file = e.target.files[0];
            if (!file) return;

            try {
                const text = await file.text();
                const data = JSON.parse(text);
                
                if (data.profiles && Array.isArray(data.profiles)) {
                    this.profiles = [...this.profiles, ...data.profiles];
                    await this.saveProfiles();
                    
                    if (data.settings) {
                        this.settings = { ...this.settings, ...data.settings };
                        await this.saveSettings();
                    }
                    
                    this.updateUI();
                    this.showNotification(`${data.profiles.length} perfis importados`);
                } else {
                    this.showNotification('Arquivo inválido');
                }
            } catch (error) {
                console.error('Error importing profiles:', error);
                this.showNotification('Erro ao importar perfis');
            }
        };
        
        input.click();
    }

    async startStatUpdates() {
        const updateStats = async () => {
            try {
                const response = await chrome.runtime.sendMessage({ action: 'getStats' });
                
                if (response) {
                    document.getElementById('sites-monitored').textContent = response.sitesMonitored || this.profiles.length;
                    document.getElementById('recoveries-count').textContent = response.recoveriesCount || 0;
                    document.getElementById('uptime').textContent = response.uptime || '00:00';
                }
            } catch (error) {
                console.error('Error updating stats:', error);
            }
        };

        updateStats();
        setInterval(updateStats, 5000); // Update every 5 seconds
    }

    showNotification(message) {
        // Create a simple notification
        const notification = document.createElement('div');
        notification.textContent = message;
        notification.style.cssText = `
            position: fixed;
            top: 10px;
            right: 10px;
            background: #667eea;
            color: white;
            padding: 10px 15px;
            border-radius: 6px;
            font-size: 12px;
            z-index: 1000;
            animation: slideIn 0.3s ease;
        `;

        document.body.appendChild(notification);

        setTimeout(() => {
            notification.remove();
        }, 3000);
    }
}

// Initialize popup when DOM is loaded
let popup;

document.addEventListener('DOMContentLoaded', () => {
    popup = new UniversalBrowserPopup();
});

// Add CSS for notification animation
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from { transform: translateX(100%); opacity: 0; }
        to { transform: translateX(0); opacity: 1; }
    }
`;
document.head.appendChild(style);