import * as THREE from 'three';
import starVertexShader from './shaders/starVertex.glsl?raw';
import starFragmentShader from './shaders/starFragment.glsl?raw';

/**
 * StarField Class
 * Creates a 3D starfield background for the solar system
 * Features: Random star distribution, twinkling effect, varying sizes and colors
 */
export class StarField {
  constructor(starCount = 5000, radius = 100) {
    // Configuration
    this.starCount = starCount;
    this.radius = radius;

    // Three.js objects
    this.stars = null;
    this.starMaterial = null;
    this.geometry = null;

    // Initialize the starfield
    this.init();
  }

  /**
   * Initialize the starfield
   */
  init() {
    this.createGeometry();
    this.createMaterial();
    this.createMesh();
  }

  /**
   * Create star geometry with positions, colors, and sizes
   */
  createGeometry() {
    this.geometry = new THREE.BufferGeometry();

    // Attribute arrays
    const positions = new Float32Array(this.starCount * 3);
    const colors = new Float32Array(this.starCount * 3);
    const sizes = new Float32Array(this.starCount);

    // Generate star data
    this.generateStarData(positions, colors, sizes);

    // Set buffer attributes
    this.geometry.setAttribute(
      'position',
      new THREE.BufferAttribute(positions, 3)
    );
    this.geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));
    this.geometry.setAttribute('size', new THREE.BufferAttribute(sizes, 1));
  }

  /**
   * Generate random star positions, colors, and sizes
   */
  generateStarData(positions, colors, sizes) {
    for (let i = 0; i < this.starCount; i++) {
      const i3 = i * 3;

      // Random spherical coordinates for uniform distribution
      const theta = Math.random() * Math.PI * 2;
      const phi = Math.acos(2 * Math.random() - 1);
      const distance = this.radius * (0.5 + Math.random() * 0.5);

      // Convert to Cartesian coordinates
      positions[i3] = distance * Math.sin(phi) * Math.cos(theta);
      positions[i3 + 1] = distance * Math.sin(phi) * Math.sin(theta);
      positions[i3 + 2] = distance * Math.cos(phi);

      // Star colors (white to bluish-white)
      const intensity = 0.5 + Math.random() * 0.5;
      colors[i3] = intensity * (0.9 + Math.random() * 0.1); // R
      colors[i3 + 1] = intensity * (0.9 + Math.random() * 0.1); // G
      colors[i3 + 2] = intensity; // B (bluer)

      // More varied star sizes - some very small, some large
      const sizeRandom = Math.random();
      if (sizeRandom < 0.6) {
        // 60% small stars
        sizes[i] = Math.random() * 3.0 + 1.0;
      } else if (sizeRandom < 0.85) {
        // 25% medium stars
        sizes[i] = Math.random() * 4.0 + 1.0;
      } else if (sizeRandom < 0.95) {
        // 10% large stars
        sizes[i] = Math.random() * 6.0 + 2.0;
      } else {
        // 5% very large stars
        sizes[i] = Math.random() * 8.0 + 3.0;
      }
    }
  }

  /**
   * Create shader material for stars with twinkling effect
   */
  createMaterial() {
    this.starMaterial = new THREE.ShaderMaterial({
      uniforms: {
        uTime: { value: 0 },
        uTexture: { value: this.createStarTexture() },
      },
      vertexShader: starVertexShader,
      fragmentShader: starFragmentShader,
      transparent: true,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
      vertexColors: true,
    });
  }

  /**
   * Create star texture for point sprites
   */
  createStarTexture() {
    const canvas = document.createElement('canvas');
    canvas.width = 32;
    canvas.height = 32;

    const context = canvas.getContext('2d');
    const gradient = context.createRadialGradient(16, 16, 0, 16, 16, 16);

    // Star glow gradient
    gradient.addColorStop(0, 'rgba(255, 255, 255, 1)');
    gradient.addColorStop(0.2, 'rgba(255, 255, 255, 0.8)');
    gradient.addColorStop(0.4, 'rgba(255, 255, 255, 0.3)');
    gradient.addColorStop(1, 'rgba(255, 255, 255, 0)');

    context.fillStyle = gradient;
    context.fillRect(0, 0, 32, 32);

    const texture = new THREE.Texture(canvas);
    texture.needsUpdate = true;

    return texture;
  }

  /**
   * Create the points mesh
   */
  createMesh() {
    this.stars = new THREE.Points(this.geometry, this.starMaterial);
  }

  /**
   * Update animation (twinkling and rotation)
   * @param {number} time - Elapsed time in seconds
   */
  update(time) {
    if (this.starMaterial) {
      // Update shader time uniform for twinkling
      this.starMaterial.uniforms.uTime.value = time;

      // Very slow rotation for subtle movement
      this.stars.rotation.y = time * 0.01;
    }
  }

  /**
   * Get the Three.js mesh object
   * @returns {THREE.Points} The stars mesh
   */
  getMesh() {
    return this.stars;
  }

  /**
   * Clean up resources
   */
  dispose() {
    if (this.geometry) {
      this.geometry.dispose();
    }
    if (this.starMaterial) {
      this.starMaterial.uniforms.uTexture.value.dispose();
      this.starMaterial.dispose();
    }
  }
}
