// Universal Browser Extension - Background Script
class UniversalBrowserBackground {
    constructor() {
        this.profiles = [];
        this.settings = {
            monitorInterval: 30,
            autoRecovery: true,
            notifications: true,
            debugMode: false
        };
        this.monitoringEnabled = true;
        this.monitoredTabs = new Map(); // tabId -> profile
        this.stats = {
            sitesMonitored: 0,
            recoveriesCount: 0,
            startTime: Date.now(),
            uptime: '00:00'
        };
        this.alarms = new Map(); // profileId -> alarmName
        
        this.init();
    }

    async init() {
        console.log('Universal Browser Extension - Background script started');
        
        await this.loadData();
        this.setupEventListeners();
        this.startMonitoring();
        this.updateStats();
        
        // Update stats every minute
        setInterval(() => this.updateStats(), 60000);
    }

    async loadData() {
        try {
            const result = await chrome.storage.sync.get(['profiles', 'settings']);
            
            if (result.profiles) {
                this.profiles = result.profiles;
            }
            
            if (result.settings) {
                this.settings = { ...this.settings, ...result.settings };
            }
            
            this.log('Data loaded', { 
                profilesCount: this.profiles.length, 
                settings: this.settings 
            });
        } catch (error) {
            console.error('Error loading data:', error);
        }
    }

