import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';

export class SceneManager {
    constructor() {
        this.scene = null;
        this.camera = null;
        this.renderer = null;
        this.clock = null;
        this.controls = null; // Add controls property
        
        this.init();
    }
    
    init() {
        this.createScene();
        this.createCamera();
        this.createRenderer();
        this.createControls(); // Add controls initialization
        this.createClock();
        this.bindEvents();
    }
    
    createScene() {
        this.scene = new THREE.Scene();
        this.scene.background = new THREE.Color(0x000000);
    }
    
    createCamera() {
        this.camera = new THREE.PerspectiveCamera(
            60,
            window.innerWidth / window.innerHeight,
            0.1,
            1000
        );
        // Initial camera position - same as before
        this.camera.position.set(0, 0, 3.5);
        this.camera.lookAt(0, 0, 0);
    }
    
    createControls() {
        // Add OrbitControls for full mouse interaction
        this.controls = new OrbitControls(this.camera, this.renderer.domElement);
        
        // Enable rotation, disable panning, keep zoom
        this.controls.enableRotate = true;  // Allow mouse rotation
        this.controls.enablePan = false;    // No panning
        this.controls.enableZoom = true;    // Keep zoom functionality
        
        // Configure smooth interaction
        this.controls.enableDamping = true; // Smooth motion
        this.controls.dampingFactor = 0.05;
        
        // Rotation settings
        this.controls.rotateSpeed = 0.5;    // Smooth rotation speed
        this.controls.autoRotate = false;   // No auto-rotation
        
        // Zoom limits
        this.controls.minDistance = 1.5; // Minimum zoom (close)
        this.controls.maxDistance = 20.0; // Maximum zoom (far)
        this.controls.zoomSpeed = 1.0;   // Zoom sensitivity
        
        // Target the center of the sphere
        this.controls.target.set(0, 0, 0);
        
        this.controls.update();
    }
    
    createRenderer() {
        this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
        this.renderer.setSize(window.innerWidth, window.innerHeight);
        this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
        document.body.appendChild(this.renderer.domElement);
    }
    
    createClock() {
        this.clock = new THREE.Clock();
    }
    
    bindEvents() {
        window.addEventListener('resize', this.onWindowResize.bind(this));
    }
    
    onWindowResize() {
        this.camera.aspect = window.innerWidth / window.innerHeight;
        this.camera.updateProjectionMatrix();
        this.renderer.setSize(window.innerWidth, window.innerHeight);
    }
    
    add(object) {
        if (this.scene) {
            this.scene.add(object);
        }
    }
    
    remove(object) {
        if (this.scene) {
            this.scene.remove(object);
        }
    }
    
    update() {
        // Update controls if they exist
        if (this.controls) {
            this.controls.update();
        }
    }
    
    render() {
        if (this.renderer && this.scene && this.camera) {
            this.renderer.render(this.scene, this.camera);
        }
    }
    
    getElapsedTime() {
        return this.clock ? this.clock.getElapsedTime() : 0;
    }
    
    getScene() {
        return this.scene;
    }
    
    getCamera() {
        return this.camera;
    }
    
    getRenderer() {
        return this.renderer;
    }
    
    dispose() {
        if (this.controls) {
            this.controls.dispose();
        }
        if (this.renderer) {
            this.renderer.dispose();
        }
        window.removeEventListener('resize', this.onWindowResize.bind(this));
    }
}