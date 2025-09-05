import * as THREE from 'three';

/**
 * SceneManager Class for Galaxy Solar System
 * Handles Three.js scene setup with zoom-only camera controls
 * No rotation or panning - fixed viewing angle
 */
export class SceneManager {
    constructor(container) {
        // Container element
        this.container = container;
        
        // Resolution update callback
        this.onResolutionUpdate = null;
        
        // Three.js core objects
        this.scene = null;
        this.camera = null;
        this.renderer = null;
        this.clock = null;
        
        // Camera configuration
        this.cameraConfig = {
            fov: 60,
            near: 0.1,
            far: 1000,
            position: { x: 0, y: 3, z: 15 },
            lookAt: { x: 0, y: 0, z: 0 }
        };
        
        // Zoom configuration
        this.zoomConfig = {
            current: 15,
            min: 5,
            max: 30,
            speed: 1.0,
            smoothing: 0.5
        };
        
        // Target zoom for smooth transitions
        this.targetZoom = this.zoomConfig.current;
        
        
        // Initialize the scene
        this.init();
    }
    
    /**
     * Initialize scene, camera, renderer, and controls
     */
    init() {
        this.createScene();
        this.createCamera();
        this.createRenderer();
        this.createClock();
        this.setupEventListeners();
    }
    
    /**
     * Create Three.js scene with dark background
     */
    createScene() {
        this.scene = new THREE.Scene();
        this.scene.background = new THREE.Color(0x000000);
        
        // Add ambient light for basic visibility
        const ambientLight = new THREE.AmbientLight(0xffffff, 0.1);
        this.scene.add(ambientLight);
    }
    
    /**
     * Create perspective camera with fixed angle
     */
    createCamera() {
        const aspect = this.container ? 
            this.container.clientWidth / this.container.clientHeight : 
            window.innerWidth / window.innerHeight;
        
        this.camera = new THREE.PerspectiveCamera(
            this.cameraConfig.fov,
            aspect,
            this.cameraConfig.near,
            this.cameraConfig.far
        );
        
        // Set fixed camera position
        this.camera.position.set(
            this.cameraConfig.position.x,
            this.cameraConfig.position.y,
            this.cameraConfig.position.z
        );
        
        // Look at center of solar system
        this.camera.lookAt(
            this.cameraConfig.lookAt.x,
            this.cameraConfig.lookAt.y,
            this.cameraConfig.lookAt.z
        );
        
    }
    
    /**
     * Create WebGL renderer
     */
    createRenderer() {
        this.renderer = new THREE.WebGLRenderer({ 
            antialias: true, 
            alpha: true 
        });
        
        if (this.container) {
            this.renderer.setSize(this.container.clientWidth, this.container.clientHeight);
            this.container.appendChild(this.renderer.domElement);
        } else {
            this.renderer.setSize(window.innerWidth, window.innerHeight);
            document.body.appendChild(this.renderer.domElement);
        }
        
        this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    }
    
    /**
     * Create clock for time tracking
     */
    createClock() {
        this.clock = new THREE.Clock();
    }
    
    /**
     * Setup event listeners for zoom and resize
     */
    setupEventListeners() {
        // Mouse wheel for zoom
        this.renderer.domElement.addEventListener('wheel', this.onWheel.bind(this), { passive: false });
        
        // Touch events for mobile zoom
        this.renderer.domElement.addEventListener('touchstart', this.onTouchStart.bind(this), { passive: false });
        this.renderer.domElement.addEventListener('touchmove', this.onTouchMove.bind(this), { passive: false });
        this.renderer.domElement.addEventListener('touchend', this.onTouchEnd.bind(this));
        
        // Window resize
        window.addEventListener('resize', this.onWindowResize.bind(this));
        
        // Touch tracking
        this.touches = [];
        this.lastTouchDistance = 0;
    }
    
    /**
     * Handle mouse wheel zoom
     */
    onWheel(event) {
        event.preventDefault();
        
        // Calculate zoom change
        const delta = event.deltaY * -0.001 * this.zoomConfig.speed;
        this.targetZoom = Math.max(
            this.zoomConfig.min,
            Math.min(this.zoomConfig.max, this.targetZoom + delta)
        );
    }
    
