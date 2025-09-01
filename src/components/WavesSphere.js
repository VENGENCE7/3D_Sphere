/**
 * WavesSphere - A complete Three.js animated sphere component
 * Features: Liquid wave animations, eclipse color gradients, interactive controls
 * 
 * Usage:
 * const sphere = new WavesSphere(document.getElementById('container'));
 * sphere.start();
 */

import * as THREE from 'three';

export class WavesSphere {
    constructor(container, options = {}) {
        // Default configuration
        this.config = {
            // Container settings
            width: container?.clientWidth || window.innerWidth,
            height: container?.clientHeight || window.innerHeight,
            
            // Sphere settings
            radius: 1.5,
            pointCount: 28000, // Approximate number of points
            
            // Wave parameters
            waveFrequency: 6.0,      // Ripple frequency
            waveSpeed: 0.25,         // Expansion speed
            waveThickness: 0.5,      // Ring thickness
            waveAmplitude: 0.8,      // Base wave height
            waveMaxAmplitude: 2.2,   // Maximum height at clash
            waveCycle: 4.0,          // Wave repeat cycle in seconds
            
            // Visual settings
            pointBaseSize: 6.0,      // Base point size
            autoRotate: true,        // Auto-rotation when not interacting
            autoRotateSpeed: 0.0008, // Auto-rotation speed
            
            // Camera settings
            cameraDistance: 3.5,     // Default camera distance
            minZoom: 2.0,           // Minimum zoom distance
            maxZoom: 15.0,          // Maximum zoom distance
            
            // Controls
            enableControls: true,    // Mouse/touch controls
            damping: 0.1,           // Rotation damping
            
            // Performance
            enableStats: false,     // Show performance stats
            pixelRatio: window.devicePixelRatio || 1,
            
            ...options // Override with user options
        };
        
        this.container = container;
        this.scene = null;
        this.camera = null;
        this.renderer = null;
        this.sphere = null;
        this.backgroundSphere = null;
        this.group = null;
        
        // Animation state
        this.isRunning = false;
        this.startTime = 0;
        this.elapsedTime = 0;
        
        // Interaction state
        this.isMouseDown = false;
        this.mouseX = 0;
        this.mouseY = 0;
        this.targetRotationX = 0;
        this.targetRotationY = 0;
        this.currentRotationX = 0;
        this.currentRotationY = 0;
        
        // Bind methods
        this.animate = this.animate.bind(this);
        this.onWindowResize = this.onWindowResize.bind(this);
        this.onMouseDown = this.onMouseDown.bind(this);
        this.onMouseMove = this.onMouseMove.bind(this);
        this.onMouseUp = this.onMouseUp.bind(this);
        this.onWheel = this.onWheel.bind(this);
        this.onTouchStart = this.onTouchStart.bind(this);
        this.onTouchMove = this.onTouchMove.bind(this);
        this.onTouchEnd = this.onTouchEnd.bind(this);
        
        this.init();
    }
    
    /**
     * Initialize the WavesSphere component
     * Call this to set up the Three.js scene and add to DOM
     */
    init() {
        try {
            this.createScene();
            this.createCamera();
            this.createRenderer();
            this.createSphere();
            this.createBackgroundSphere();
            this.createGroup();
            this.setupControls();
            this.setupEventListeners();
            
            if (this.container) {
                this.container.appendChild(this.renderer.domElement);
            }
            
            return true; // Success
        } catch (error) {
            console.error('WavesSphere initialization failed:', error);
            return false; // Failure
        }
    }

    /**
     * Reinitialize the component (useful for config changes)
     */
    reinit() {
        this.destroy();
        return this.init();
    }
    
    createScene() {
        this.scene = new THREE.Scene();
        this.scene.background = new THREE.Color(0x000000); // Black background
    }
    
    createCamera() {
        const aspect = this.config.width / this.config.height;
        this.camera = new THREE.PerspectiveCamera(75, aspect, 0.1, 1000);
        this.camera.position.set(0, 0, this.config.cameraDistance);
    }
    
    createRenderer() {
        this.renderer = new THREE.WebGLRenderer({
            antialias: true,
            alpha: true
        });
        this.renderer.setSize(this.config.width, this.config.height);
        this.renderer.setPixelRatio(Math.min(this.config.pixelRatio, 2));
    }
    
