import * as THREE from 'three';
import planetVertexShader from './shaders/planetVertex.glsl?raw';
import planetFragmentShader from './shaders/planetFragment.glsl?raw';
import {
  globalLiquidMovement,
  globalTransparency,
  globalBlobness,
  globalColorCoverage,
  globalShaderControls,
} from './planetsConfig.js';

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
    this.blobness =
      config.blobness !== undefined ? config.blobness : globalBlobness; // Use global or individual blobness

    // Unique seed for each planet's random deformation
    this.seed = config.seed || Math.random() * 1000;

    // Color coverage from rim (how much of sphere is colored vs black)
    this.colorCoverage =
      config.colorCoverage !== undefined
        ? config.colorCoverage
        : globalColorCoverage;

    // Text properties
    this.text = config.text || '';
    this.textColor = config.textColor || '#FFFFFF';
    this.textSize = config.textSize || 0.1;

    // Color configuration
    this.baseColor = new THREE.Color(config.color.base || '#FFFFFF');
    this.glowIntensity = config.color.glowIntensity || 0.3;
    this.transparency =
      config.transparency !== undefined
        ? config.transparency
        : globalTransparency; // Use global or individual transparency

    // Use global liquid movement settings for all planets
    this.liquidMovement = globalLiquidMovement;

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

    // Create shader material with transparency
    const material = new THREE.ShaderMaterial({
      uniforms: {
        uTime: { value: 0 },
        uScale: { value: this.size },
        uBaseColor: { value: this.baseColor },
        uGlowIntensity: { value: this.glowIntensity },
        uTransparency: { value: this.transparency },
        uBlobness: { value: this.blobness },
        uWaveSpeed: { value: this.liquidMovement.waveSpeed },
        uWaveAmplitude: { value: this.liquidMovement.waveAmplitude },
        uBreathingSpeed: { value: this.liquidMovement.breathingSpeed },
        uBreathingScale: { value: this.liquidMovement.breathingScale },
        uSeed: { value: this.seed },
        uColorCoverage: { value: this.colorCoverage },
        // Shader control uniforms
        uRimGlowIntensity: { value: globalShaderControls.rimGlowIntensity },
        uRimGlowWidth: { value: globalShaderControls.rimGlowWidth },
        uAuraIntensity: { value: globalShaderControls.auraIntensity },
        uAuraWidth: { value: globalShaderControls.auraWidth },
        uSpecularIntensity: { value: globalShaderControls.specularIntensity },
        uSpecularSharpness: { value: globalShaderControls.specularSharpness },
        uBoundaryGlow: { value: globalShaderControls.boundaryGlow },
        uSurfaceGlow: { value: globalShaderControls.surfaceGlow },
        uShimmerIntensity: { value: globalShaderControls.shimmerIntensity },
        uOverallBoost: { value: globalShaderControls.overallBoost },
        uBlackTint: { value: globalShaderControls.blackTint },
        uBreathingIntensity: { value: globalShaderControls.breathingIntensity },
        uPulseIntensity: { value: globalShaderControls.pulseIntensity },
        uSunPosition: { value: new THREE.Vector3(0, 0, 0) },
      },
      vertexShader: planetVertexShader,
      fragmentShader: planetFragmentShader,
      side: THREE.FrontSide,
      transparent: true,
      depthWrite: true,
      blending: THREE.NormalBlending,
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
    canvas.width = 1024;
    canvas.height = 512;

    // Configure text
    const fontSize = 42;
    context.font = `bold ${fontSize}px Arial`;
    context.fillStyle = this.textColor;
    context.textAlign = 'center';
    context.textBaseline = 'middle';

    // Text wrapping function with improved word handling and newline support
    const wrapText = (text, maxWidth) => {
      // First split by newline characters
      const paragraphs = text.split('\n');
      const lines = [];

      for (const paragraph of paragraphs) {
        const words = paragraph.trim().split(' ');
        let currentLine = words[0] || '';

        for (let i = 1; i < words.length; i++) {
          const word = words[i];
          const testLine = currentLine ? currentLine + ' ' + word : word;
          const width = context.measureText(testLine).width;

          if (width < maxWidth) {
            currentLine = testLine;
          } else {
            if (currentLine) {
              lines.push(currentLine);
            }
            // Check if single word is too long
            if (context.measureText(word).width > maxWidth) {
              // Break long word if needed
              const chars = word.split('');
              let wordPart = '';
              for (const char of chars) {
                const testPart = wordPart + char;
                if (context.measureText(testPart).width < maxWidth) {
                  wordPart = testPart;
                } else {
                  if (wordPart) lines.push(wordPart);
                  wordPart = char;
                }
              }
              currentLine = wordPart;
            } else {
              currentLine = word;
            }
          }
        }
        if (currentLine) {
          lines.push(currentLine);
        }
      }
      return lines;
    };

    // Wrap text to fit
    const maxWidth = canvas.width * 0.8; // 80% of canvas width
    const lines = wrapText(this.text, maxWidth);

    // Calculate line height and starting position
    const lineHeight = fontSize * 1.2;
    const totalHeight = lines.length * lineHeight;
    const startY = canvas.height / 2 - totalHeight / 2 + lineHeight / 2;

    // Draw each line
    lines.forEach((line, index) => {
      const y = startY + index * lineHeight;
      context.fillText(line, canvas.width / 2, y);
    });

    // Create texture from canvas
    const texture = new THREE.Texture(canvas);
    texture.needsUpdate = true;

    // Create sprite material
    const spriteMaterial = new THREE.SpriteMaterial({
      map: texture,
      transparent: true,
      depthTest: false,
      depthWrite: false,
    });

    // Create sprite with adjusted scale for wrapped text
    this.textMesh = new THREE.Sprite(spriteMaterial);
    const scaleMultiplier = Math.min(1.0, 3.0 / lines.length); // Scale down for multiple lines
    // Apply individual text size from config
    const textSizeScale = this.textSize || 1.0;
    this.textMesh.scale.set(
      this.size * 2.5 * scaleMultiplier * textSizeScale,
      this.size * 1.25 * scaleMultiplier * textSizeScale,
      1
    );
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

    // Update position
    if (position) {
      this.group.position.copy(position);
    }

    // Make the sphere face the camera so the black center is always visible
    if (camera) {
      this.mesh.lookAt(camera.position);
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
