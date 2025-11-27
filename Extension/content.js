// Universal Browser Extension - Content Script
(() => {
    'use strict';
    
    class UniversalBrowserContent {
        constructor() {
            this.isMonitored = false;
            this.profile = null;
            this.observers = [];
            this.lastActivity = Date.now();
            this.heartbeatInterval = null;
            this.disconnectionDetected = false;
            
            this.init();
        }

        async init() {
            // Don't run on extension pages or chrome:// pages
            if (window.location.protocol === 'chrome-extension:' || 
                window.location.protocol === 'chrome:' ||
                window.location.protocol === 'moz-extension:') {
                return;
            }

            await this.checkIfMonitored();
            
            if (this.isMonitored) {
                this.setupMonitoring();
                this.log('Content script initialized', { url: window.location.href });
            }
        }

        async checkIfMonitored() {
            try {
                // Get profiles from storage
                const result = await chrome.storage.sync.get('profiles');
                const profiles = result.profiles || [];
                
                // Check if current domain matches any profile
                const currentDomain = window.location.hostname;
                this.profile = profiles.find(p => 
                    p.enabled && (
                        currentDomain.includes(p.domain) || 
                        p.domain.includes(currentDomain)
                    )
                );
                
                this.isMonitored = !!this.profile;
            } catch (error) {
                console.error('Error checking if monitored:', error);
            }
        }

        setupMonitoring() {
            this.setupActivityTracking();
            this.setupConnectionMonitoring();
            this.setupErrorDetection();
            this.setupPageVisibilityTracking();
            this.startHeartbeat();
            
            // Inject monitoring UI if enabled
            this.injectMonitoringUI();
        }

        setupActivityTracking() {
            const updateActivity = () => {
                this.lastActivity = Date.now();
            };

            // Track user interactions
            const events = ['click', 'keypress', 'scroll', 'mousemove', 'touchstart'];
            events.forEach(event => {
                document.addEventListener(event, updateActivity, { passive: true });
            });
        }

        setupConnectionMonitoring() {
            // Monitor online/offline status
            window.addEventListener('online', () => {
                this.log('Connection restored');
                this.disconnectionDetected = false;
                this.notifyBackground('connectionRestored', {
                    profile: this.profile.name,
                    url: window.location.href
                });
            });

            window.addEventListener('offline', () => {
                this.log('Connection lost');
                this.disconnectionDetected = true;
                this.notifyBackground('connectionLost', {
                    profile: this.profile.name,
                    url: window.location.href
                });
            });
        }

        setupErrorDetection() {
            // Monitor for JavaScript errors that might indicate page problems
            window.addEventListener('error', (event) => {
                if (this.isRecoverableError(event.error)) {
                    this.log('Recoverable error detected', event.error);
                    this.notifyBackground('recoverableError', {
                        profile: this.profile.name,
                        error: event.error.message,
                        url: window.location.href
                    });
                }
            });

            // Monitor for unhandled promise rejections
            window.addEventListener('unhandledrejection', (event) => {
                if (this.isRecoverableError(event.reason)) {
                    this.log('Unhandled promise rejection', event.reason);
                    this.notifyBackground('recoverableError', {
                        profile: this.profile.name,
                        error: event.reason.message || event.reason,
                        url: window.location.href
                    });
                }
            });
        }

        setupPageVisibilityTracking() {
            document.addEventListener('visibilitychange', () => {
                const isHidden = document.hidden;
                this.log('Page visibility changed', { hidden: isHidden });
                
                if (!isHidden) {
                    // Page became visible, check if it's still responsive
                    setTimeout(() => {
                        this.performHealthCheck();
                    }, 1000);
                }
            });
        }

        startHeartbeat() {
            // Send periodic heartbeat to background script
            this.heartbeatInterval = setInterval(() => {
                if (this.isMonitored) {
                    this.sendHeartbeat();
                }
            }, this.profile.monitorInterval * 1000);
        }

        async sendHeartbeat() {
            try {
                const healthData = await this.performHealthCheck();
                
                this.notifyBackground('heartbeat', {
                    profile: this.profile.name,
                    url: window.location.href,
                    health: healthData,
                    lastActivity: this.lastActivity,
                    timestamp: Date.now()
                });
            } catch (error) {
                this.log('Error sending heartbeat', error);
            }
        }

        async performHealthCheck() {
            const health = {
                responsive: true,
                errors: [],
                warnings: [],
                performance: {}
            };

            try {
                // Check if DOM is accessible
                if (!document.body) {
                    health.responsive = false;
                    health.errors.push('Document body not accessible');
                }

                // Check for common error indicators
                const errorIndicators = [
                    '.error-page',
                    '.connection-error',
                    '.server-error',
                    '[class*="error"]',
                    '[id*="error"]'
                ];

                errorIndicators.forEach(selector => {
                    const errorElements = document.querySelectorAll(selector);
                    if (errorElements.length > 0) {
                        health.warnings.push(`Error indicator found: ${selector}`);
                    }
                });

                // Check for specific page content based on profile
                if (this.profile.name === 'iFood Gestor') {
                    health.responsive = this.checkIFoodHealth();
                } else if (this.profile.name === 'WhatsApp Web') {
                    health.responsive = this.checkWhatsAppHealth();
                }

                // Performance check
                if (window.performance && window.performance.timing) {
                    const timing = window.performance.timing;
                    health.performance.loadTime = timing.loadEventEnd - timing.navigationStart;
                    health.performance.domReady = timing.domContentLoadedEventEnd - timing.navigationStart;
                }

                // Check if page has been idle too long
                const idleTime = Date.now() - this.lastActivity;
                const maxIdleTime = this.profile.monitorInterval * 2000; // 2x monitor interval
                
                if (idleTime > maxIdleTime) {
                    health.warnings.push(`Page idle for ${Math.round(idleTime / 1000)}s`);
                }

            } catch (error) {
                health.responsive = false;
                health.errors.push(`Health check error: ${error.message}`);
            }

            return health;
        }

        checkIFoodHealth() {
            // Specific checks for iFood Gestor de Pedidos
            const indicators = [
                '#app', // Main app container
                '[data-testid]', // iFood uses test IDs
                '.order-item', // Order items
                '.restaurant-info' // Restaurant info
            ];

            return indicators.some(selector => document.querySelector(selector));
        }

        checkWhatsAppHealth() {
            // Specific checks for WhatsApp Web
            const indicators = [
                '[data-testid="chat-list"]',
                '.chatlist-panel',
                '._3uMse', // WhatsApp specific classes
                '[title="WhatsApp"]'
            ];

            return indicators.some(selector => document.querySelector(selector));
        }

        isRecoverableError(error) {
            if (!error) return false;
            
            const recoverablePatterns = [
                /network error/i,
                /connection failed/i,
                /timeout/i,
                /server error/i,
                /service unavailable/i,
                /502|503|504/,
                /fetch.*failed/i,
                /websocket.*closed/i
            ];

            const errorMessage = error.message || error.toString();
            return recoverablePatterns.some(pattern => pattern.test(errorMessage));
        }

        injectMonitoringUI() {
            // Create a small monitoring indicator
            const indicator = document.createElement('div');
            indicator.id = 'universal-browser-indicator';
            indicator.innerHTML = `
                <div style="
                    position: fixed;
                    top: 10px;
                    right: 10px;
                    z-index: 999999;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    padding: 8px 12px;
                    border-radius: 20px;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                    font-size: 12px;
                    font-weight: 500;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.2);
                    cursor: pointer;
                    transition: all 0.3s ease;
                    opacity: 0.8;
                " 
                onmouseover="this.style.opacity='1'; this.style.transform='scale(1.05)'"
                onmouseout="this.style.opacity='0.8'; this.style.transform='scale(1)'"
                onclick="this.style.display='none'"
                title="Universal Browser está monitorando esta página. Clique para ocultar.">
                    🛡️ Monitorado
                </div>
            `;

            document.body.appendChild(indicator);

            // Auto-hide after 5 seconds
            setTimeout(() => {
                if (indicator && indicator.parentNode) {
                    indicator.style.opacity = '0.3';
                    indicator.style.transform = 'scale(0.8)';
                }
            }, 5000);
        }

        async notifyBackground(type, data) {
            try {
                await chrome.runtime.sendMessage({
                    action: 'contentScriptMessage',
                    type: type,
                    data: data,
                    timestamp: Date.now()
                });
            } catch (error) {
                this.log('Error notifying background', error);
            }
        }

        log(message, data = null) {
            console.log(`[Universal Browser Content] ${message}`, data);
        }

        destroy() {
            if (this.heartbeatInterval) {
                clearInterval(this.heartbeatInterval);
            }
            
            this.observers.forEach(observer => {
                if (observer.disconnect) observer.disconnect();
            });
        }
    }

    // Initialize content script
    const universalBrowserContent = new UniversalBrowserContent();

    // Clean up on page unload
    window.addEventListener('beforeunload', () => {
        universalBrowserContent.destroy();
    });

    // Expose for debugging
    if (typeof window !== 'undefined') {
        window.universalBrowserContent = universalBrowserContent;
    }

})();