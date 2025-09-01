/**
 * Vanilla JavaScript Integration Example
 * Shows how to integrate WavesSphere into any website
 */

class WavesSphereIntegration {
    constructor() {
        this.spheres = new Map();
        this.defaultConfig = {
            autoRotate: true,
            autoRotateSpeed: 0.001,
            cameraDistance: 4.0,
            minZoom: 2.0,
            maxZoom: 12.0,
            enableControls: true
        };
        
        this.init();
    }
    
    init() {
        // Wait for DOM to be ready
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this.setup());
        } else {
            this.setup();
        }
    }
    
    setup() {
        // Auto-detect and initialize spheres
        this.autoDetectSpheres();
        
        // Setup global controls if they exist
        this.setupGlobalControls();
        
        // Handle window resize
        window.addEventListener('resize', () => this.handleResize());
        
        // Cleanup on page unload
        window.addEventListener('beforeunload', () => this.cleanup());
    }
    
    /**
     * Auto-detect elements with data-waves-sphere attribute
     */
    autoDetectSpheres() {
        const elements = document.querySelectorAll('[data-waves-sphere]');
        
        elements.forEach((element, index) => {
            try {
                // Parse configuration from data attributes
                const config = this.parseConfigFromElement(element);
                
                // Create unique ID if not provided
                const id = element.id || `waves-sphere-${index}`;
                element.id = id;
                
                // Create sphere
                this.createSphere(id, element, config);
                
            } catch (error) {
                console.error(`Failed to initialize sphere for element:`, element, error);
            }
        });
    }
    
    /**
     * Parse configuration from data attributes
     */
    parseConfigFromElement(element) {
        const config = { ...this.defaultConfig };
        
        // Parse data attributes
        const dataset = element.dataset;
        
        Object.keys(dataset).forEach(key => {
            if (key.startsWith('sphere')) {
                // Convert data-sphere-auto-rotate to autoRotate
                const configKey = key
                    .replace('sphere', '')
                    .replace(/^([a-z])/, (match, p1) => p1.toLowerCase())
                    .replace(/-([a-z])/g, (match, p1) => p1.toUpperCase());
                
                let value = dataset[key];
                
                // Type conversion
                if (value === 'true') value = true;
                else if (value === 'false') value = false;
                else if (!isNaN(value) && !isNaN(parseFloat(value))) value = parseFloat(value);
                
                config[configKey] = value;
            }
        });
        
        return config;
    }
    
    /**
     * Create a new sphere instance
     */
    createSphere(id, container, config = {}) {
        if (this.spheres.has(id)) {
            console.warn(`Sphere with ID '${id}' already exists. Destroying existing instance.`);
            this.destroySphere(id);
        }
        
        try {
            const sphere = new WavesSphere(container, {
                ...this.defaultConfig,
                ...config
            });
            
            sphere.start();
            this.spheres.set(id, sphere);
            
            // Trigger custom event
            const event = new CustomEvent('wavesSphereCreated', {
                detail: { id, sphere, container }
            });
            container.dispatchEvent(event);
            
            console.log(`WavesSphere '${id}' created successfully`);
            return sphere;
            
        } catch (error) {
            console.error(`Failed to create sphere '${id}':`, error);
            return null;
        }
    }
    
    /**
     * Get sphere instance by ID
     */
    getSphere(id) {
        return this.spheres.get(id) || null;
    }
    
    /**
     * Destroy sphere by ID
     */
    destroySphere(id) {
        const sphere = this.spheres.get(id);
        if (sphere) {
            sphere.destroy();
            this.spheres.delete(id);
            
            // Trigger custom event
            const event = new CustomEvent('wavesSphereDestroyed', {
                detail: { id }
            });
            document.dispatchEvent(event);
            
            console.log(`WavesSphere '${id}' destroyed`);
        }
    }
    
    /**
     * Setup global control buttons
     */
    setupGlobalControls() {
        // Start all button
        const startAllBtn = document.querySelector('[data-waves-control="start-all"]');
        if (startAllBtn) {
            startAllBtn.addEventListener('click', () => this.startAll());
        }
        
        // Stop all button
        const stopAllBtn = document.querySelector('[data-waves-control="stop-all"]');
        if (stopAllBtn) {
            stopAllBtn.addEventListener('click', () => this.stopAll());
        }
        
        // Zoom in all button
        const zoomInBtn = document.querySelector('[data-waves-control="zoom-in-all"]');
        if (zoomInBtn) {
            zoomInBtn.addEventListener('click', () => this.zoomInAll());
        }
        
        // Zoom out all button
        const zoomOutBtn = document.querySelector('[data-waves-control="zoom-out-all"]');
        if (zoomOutBtn) {
            zoomOutBtn.addEventListener('click', () => this.zoomOutAll());
        }
        
        // Reset all button
        const resetBtn = document.querySelector('[data-waves-control="reset-all"]');
        if (resetBtn) {
            resetBtn.addEventListener('click', () => this.resetAll());
        }
        
        // Individual sphere controls
        document.querySelectorAll('[data-waves-control]').forEach(btn => {
            const control = btn.dataset.wavesControl;
            const target = btn.dataset.wavesTarget;
            
            if (target && !control.endsWith('-all')) {
                btn.addEventListener('click', () => {
                    const sphere = this.getSphere(target);
                    if (sphere) {
                        this.executeControl(sphere, control);
                    }
                });
            }
        });
    }
    
    /**
     * Execute control command on sphere
     */
    executeControl(sphere, control) {
        switch (control) {
            case 'start':
                sphere.start();
                break;
            case 'stop':
                sphere.stop();
                break;
            case 'zoom-in':
                sphere.zoomIn();
                break;
            case 'zoom-out':
                sphere.zoomOut();
                break;
            case 'reset-zoom':
                sphere.resetZoom();
                break;
            default:
                console.warn(`Unknown control: ${control}`);
        }
    }
    
    /**
     * Global control methods
     */
    startAll() {
        this.spheres.forEach(sphere => sphere.start());
    }
    
    stopAll() {
        this.spheres.forEach(sphere => sphere.stop());
    }
    
    zoomInAll() {
        this.spheres.forEach(sphere => sphere.zoomIn());
    }
    
    zoomOutAll() {
        this.spheres.forEach(sphere => sphere.zoomOut());
    }
    
    resetAll() {
        this.spheres.forEach(sphere => sphere.resetZoom());
    }
    
    /**
     * Handle window resize
     */
    handleResize() {
        this.spheres.forEach(sphere => {
            if (sphere.onWindowResize) {
                sphere.onWindowResize();
            }
        });
    }
    
    /**
     * Cleanup all spheres
     */
    cleanup() {
        this.spheres.forEach((sphere, id) => {
            sphere.destroy();
        });
        this.spheres.clear();
    }
    
    /**
     * Get stats for all spheres
     */
    getStats() {
        const stats = {};
        this.spheres.forEach((sphere, id) => {
            stats[id] = {
                isRunning: sphere.isRunning,
                isInitialized: sphere.isInitialized(),
                memoryUsage: sphere.getMemoryUsage(),
                zoomLevel: sphere.getZoomLevel()
            };
        });
        return stats;
    }
}