    /**
     * Handle touch start for pinch zoom
     */
    onTouchStart(event) {
        event.preventDefault();
        this.touches = Array.from(event.touches);
        
        if (this.touches.length === 2) {
            const dx = this.touches[0].clientX - this.touches[1].clientX;
            const dy = this.touches[0].clientY - this.touches[1].clientY;
            this.lastTouchDistance = Math.sqrt(dx * dx + dy * dy);
        }
    }
    
    /**
     * Handle touch move for pinch zoom
     */
    onTouchMove(event) {
        event.preventDefault();
        this.touches = Array.from(event.touches);
        
        if (this.touches.length === 2) {
            const dx = this.touches[0].clientX - this.touches[1].clientX;
            const dy = this.touches[0].clientY - this.touches[1].clientY;
            const distance = Math.sqrt(dx * dx + dy * dy);
            
            if (this.lastTouchDistance > 0) {
                const delta = (distance - this.lastTouchDistance) * 0.01 * this.zoomConfig.speed;
                this.targetZoom = Math.max(
                    this.zoomConfig.min,
                    Math.min(this.zoomConfig.max, this.targetZoom - delta)
                );
            }
            
            this.lastTouchDistance = distance;
        }
    }
    
    /**
     * Handle touch end
     */
    onTouchEnd() {
        this.touches = [];
        this.lastTouchDistance = 0;
    }
    
    /**
     * Handle window resize
     */
    onWindowResize() {
        if (!this.container) return;
        
        this.camera.aspect = this.container.clientWidth / this.container.clientHeight;
        this.camera.updateProjectionMatrix();
        this.renderer.setSize(this.container.clientWidth, this.container.clientHeight);
        
        // Update Line2 resolution for orbit rendering
        if (this.onResolutionUpdate) {
            this.onResolutionUpdate(this.container.clientWidth, this.container.clientHeight);
        }
    }
    
    
    /**
     * Update scene (handle zoom smoothing)
     */
    update() {
        // Smooth zoom interpolation
        if (Math.abs(this.targetZoom - this.zoomConfig.current) > 0.01) {
            this.zoomConfig.current += 
                (this.targetZoom - this.zoomConfig.current) * this.zoomConfig.smoothing;
            
            // Update camera position maintaining the same viewing angle
            const zoomFactor = this.zoomConfig.current / 15; // 15 is initial distance
            this.camera.position.set(
                this.cameraConfig.position.x * zoomFactor,
                this.cameraConfig.position.y * zoomFactor,
                this.cameraConfig.position.z * zoomFactor
            );
            
            // Keep looking at center
            this.camera.lookAt(
                this.cameraConfig.lookAt.x,
                this.cameraConfig.lookAt.y,
                this.cameraConfig.lookAt.z
            );
        }
    }
    
    /**
     * Render the scene
     */
    render() {
        if (this.renderer && this.scene && this.camera) {
            this.renderer.render(this.scene, this.camera);
        }
    }
    
    /**
     * Get camera for distance calculations
     */
    getCamera() {
        return this.camera;
    }
    
    /**
     * Set resolution update callback
     */
    setResolutionUpdateCallback(callback) {
        this.onResolutionUpdate = callback;
    }
    
    /**
     * Clean up resources
     */
    dispose() {
        // Remove event listeners
        this.renderer.domElement.removeEventListener('wheel', this.onWheel.bind(this));
        this.renderer.domElement.removeEventListener('touchstart', this.onTouchStart.bind(this));
        this.renderer.domElement.removeEventListener('touchmove', this.onTouchMove.bind(this));
        this.renderer.domElement.removeEventListener('touchend', this.onTouchEnd.bind(this));
        window.removeEventListener('resize', this.onWindowResize.bind(this));
        
        // Dispose renderer
        if (this.renderer) {
            this.renderer.dispose();
            this.renderer.forceContextLoss();
            if (this.container && this.container.contains(this.renderer.domElement)) {
                this.container.removeChild(this.renderer.domElement);
            }
        }
        
        // Clear scene
        if (this.scene) {
            this.scene.clear();
        }
        
        // Clear references
        this.scene = null;
        this.camera = null;
        this.renderer = null;
        this.clock = null;
    }
}