    createSphere() {
        // Create geometry with hexagonal packing
        const positions = this.createHexagonalSpherePositions();
        const geometry = new THREE.BufferGeometry();
        geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
        geometry.setAttribute('initialPosition', new THREE.BufferAttribute(new Float32Array(positions), 3));
        
        // Add random values for each point
        const randoms = new Float32Array(positions.length / 3);
        for (let i = 0; i < randoms.length; i++) {
            randoms[i] = Math.random();
        }
        geometry.setAttribute('aRandom', new THREE.BufferAttribute(randoms, 1));
        
        // Create shader material
        const material = new THREE.ShaderMaterial({
            vertexShader: this.getVertexShader(),
            fragmentShader: this.getFragmentShader(),
            uniforms: {
                uTime: { value: 0.0 },
                uCameraDistance: { value: this.config.cameraDistance }
            },
            transparent: true,
            depthTest: true,
            depthWrite: false,
            blending: THREE.NormalBlending
        });
        
        this.sphere = new THREE.Points(geometry, material);
        this.sphere.renderOrder = 1;
    }
    
    createBackgroundSphere() {
        const geometry = new THREE.SphereGeometry(
            this.config.radius * 0.95, // Slightly smaller
            64, 32
        );
        
        const material = new THREE.MeshBasicMaterial({
            color: 0x141916, // Dark background color
            side: THREE.FrontSide,
            transparent: false,
            depthWrite: true,
            depthTest: true
        });
        
        this.backgroundSphere = new THREE.Mesh(geometry, material);
        this.backgroundSphere.renderOrder = -1;
    }
    
    createGroup() {
        this.group = new THREE.Group();
        this.group.add(this.backgroundSphere);
        this.group.add(this.sphere);
        this.scene.add(this.group);
    }
    
    createHexagonalSpherePositions() {
        const points = [];
        const radius = this.config.radius;
        const latLines = 240; // Number of latitude lines
        const hexRowHeight = Math.PI / latLines;
        
        for (let lat = 0; lat <= latLines; lat++) {
            const theta = lat * hexRowHeight;
            const sinTheta = Math.sin(theta);
            const cosTheta = Math.cos(theta);
            
            const circumference = 2 * Math.PI * radius * sinTheta;
            const targetSpacing = (2 * Math.PI * radius) / 360;
            let lonLines = Math.max(3, Math.round(circumference / targetSpacing));
            
            const isOffsetRow = (lat % 2) === 1;
            const phiOffset = isOffsetRow ? (Math.PI / lonLines) : 0;
            
            for (let lon = 0; lon < lonLines; lon++) {
                const phi = (lon / lonLines) * 2 * Math.PI + phiOffset;
                const sinPhi = Math.sin(phi);
                const cosPhi = Math.cos(phi);
                
                const x = radius * sinTheta * cosPhi;
                const y = radius * cosTheta;
                const z = radius * sinTheta * sinPhi;
                
                points.push(x, y, z);
            }
        }
        
        return new Float32Array(points);
    }
    
    setupControls() {
        if (!this.config.enableControls) return;
        
        const canvas = this.renderer.domElement;
        
        // Mouse events
        canvas.addEventListener('mousedown', this.onMouseDown);
        canvas.addEventListener('mousemove', this.onMouseMove);
        canvas.addEventListener('mouseup', this.onMouseUp);
        canvas.addEventListener('wheel', this.onWheel, { passive: false });
        
        // Touch events
        canvas.addEventListener('touchstart', this.onTouchStart, { passive: false });
        canvas.addEventListener('touchmove', this.onTouchMove, { passive: false });
        canvas.addEventListener('touchend', this.onTouchEnd);
        
        canvas.style.cursor = 'grab';
    }
    
    setupEventListeners() {
        window.addEventListener('resize', this.onWindowResize);
    }
    
    // Event Handlers
    onMouseDown(event) {
        this.isMouseDown = true;
        this.mouseX = event.clientX;
        this.mouseY = event.clientY;
        this.renderer.domElement.style.cursor = 'grabbing';
    }
    
