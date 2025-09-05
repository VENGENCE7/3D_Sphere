import * as THREE from 'three';
import planetVertexShader from './shaders/planetVertex.glsl?raw';
import planetFragmentShader from './shaders/planetFragment.glsl?raw';

/**
 * PlanetBlob Class
 * Creates a blob-like planet with organic liquid movement
 * Smooth surface (not dots) with gradient from color to black
 */
export class PlanetBlob {
    constructor(config) {
        // Planet configuration
        this.config = config;
        this.id = config.id;
        this.size = config.size || 0.5;
        this.blobness = config.blobness || 0.15;
        
        // Text properties
        this.text = config.text || '';
        this.textColor = config.textColor || '#FFFFFF';
        this.textSize = config.textSize || 0.1;
        
        // Color configuration
        this.baseColor = new THREE.Color(config.color.base || '#FFFFFF');
        this.glowIntensity = config.color.glowIntensity || 0.3;
        
        // Liquid movement settings
        this.liquidMovement = config.liquidMovement || {
            enabled: true,
            waveSpeed: 0.5,
            waveAmplitude: 0.15,
            breathingSpeed: 0.3,
            breathingScale: 0.05,
            noiseScale: 2.5,
            flowSpeed: 0.2
        };
        
        // Rotation settings
        this.rotationSpeed = config.rotation?.speed || 0.005;
        this.rotationAxis = new THREE.Vector3(
            config.rotation?.axis?.x || 0,
            config.rotation?.axis?.y || 1,
            config.rotation?.axis?.z || 0
        ).normalize();
        
        // Three.js objects
        this.mesh = null;
        this.textMesh = null;
        this.group = new THREE.Group();
        
        // Initialize the planet
        this.init();
    }
    
    /**
     * Initialize the planet blob
     */
    init() {
        this.createPlanetMesh();
        this.createTextLabel();
        
        // Add mesh to group
        this.group.add(this.mesh);
        if (this.textMesh) {
            this.group.add(this.textMesh);
        }
    }
    
    /**
     * Create the planet mesh with smooth blob surface
     */
    createPlanetMesh() {
        // Create sphere geometry with enough detail for smooth deformation
        const geometry = new THREE.SphereGeometry(1, 64, 64);
        
        // Create shader material
        const material = new THREE.ShaderMaterial({
            uniforms: {
                uTime: { value: 0 },
                uScale: { value: this.size },
                uBaseColor: { value: this.baseColor },
                uGlowIntensity: { value: this.glowIntensity },
                uBlobness: { value: this.blobness },
                uWaveSpeed: { value: this.liquidMovement.waveSpeed },
                uWaveAmplitude: { value: this.liquidMovement.waveAmplitude },
                uBreathingSpeed: { value: this.liquidMovement.breathingSpeed },
                uBreathingScale: { value: this.liquidMovement.breathingScale },
                uSunPosition: { value: new THREE.Vector3(0, 0, 0) }
            },
            vertexShader: planetVertexShader,
            fragmentShader: planetFragmentShader,
            side: THREE.DoubleSide
        });
        
        this.mesh = new THREE.Mesh(geometry, material);
    }
    
    /**
     * Create text label that floats inside the blob
     */
    createTextLabel() {
        if (!this.text) return;
        
        // Use CSS2DRenderer for text that always faces camera
        // For now, using a simple sprite as placeholder
        const canvas = document.createElement('canvas');
        const context = canvas.getContext('2d');
        canvas.width = 512;
        canvas.height = 256;
        
        // Configure text
        context.font = `bold 48px Arial`;
        context.fillStyle = this.textColor;
        context.textAlign = 'center';
        context.textBaseline = 'middle';
        
        // Draw text
        context.fillText(this.text, canvas.width / 2, canvas.height / 2);
        
        // Create texture from canvas
        const texture = new THREE.Texture(canvas);
        texture.needsUpdate = true;
        
        // Create sprite material
        const spriteMaterial = new THREE.SpriteMaterial({
            map: texture,
            transparent: true,
            depthTest: false,
            depthWrite: false
        });
        
        // Create sprite
        this.textMesh = new THREE.Sprite(spriteMaterial);
        this.textMesh.scale.set(this.size * 2, this.size * 1, 1);
    }
    
    /**
     * Update the planet animation
     * @param {number} time - Elapsed time
     * @param {THREE.Vector3} position - Current position in world space
     * @param {THREE.Camera} camera - Camera for dynamic sizing
     */
    update(time, position, camera) {
        if (!this.mesh) return;
        
        // Update shader uniforms
        this.mesh.material.uniforms.uTime.value = time;
        
        // Self-rotation
        this.mesh.rotateOnAxis(this.rotationAxis, this.rotationSpeed);
        
        // Update position
        if (position) {
            this.group.position.copy(position);
        }
        
        // Dynamic sizing based on distance from camera
        if (camera) {
            const distance = camera.position.distanceTo(this.group.position);
            
            // Organic size changes based on distance
            const baseSizeFactor = 1.0;
            const distanceFactor = Math.max(0.5, Math.min(1.5, 10 / distance));
            
            // Add organic breathing independent of distance
            const breathing = Math.sin(time * this.liquidMovement.breathingSpeed) * 0.05 + 1.0;
            
            const finalScale = baseSizeFactor * distanceFactor * breathing;
            this.group.scale.setScalar(finalScale);
        }
        
        // Make text always face camera
        if (this.textMesh && camera) {
            this.textMesh.lookAt(camera.position);
        }
    }
    
    /**
     * Set the planet's position
     */
    setPosition(x, y, z) {
        this.group.position.set(x, y, z);
    }
    
    /**
     * Get the planet's group for adding to scene
     * @returns {THREE.Group} Planet group
     */
    getGroup() {
        return this.group;
    }
    
    /**
     * Get the planet's configuration
     */
    getConfig() {
        return this.config;
    }
    
    /**
     * Clean up resources
     */
    dispose() {
        if (this.mesh) {
            this.mesh.geometry.dispose();
            this.mesh.material.dispose();
        }
        if (this.textMesh) {
            this.textMesh.material.map.dispose();
            this.textMesh.material.dispose();
        }
    }
}