// Auto-initialize when script loads
let wavesSphereIntegration;

if (typeof window !== 'undefined') {
    // Browser environment
    wavesSphereIntegration = new WavesSphereIntegration();
    
    // Expose globally for manual access
    window.WavesSphereIntegration = wavesSphereIntegration;
    
    // Also expose individual methods for convenience
    window.createWavesSphere = (id, container, config) => {
        return wavesSphereIntegration.createSphere(id, container, config);
    };
    
    window.getWavesSphere = (id) => {
        return wavesSphereIntegration.getSphere(id);
    };
    
    window.destroyWavesSphere = (id) => {
        return wavesSphereIntegration.destroySphere(id);
    };
}

// Example HTML usage:
/*
<!DOCTYPE html>
<html>
<head>
    <title>WavesSphere Integration</title>
    <style>
        .sphere-container {
            width: 100%;
            height: 400px;
            border: 1px solid #333;
        }
    </style>
</head>
<body>
    <!-- Auto-detected sphere with configuration -->
    <div 
        data-waves-sphere
        data-sphere-auto-rotate="true"
        data-sphere-auto-rotate-speed="0.002"
        data-sphere-camera-distance="5.0"
        class="sphere-container"
        id="main-sphere"
    ></div>
    
    <!-- Control buttons -->
    <button data-waves-control="start" data-waves-target="main-sphere">Start</button>
    <button data-waves-control="stop" data-waves-target="main-sphere">Stop</button>
    <button data-waves-control="zoom-in" data-waves-target="main-sphere">Zoom In</button>
    <button data-waves-control="zoom-out" data-waves-target="main-sphere">Zoom Out</button>
    <button data-waves-control="reset-zoom" data-waves-target="main-sphere">Reset</button>
    
    <!-- Global controls -->
    <button data-waves-control="start-all">Start All</button>
    <button data-waves-control="stop-all">Stop All</button>
    
    <!-- Include Three.js and WavesSphere -->
    <script src="https://unpkg.com/three@latest/build/three.min.js"></script>
    <script src="waves-sphere-bundle.js"></script>
    <script src="vanilla-js-integration.js"></script>
    
    <!-- Custom event listeners -->
    <script>
        document.addEventListener('wavesSphereCreated', (event) => {
            console.log('Sphere created:', event.detail);
        });
        
        document.addEventListener('wavesSphereDestroyed', (event) => {
            console.log('Sphere destroyed:', event.detail);
        });
    </script>
</body>
</html>
*/

export default WavesSphereIntegration;