    onMouseMove(event) {
        if (!this.isMouseDown) return;
        
        const deltaX = event.clientX - this.mouseX;
        const deltaY = event.clientY - this.mouseY;
        
        this.targetRotationY += deltaX * 0.01;
        this.targetRotationX += deltaY * 0.01;
        
        // Constrain vertical rotation
        this.targetRotationX = Math.max(-Math.PI / 2, Math.min(Math.PI / 2, this.targetRotationX));
        
        this.mouseX = event.clientX;
        this.mouseY = event.clientY;
    }
    
    onMouseUp() {
        this.isMouseDown = false;
        this.renderer.domElement.style.cursor = 'grab';
    }
    
    onWheel(event) {
        event.preventDefault();
        const delta = event.deltaY * 0.001;
        this.zoomTo(this.camera.position.z + delta);
    }

    /**
     * Zoom to a specific distance
     * @param {number} distance - Target camera distance
     * @param {boolean} smooth - Whether to animate the zoom (default: false)
     */
    zoomTo(distance, smooth = false) {
        const targetDistance = Math.max(
            this.config.minZoom,
            Math.min(this.config.maxZoom, distance)
        );
        
        if (smooth) {
            // Smooth zoom animation
            const startDistance = this.camera.position.z;
            const startTime = performance.now();
            const duration = 500; // 500ms animation
            
            const animateZoom = (currentTime) => {
                const elapsed = currentTime - startTime;
                const progress = Math.min(elapsed / duration, 1);
                
                // Ease-out animation
                const easeProgress = 1 - Math.pow(1 - progress, 3);
                
                this.camera.position.z = startDistance + (targetDistance - startDistance) * easeProgress;
                
                if (progress < 1) {
                    requestAnimationFrame(animateZoom);
                }
            };
            
            requestAnimationFrame(animateZoom);
        } else {
            this.camera.position.z = targetDistance;
        }
    }

    /**
     * Zoom in by a relative amount
     * @param {number} factor - Zoom factor (default: 0.8)
     * @param {boolean} smooth - Whether to animate (default: true)
     */
    zoomIn(factor = 0.8, smooth = true) {
        this.zoomTo(this.camera.position.z * factor, smooth);
    }

    /**
     * Zoom out by a relative amount
     * @param {number} factor - Zoom factor (default: 1.25)
     * @param {boolean} smooth - Whether to animate (default: true)
     */
    zoomOut(factor = 1.25, smooth = true) {
        this.zoomTo(this.camera.position.z * factor, smooth);
    }

    /**
     * Reset zoom to default distance
     * @param {boolean} smooth - Whether to animate (default: true)
     */
    resetZoom(smooth = true) {
        this.zoomTo(this.config.cameraDistance, smooth);
    }

    /**
     * Get current zoom level as a normalized value (0-1)
     * @returns {number} Zoom level between 0 (max zoom out) and 1 (max zoom in)
     */
    getZoomLevel() {
        const range = this.config.maxZoom - this.config.minZoom;
        const current = this.camera.position.z - this.config.minZoom;
        return 1 - (current / range); // Inverted so 1 = zoomed in, 0 = zoomed out
    }

    /**
     * Set zoom level using normalized value (0-1)
     * @param {number} level - Zoom level between 0 (max zoom out) and 1 (max zoom in)
     * @param {boolean} smooth - Whether to animate (default: true)
     */
    setZoomLevel(level, smooth = true) {
        const clampedLevel = Math.max(0, Math.min(1, level));
        const range = this.config.maxZoom - this.config.minZoom;
        const targetDistance = this.config.maxZoom - (clampedLevel * range);
        this.zoomTo(targetDistance, smooth);
    }
    
    onTouchStart(event) {
        event.preventDefault();
        if (event.touches.length === 1) {
            this.isMouseDown = true;
            this.mouseX = event.touches[0].clientX;
            this.mouseY = event.touches[0].clientY;
        }
    }
    
    onTouchMove(event) {
        event.preventDefault();
        if (!this.isMouseDown || event.touches.length !== 1) return;
        
        const deltaX = event.touches[0].clientX - this.mouseX;
        const deltaY = event.touches[0].clientY - this.mouseY;
        
        this.targetRotationY += deltaX * 0.01;
        this.targetRotationX += deltaY * 0.01;
        
        this.targetRotationX = Math.max(-Math.PI / 2, Math.min(Math.PI / 2, this.targetRotationX));
        
        this.mouseX = event.touches[0].clientX;
        this.mouseY = event.touches[0].clientY;
    }
    