    setupEventListeners() {
        // Handle messages from popup
        chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
            this.handleMessage(message, sender, sendResponse);
            return true; // Keep the message channel open for async responses
        });

        // Handle tab updates
        chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
            if (changeInfo.status === 'complete' && tab.url) {
                this.handleTabUpdate(tabId, tab);
            }
        });

        // Handle tab removal
        chrome.tabs.onRemoved.addListener((tabId, removeInfo) => {
            this.handleTabRemoved(tabId);
        });

        // Handle window focus changes
        chrome.windows.onFocusChanged.addListener((windowId) => {
            if (windowId !== chrome.windows.WINDOW_ID_NONE) {
                this.handleWindowFocusChanged(windowId);
            }
        });

        // Handle alarms for monitoring
        chrome.alarms.onAlarm.addListener((alarm) => {
            this.handleAlarm(alarm);
        });

        // Handle extension startup
        chrome.runtime.onStartup.addListener(() => {
            this.log('Extension started');
            this.startMonitoring();
        });

        // Handle extension install
        chrome.runtime.onInstalled.addListener((details) => {
            this.handleInstall(details);
        });
    }

    async handleMessage(message, sender, sendResponse) {
        try {
            switch (message.action) {
                case 'addProfile':
                    await this.addProfile(message.profile);
                    sendResponse({ success: true });
                    break;

                case 'removeProfile':
                    await this.removeProfile(message.profileId);
                    sendResponse({ success: true });
                    break;

                case 'toggleMonitoring':
                    const enabled = this.toggleMonitoring();
                    sendResponse({ enabled });
                    break;

                case 'getStats':
                    sendResponse(this.stats);
                    break;

                case 'updateSettings':
                    await this.updateSettings(message.settings);
                    sendResponse({ success: true });
                    break;

                default:
                    sendResponse({ error: 'Unknown action' });
            }
        } catch (error) {
            console.error('Error handling message:', error);
            sendResponse({ error: error.message });
        }
    }

    async addProfile(profile) {
        this.profiles.push(profile);
        await chrome.storage.sync.set({ profiles: this.profiles });
        
        this.log('Profile added', profile);
        
        // Start monitoring for this profile
        if (profile.enabled) {
            this.startProfileMonitoring(profile);
        }
        
        this.updateStats();
    }

    async removeProfile(profileId) {
        const profile = this.profiles.find(p => p.id === profileId);
        if (!profile) return;

        this.profiles = this.profiles.filter(p => p.id !== profileId);
        await chrome.storage.sync.set({ profiles: this.profiles });
        
        // Stop monitoring for this profile
        this.stopProfileMonitoring(profile);
        
        this.log('Profile removed', { profileId });
        this.updateStats();
    }

    toggleMonitoring() {
        this.monitoringEnabled = !this.monitoringEnabled;
        
        if (this.monitoringEnabled) {
            this.startMonitoring();
            this.log('Monitoring enabled');
        } else {
            this.stopAllMonitoring();
            this.log('Monitoring disabled');
        }
        
        return this.monitoringEnabled;
    }

    async updateSettings(newSettings) {
        this.settings = { ...this.settings, ...newSettings };
        await chrome.storage.sync.set({ settings: this.settings });
        
        this.log('Settings updated', this.settings);
        
        // Restart monitoring with new settings
        if (this.monitoringEnabled) {
            this.stopAllMonitoring();
            this.startMonitoring();
        }
    }

    startMonitoring() {
        if (!this.monitoringEnabled) return;
        
        this.profiles
            .filter(profile => profile.enabled)
            .forEach(profile => this.startProfileMonitoring(profile));
        
        this.log('Started monitoring', { profileCount: this.profiles.length });
    }

    startProfileMonitoring(profile) {
        const alarmName = `monitor_${profile.id}`;
        
        // Clear existing alarm
        chrome.alarms.clear(alarmName);
        
        // Create new alarm
        chrome.alarms.create(alarmName, {
            delayInMinutes: profile.monitorInterval / 60,
            periodInMinutes: profile.monitorInterval / 60
        });
        
        this.alarms.set(profile.id, alarmName);
        this.log('Started monitoring profile', { name: profile.name, interval: profile.monitorInterval });
    }

    stopProfileMonitoring(profile) {
        const alarmName = this.alarms.get(profile.id);
        if (alarmName) {
            chrome.alarms.clear(alarmName);
            this.alarms.delete(profile.id);
        }
        
        this.log('Stopped monitoring profile', { name: profile.name });
    }

    stopAllMonitoring() {
        this.alarms.forEach((alarmName, profileId) => {
            chrome.alarms.clear(alarmName);
        });
        this.alarms.clear();
        
        this.log('Stopped all monitoring');
    }

    async handleAlarm(alarm) {
        if (!alarm.name.startsWith('monitor_')) return;
        
        const profileId = alarm.name.replace('monitor_', '');
        const profile = this.profiles.find(p => p.id === profileId);
        
        if (!profile || !profile.enabled) return;
        
        await this.checkProfileStatus(profile);
    }

    async checkProfileStatus(profile) {
        try {
            // Find tabs with this profile's domain
            const tabs = await chrome.tabs.query({
                url: `*://${profile.domain}/*`
            });
            
            if (tabs.length === 0) {
                // No tabs found for this profile
                if (this.settings.autoRecovery) {
                    await this.recoverProfile(profile);
                } else if (this.settings.notifications) {
                    this.showNotification(`${profile.name} não está aberto`, 'Clique para abrir');
                }
            } else {
                // Check if tabs are responsive
                for (const tab of tabs) {
                    const isResponsive = await this.checkTabResponsiveness(tab);
                    if (!isResponsive && this.settings.autoRecovery) {
                        await this.recoverTab(tab, profile);
                    }
                }
            }
        } catch (error) {
            this.log('Error checking profile status', { error: error.message, profile: profile.name });
        }
    }

    async checkTabResponsiveness(tab) {
        try {
            // Inject a script to check if the page is responsive
            const results = await chrome.scripting.executeScript({
                target: { tabId: tab.id },
                func: () => {
                    // Check if page is loaded and interactive
                    return document.readyState === 'complete' && 
                           document.body && 
                           !document.body.classList.contains('error-page');
                }
            });
            
            return results && results[0] && results[0].result;
        } catch (error) {
            // If we can't inject script, assume tab is not responsive
            return false;
        }
    }

    async recoverProfile(profile) {
        try {
            const tab = await chrome.tabs.create({
                url: profile.url,
                active: false
            });
            
            this.stats.recoveriesCount++;
            this.log('Profile recovered', { name: profile.name, tabId: tab.id });
            
            if (this.settings.notifications) {
                this.showNotification(`${profile.name} recuperado`, 'Site reaberto automaticamente');
            }
        } catch (error) {
            this.log('Error recovering profile', { error: error.message, profile: profile.name });
        }
    }

    async recoverTab(tab, profile) {
        try {
            await chrome.tabs.reload(tab.id);
            
            this.stats.recoveriesCount++;
            this.log('Tab recovered', { name: profile.name, tabId: tab.id });
            
            if (this.settings.notifications) {
                this.showNotification(`${profile.name} recarregado`, 'Página recarregada automaticamente');
            }
        } catch (error) {
            // If reload fails, try to create a new tab
            await this.recoverProfile(profile);
        }
    }

    handleTabUpdate(tabId, tab) {
        // Check if this tab matches any profile
        const profile = this.profiles.find(p => 
            tab.url && tab.url.includes(p.domain)
        );
        
        if (profile) {
            this.monitoredTabs.set(tabId, profile);
            this.log('Tab monitored', { tabId, profile: profile.name, url: tab.url });
        }
    }

    handleTabRemoved(tabId) {
        const profile = this.monitoredTabs.get(tabId);
        if (profile) {
            this.monitoredTabs.delete(tabId);
            this.log('Monitored tab removed', { tabId, profile: profile.name });
            
            // Check if we need to recover this profile
            setTimeout(() => {
                this.checkProfileStatus(profile);
            }, 1000); // Small delay to allow for page redirects
        }
    }

    handleWindowFocusChanged(windowId) {
        // Could be used for additional monitoring logic
        // For now, just log the event
        this.log('Window focus changed', { windowId });
    }

    handleInstall(details) {
        if (details.reason === 'install') {
            // First time install
            this.log('Extension installed');
            
            // Open welcome page
            chrome.tabs.create({
                url: 'https://universalbrowser.vercel.app'
            });
            
            // Show notification
            this.showNotification(
                'Universal Browser instalado!',
                'Clique no ícone da extensão para começar'
            );
        } else if (details.reason === 'update') {
            this.log('Extension updated', { version: chrome.runtime.getManifest().version });
        }
    }

    updateStats() {
        const now = Date.now();
        const uptimeMs = now - this.stats.startTime;
        const uptimeHours = Math.floor(uptimeMs / (1000 * 60 * 60));
        const uptimeMinutes = Math.floor((uptimeMs % (1000 * 60 * 60)) / (1000 * 60));
        
        this.stats.sitesMonitored = this.profiles.filter(p => p.enabled).length;
        this.stats.uptime = `${uptimeHours.toString().padStart(2, '0')}:${uptimeMinutes.toString().padStart(2, '0')}`;
    }

    showNotification(title, message) {
        if (!this.settings.notifications) return;
        
        chrome.notifications.create({
            type: 'basic',
            iconUrl: 'icons/icon48.png',
            title: title,
            message: message
        });
    }

    log(message, data = null) {
        const timestamp = new Date().toISOString();
        console.log(`[${timestamp}] Universal Browser:`, message, data);
        
        if (this.settings.debugMode) {
            // In debug mode, also store logs for later retrieval
            chrome.storage.local.get('logs', (result) => {
                const logs = result.logs || [];
                logs.push({
                    timestamp,
                    message,
                    data
                });
                
                // Keep only last 1000 logs
                if (logs.length > 1000) {
                    logs.splice(0, logs.length - 1000);
                }
                
                chrome.storage.local.set({ logs });
            });
        }
    }
}

// Initialize the background script
const universalBrowser = new UniversalBrowserBackground();