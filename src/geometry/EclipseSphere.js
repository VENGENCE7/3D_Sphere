import * as THREE from 'three';
import vertexShader from '../shaders/vertexShader.glsl?raw';
import fragmentShader from '../shaders/fragmentShader.glsl?raw';

export class EclipseSphere {
    constructor(radius = 1.5) {
        this.radius = radius;
        this.sphere = null;
        this.material = null;
        this.geometry = null;
        this.solidSphere = null; // Solid black sphere underneath
        this.blackBackgroundSphere = null; // Black background layer
        this.group = null; // Group to hold both spheres
        
        this.createGeometry();
        this.createMaterial();
        this.createSphere();
        this.createSolidBlackSphere();
        this.createBlackBackgroundSphere();
        this.createGroup();
    }
    
    createEclipseSpherePositions(radius) {
        const points = [];
        
        // === HEXAGONAL PACKING PATTERN - FULL SPHERE FOR INTERACTIVE VIEWING ===
        const latLines = 280;  // Increased for better clarity and density
        
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
                
                // Include all points for full sphere
                points.push(x, y, z);
                
            }
        }
        
        return new Float32Array(points);
    }
    
    createGeometry() {
        const positions = this.createEclipseSpherePositions(this.radius);
        
        this.geometry = new THREE.BufferGeometry();
        this.geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
        
        const initialPositions = new Float32Array(positions);
        this.geometry.setAttribute('initialPosition', new THREE.BufferAttribute(initialPositions, 3));
        
        const randoms = new Float32Array(positions.length / 3);
        for (let i = 0; i < randoms.length; i++) {
            randoms[i] = Math.random();
        }
        this.geometry.setAttribute('aRandom', new THREE.BufferAttribute(randoms, 1));
    }
    
    createMaterial() {
        this.material = new THREE.ShaderMaterial({
            vertexShader,
            fragmentShader,
            uniforms: {
                uTime: { value: 0.0 },
                uCameraDistance: { value: 3.5 }  // For dynamic dot sizing
            },
            transparent: true,
            depthTest: true,
            depthWrite: false,
            blending: THREE.NormalBlending
        });
    }
    
    createSphere() {
        this.sphere = new THREE.Points(this.geometry, this.material);
        
        // Ensure dots render in front of background sphere
        this.sphere.renderOrder = 1;
    }
    
    createSolidBlackSphere() {
        // No longer needed - using unified dots-only approach
        this.solidSphere = null;
    }
    
    createBlackBackgroundSphere() {
        // Create a black background sphere slightly smaller than the dots
        // This provides a unified black sheet underneath the dots
        const backgroundGeometry = new THREE.SphereGeometry(
            this.radius * 0.95, // Smaller to stay well behind animated dots
            64, // High resolution for smooth appearance
            32  // High resolution for smooth appearance
        );
        
        // Create a pure black material with adjusted depth settings
        const backgroundMaterial = new THREE.MeshBasicMaterial({
            color: 0x141916, // Pure black
            side: THREE.FrontSide, // Only render front faces
            transparent: false,
            depthWrite: true,
            depthTest: true
        });
        
        this.blackBackgroundSphere = new THREE.Mesh(backgroundGeometry, backgroundMaterial);
        
        // Ensure background renders behind dots by adjusting render order
        this.blackBackgroundSphere.renderOrder = -1;
    }
    
    createGroup() {
        // Create a group to hold the black background and dots sphere
        this.group = new THREE.Group();
        this.group.add(this.blackBackgroundSphere); // Add black background first (behind)
        this.group.add(this.sphere);                 // Add dots sphere on top
    }
    
    update(elapsedTime, camera) {
        if (this.material) {
            this.material.uniforms.uTime.value = elapsedTime;
    
            // Update camera distance to sphere center (assume at origin)
            const camDist = camera.position.length();
            this.material.uniforms.uCameraDistance.value = camDist;
        }
    }
    
    getMesh() {
        return this.group; // Return the group containing both spheres
    }
    
    dispose() {
        if (this.geometry) {
            this.geometry.dispose();
        }
        if (this.material) {
            this.material.dispose();
        }
        if (this.solidSphere) {
            this.solidSphere.geometry.dispose();
            this.solidSphere.material.dispose();
        }
        if (this.blackBackgroundSphere) {
            this.blackBackgroundSphere.geometry.dispose();
            this.blackBackgroundSphere.material.dispose();
        }
    }
}