    onTouchEnd() {
        this.isMouseDown = false;
    }
    
    onWindowResize() {
        if (!this.container) return;
        
        this.config.width = this.container.clientWidth;
        this.config.height = this.container.clientHeight;
        
        this.camera.aspect = this.config.width / this.config.height;
        this.camera.updateProjectionMatrix();
        
        this.renderer.setSize(this.config.width, this.config.height);
    }
    
    // Animation
    start() {
        if (this.isRunning) return;
        
        this.isRunning = true;
        this.startTime = performance.now();
        this.animate();
    }
    
    stop() {
        this.isRunning = false;
    }
    
    animate() {
        if (!this.isRunning) return;
        
        requestAnimationFrame(this.animate);
        
        // Update elapsed time
        this.elapsedTime = (performance.now() - this.startTime) * 0.001;
        
        // Update rotations with damping
        this.currentRotationX += (this.targetRotationX - this.currentRotationX) * this.config.damping;
        this.currentRotationY += (this.targetRotationY - this.currentRotationY) * this.config.damping;
        
        // Auto-rotation when not interacting
        if (this.config.autoRotate && !this.isMouseDown) {
            this.targetRotationY += this.config.autoRotateSpeed;
        }
        
        // Apply rotations
        this.group.rotation.x = this.currentRotationX;
        this.group.rotation.y = this.currentRotationY;
        
        // Update shader uniforms
        if (this.sphere && this.sphere.material) {
            this.sphere.material.uniforms.uTime.value = this.elapsedTime;
            this.sphere.material.uniforms.uCameraDistance.value = this.camera.position.length();
        }
        
        // Render
        this.renderer.render(this.scene, this.camera);
    }
    
    // Configuration
    updateConfig(newConfig) {
        Object.assign(this.config, newConfig);
        
        // Update shader uniforms if needed
        if (this.sphere?.material?.uniforms) {
            // Add specific uniform updates here based on config changes
        }
    }
    
    /**
     * Completely destroy the WavesSphere component
     * Removes from DOM, cleans up event listeners, and disposes of Three.js resources
     */
    destroy() {
        // Stop animation loop
        this.stop();
        
        // Remove event listeners
        this.removeEventListeners();
        
        // Dispose Three.js objects
        this.disposeThreeJSObjects();
        
        // Remove from DOM
        if (this.renderer?.domElement && this.container?.contains(this.renderer.domElement)) {
            this.container.removeChild(this.renderer.domElement);
        }
        
        // Clear references
        this.clearReferences();
    }

    /**
     * Legacy alias for destroy() - kept for backward compatibility
     */
    dispose() {
        this.destroy();
    }

    /**
     * Remove all event listeners
     * @private
     */
    removeEventListeners() {
        // Window events
        window.removeEventListener('resize', this.onWindowResize);
        
        // Canvas events
        if (this.renderer?.domElement) {
            const canvas = this.renderer.domElement;
            canvas.removeEventListener('mousedown', this.onMouseDown);
            canvas.removeEventListener('mousemove', this.onMouseMove);
            canvas.removeEventListener('mouseup', this.onMouseUp);
            canvas.removeEventListener('wheel', this.onWheel);
            canvas.removeEventListener('touchstart', this.onTouchStart);
            canvas.removeEventListener('touchmove', this.onTouchMove);
            canvas.removeEventListener('touchend', this.onTouchEnd);
        }
    }

    /**
     * Dispose of all Three.js objects and free memory
     * @private
     */
    disposeThreeJSObjects() {
        // Dispose sphere objects
        if (this.sphere) {
            if (this.sphere.geometry) {
                this.sphere.geometry.dispose();
            }
            if (this.sphere.material) {
                // Dispose material uniforms if they contain textures
                if (this.sphere.material.uniforms) {
                    Object.values(this.sphere.material.uniforms).forEach(uniform => {
                        if (uniform.value && uniform.value.dispose) {
                            uniform.value.dispose();
                        }
                    });
                }
                this.sphere.material.dispose();
            }
        }
        
        // Dispose background sphere
        if (this.backgroundSphere) {
            if (this.backgroundSphere.geometry) {
                this.backgroundSphere.geometry.dispose();
            }
            if (this.backgroundSphere.material) {
                this.backgroundSphere.material.dispose();
            }
        }
        
        // Dispose renderer
        if (this.renderer) {
            this.renderer.dispose();
            this.renderer.forceContextLoss();
            this.renderer.domElement = null;
        }
        
        // Clear scene
        if (this.scene) {
            this.scene.clear();
        }
    }

    /**
     * Clear all object references
     * @private
     */
    clearReferences() {
        this.scene = null;
        this.camera = null;
        this.renderer = null;
        this.sphere = null;
        this.backgroundSphere = null;
        this.group = null;
        
        // Reset state
        this.isRunning = false;
        this.isMouseDown = false;
    }

    /**
     * Check if the component is properly initialized
     * @returns {boolean} True if initialized and ready to use
     */
    isInitialized() {
        return !!(this.scene && this.camera && this.renderer && this.sphere);
    }

    /**
     * Get memory usage information (useful for debugging)
     * @returns {object} Memory usage stats
     */
    getMemoryUsage() {
        if (!this.renderer) return null;
        
        return {
            geometries: this.renderer.info.memory.geometries,
            textures: this.renderer.info.memory.textures,
            render: {
                calls: this.renderer.info.render.calls,
                triangles: this.renderer.info.render.triangles,
                points: this.renderer.info.render.points
            }
        };
    }
    
    // Shader code (embedded for completeness)
    getVertexShader() {
        return `
uniform float uTime;
uniform float uCameraDistance;

attribute vec3 initialPosition;
attribute float aRandom;

varying vec3 vColor;
varying float vIntensity;
varying vec3 vNormal;
varying vec3 vWorldPos;
varying float vEdgeFade;
varying float vDistortion;
varying float vRadialDist;
varying float vFoldDepth;

const float radius = 1.5;
const float PI = 3.14159265359;

// Wave System Functions
float createFoldingWaves(vec3 p) {
    float time = uTime;
    
    // Wave parameters
    float WAVE_FREQUENCY = 6.0;
    float WAVE_SPEED = 0.25;
    float WAVE_THICKNESS = 0.5;
    float WAVE_AMPLITUDE = 0.8;
    float WAVE_MAX_AMPLITUDE = 2.2;
    float WAVE_FORM = 1.0;
    
    float enableWave1Main = 1.0;
    float enableWave2Main = 1.0;
    
    float totalCycle = 20.0;
    float currentPhase = mod(time, totalCycle);
    
    float wave1_main = 0.0;
    float wave2_main = 0.0;
    
    float mainWaveCycle = 4.0;
    float mainWavePhase = mod(time, mainWaveCycle);
    
    vec3 origin1 = vec3(0.707, 0.707, 0.5);
    vec3 origin2 = vec3(-0.707, -0.707, 0.65);
    float clashDistance = length(origin1 - origin2);
    float clashPoint = clashDistance * 0.5;
    
    if (enableWave1Main > 0.0) {
        float expansionSpeed = WAVE_SPEED;
        float waveThickness = WAVE_THICKNESS;
        float waveFrequency = WAVE_FREQUENCY;
        float baseAmplitude = WAVE_AMPLITUDE;
        float maxAmplitude = WAVE_MAX_AMPLITUDE;
        
        float distFromOrigin1 = length(p - origin1);
        float waveAge = mainWavePhase;
        float waveRadius = waveAge * expansionSpeed;
        
        float maxRadius = clashPoint + waveThickness * 0.5;
        
        if (waveRadius < maxRadius) {
            float ringDistance = abs(distFromOrigin1 - waveRadius);
            if (ringDistance < waveThickness) {
                float progressToClash = waveRadius / clashPoint;
                float growthFactor = baseAmplitude + (maxAmplitude - baseAmplitude) * pow(progressToClash, 2.0);
                
                float clashFade = 1.0;
                if (waveRadius > clashPoint * 0.95) {
                    clashFade = 1.0 - smoothstep(clashPoint * 0.95, maxRadius, waveRadius);
                }
                
                float intensity = (1.0 - ringDistance / waveThickness) * clashFade;
                float waveShape = pow(abs(sin(ringDistance * waveFrequency)), WAVE_FORM);
                wave1_main = waveShape * intensity * growthFactor * enableWave1Main;
            }
        }
    }
    
    if (enableWave2Main > 0.0) {
        float expansionSpeed = WAVE_SPEED;
        float waveThickness = WAVE_THICKNESS;
        float waveFrequency = WAVE_FREQUENCY;
        float baseAmplitude = WAVE_AMPLITUDE;
        float maxAmplitude = WAVE_MAX_AMPLITUDE;
        
        float distFromOrigin2 = length(p - origin2);
        float waveAge = mainWavePhase;
        float waveRadius = waveAge * expansionSpeed;
        
        float maxRadius = clashPoint + waveThickness * 0.5;
        
        if (waveRadius < maxRadius) {
            float ringDistance = abs(distFromOrigin2 - waveRadius);
            if (ringDistance < waveThickness) {
                float progressToClash = waveRadius / clashPoint;
                float growthFactor = baseAmplitude + (maxAmplitude - baseAmplitude) * pow(progressToClash, 2.0);
                
                float clashFade = 1.0;
                if (waveRadius > clashPoint * 0.95) {
                    clashFade = 1.0 - smoothstep(clashPoint * 0.95, maxRadius, waveRadius);
                }
                
                float intensity = (1.0 - ringDistance / waveThickness) * clashFade;
                float waveShape = pow(abs(sin(ringDistance * waveFrequency)), WAVE_FORM);
                wave2_main = waveShape * intensity * growthFactor * enableWave2Main;
            }
        }
    }
    
    float totalWave = wave1_main + wave2_main;
    
    if (abs(wave1_main) > 0.01 && abs(wave2_main) > 0.01) {
        totalWave *= 1.5;
    }
    
    float distanceFromCenter = length(p);
    if (distanceFromCenter > 1.4) {
        totalWave *= -0.2;
    }
    
    return clamp(totalWave, -0.05, 0.1);
}

float createAsymmetricDistortion(vec3 p) {
    float time = uTime;
    float drift1 = sin(p.x * 2.0 + time * 0.8) * cos(p.y * 1.5 + time * 0.6) * 0.008;
    float drift2 = cos(p.z * 2.5 + time * 0.4) * sin(p.x * 1.8 + time * 0.9) * 0.006;
    return drift1 + drift2;
}

float createSphericalShape(vec3 p) {
    float r = length(p);
    float baseShape = radius - r;
    
    float foldingWaves = createFoldingWaves(p);
    float asymmetric = createAsymmetricDistortion(p);
    
    float totalDisplacement = foldingWaves + asymmetric;
    totalDisplacement = clamp(totalDisplacement, -0.35, 0.35);
    
    return baseShape + totalDisplacement;
}

void main() {
    vec3 pos = initialPosition;
    vec3 originalNormal = normalize(pos);
    
    float shapeDisplacement = createSphericalShape(pos);
    float totalDisplacement = shapeDisplacement;
    
    vec3 displaced = pos + originalNormal * totalDisplacement;
    
    vFoldDepth = createFoldingWaves(pos);
    vRadialDist = length(displaced) / radius;
    
    vec3 viewDir = normalize(cameraPosition - displaced);
    float edgeFactor = abs(dot(originalNormal, viewDir)); 
    vEdgeFade = max(0.7, smoothstep(0.1, 0.9, edgeFactor));
    
    if (vFoldDepth < -0.15) {
        float foldFade = 1.0 + vFoldDepth * 1.5;
        vEdgeFade *= max(foldFade, 0.6);
    }
    
    vDistortion = totalDisplacement;
    
    vec3 tangent1 = normalize(cross(originalNormal, vec3(0.0, 1.0, 0.0)));
    if (length(tangent1) < 0.01) {
        tangent1 = normalize(cross(originalNormal, vec3(1.0, 0.0, 0.0)));
    }
    vec3 tangent2 = normalize(cross(originalNormal, tangent1));
    
    float epsilon = 0.01;
    vec3 posT1 = pos + tangent1 * epsilon;
    vec3 posT2 = pos + tangent2 * epsilon;
    float dispT1 = createSphericalShape(posT1);
    float dispT2 = createSphericalShape(posT2);
    
    vec3 perturbedNormal = normalize(originalNormal + 
        tangent1 * (dispT1 - shapeDisplacement) * 30.0 + 
        tangent2 * (dispT2 - shapeDisplacement) * 30.0);
    
    vNormal = perturbedNormal;
    vWorldPos = displaced;
    
    vec4 worldPos4 = modelMatrix * vec4(displaced, 1.0);
    vec3 worldPosition = worldPos4.xyz;
    vec3 worldNormal = normalize((modelMatrix * vec4(perturbedNormal, 0.0)).xyz);
    
    // Eclipse color calculation (simplified)
    vec3 centerBlack = vec3(0.078, 0.098, 0.086);
    vec3 deepViolet = vec3(0.12, 0.0, 0.30);
    vec3 purple = vec3(0.35, 0.0, 0.7);
    vec3 magenta = vec3(0.6, 0.0, 0.6);
    vec3 pink = vec3(0.85, 0.15, 0.45);
    vec3 red = vec3(1.0, 0.1, 0.2);
    vec3 orange = vec3(1.0, 0.4, 0.0);
    vec3 goldenYellow = vec3(1.0, 0.8, 0.2);
    vec3 brightGold = vec3(1.0, 0.9, 0.4);
    vec3 coronaGlow = vec3(1.0, 1.0, 0.5);
    
    vec3 worldViewDir = normalize(cameraPosition - worldPosition);
    float rimFactor = 1.0 - abs(dot(perturbedNormal, worldViewDir));
    float eclipseFactor = smoothstep(0.0, 1.0, rimFactor);
    
    vec3 color = centerBlack;
    
    if (eclipseFactor > 0.0) {
        float t = smoothstep(0.0, 0.25, eclipseFactor);
        color = mix(centerBlack, deepViolet, t);
    }
    if (eclipseFactor > 0.20) {
        float t = smoothstep(0.20, 0.35, eclipseFactor);
        color = mix(color, purple, t * 0.9);
    }
    if (eclipseFactor > 0.50) {
        float t = smoothstep(0.50, 0.65, eclipseFactor);
        color = mix(color, magenta, t * 0.95);
    }
    if (eclipseFactor > 0.60) {
        float t = smoothstep(0.60, 0.72, eclipseFactor);
        color = mix(color, pink, t * 0.9);
    }
    if (eclipseFactor > 0.70) {
        float t = smoothstep(0.70, 0.80, eclipseFactor);
        color = mix(color, red, t * 0.95);
    }
    if (eclipseFactor > 0.80) {
        float t = smoothstep(0.80, 0.90, eclipseFactor);
        color = mix(color, orange, t * 0.85);
    }
    if (eclipseFactor > 0.88) {
        float t = smoothstep(0.88, 0.95, eclipseFactor);
        color = mix(color, goldenYellow, t * 0.9);
    }
    if (eclipseFactor > 0.95) {
        float t = smoothstep(0.95, 1.0, eclipseFactor);
        color = mix(color, brightGold, t);
    }
    
    vIntensity = 1.0;
    vColor = color;
    
    vec4 mvPosition = modelViewMatrix * vec4(displaced, 1.0);
    
    float baseSize = 6.0;
    float screenScale = 6.0;
    float zoomFactor = sqrt(uCameraDistance / 3.5);
    float perspectiveScale = screenScale * zoomFactor;
    float randomSize = 0.95 + aRandom * 0.1;
    
    gl_PointSize = baseSize * perspectiveScale * randomSize;
    gl_PointSize = clamp(gl_PointSize, 1.0, 12.0);
    
    gl_Position = projectionMatrix * mvPosition;
}
        `;
    }
    
    getFragmentShader() {
        return `
varying vec3 vColor;
varying float vIntensity;
varying float vEdgeFade;

void main() {
    vec2 center = gl_PointCoord - vec2(0.5);
    float dist = length(center);
    
    if (dist > 0.5) {
        discard;
    }
    
    float alpha = 1.0 - smoothstep(0.3, 0.5, dist);
    alpha *= vEdgeFade;
    alpha *= vIntensity;
    
    vec3 dotColor = vColor;
    
    if (vIntensity > 0.7) {
        float glow = 1.0 - dist * 1.5;
        dotColor += vColor * glow * 0.4;
        
        if (vIntensity > 0.9) {
            float corona = smoothstep(0.5, 0.0, dist);
            dotColor += vec3(1.0, 0.9, 0.7) * corona * 0.2;
        }
    }
    
    gl_FragColor = vec4(dotColor, alpha);
}
        `;
    }
}

// Export for ES6 modules
export default WavesSphere;