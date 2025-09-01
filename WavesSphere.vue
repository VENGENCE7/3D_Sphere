<template>
  <div ref="containerRef" class="waves-sphere-container">
    <canvas ref="canvasRef"></canvas>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue';
import * as THREE from 'three';

// Props for customization
const props = defineProps({
  width: {
    type: Number,
    default: 800
  },
  height: {
    type: Number,
    default: 600
  },
  radius: {
    type: Number,
    default: 1.5
  },
  backgroundColor: {
    type: String,
    default: '#000000'
  },
  enableRotation: {
    type: Boolean,
    default: true
  },
  enableZoom: {
    type: Boolean,
    default: true
  },
  autoRotate: {
    type: Boolean,
    default: false
  },
  autoRotateSpeed: {
    type: Number,
    default: 1.0
  }
});

// Template refs
const containerRef = ref(null);
const canvasRef = ref(null);

// Three.js objects
let scene, camera, renderer, sphere, material, animationId;
let controls = null;
let clock = new THREE.Clock();

// Simplified vertex shader
const vertexShader = `
uniform float uTime;
uniform float uCameraDistance;

attribute vec3 initialPosition;
attribute float aRandom;

varying vec3 vColor;

const float radius = 1.5;
const float PI = 3.14159265359;

float createWaves(vec3 p) {
    float time = uTime;
    
    // Wave configuration
    float WAVE_FREQUENCY = 6.0;
    float WAVE_SPEED = 0.25;
    float WAVE_AMPLITUDE = 0.8;
    
    // Wave origin points
    vec3 origin1 = vec3(0.707, 0.707, 0.5);
    vec3 origin2 = vec3(-0.707, -0.707, 0.65);
    
    float mainWaveCycle = 4.0;
    float mainWavePhase = mod(time, mainWaveCycle);
    
    float wave1 = 0.0;
    float wave2 = 0.0;
    
    // Wave 1
    float distFromOrigin1 = length(p - origin1);
    float waveRadius1 = mainWavePhase * WAVE_SPEED;
    float ringDistance1 = abs(distFromOrigin1 - waveRadius1);
    if (ringDistance1 < 0.5) {
        float intensity = (1.0 - ringDistance1 / 0.5);
        wave1 = sin(ringDistance1 * WAVE_FREQUENCY) * intensity * WAVE_AMPLITUDE;
    }
    
    // Wave 2
    float distFromOrigin2 = length(p - origin2);
    float waveRadius2 = mainWavePhase * WAVE_SPEED;
    float ringDistance2 = abs(distFromOrigin2 - waveRadius2);
    if (ringDistance2 < 0.5) {
        float intensity = (1.0 - ringDistance2 / 0.5);
        wave2 = sin(ringDistance2 * WAVE_FREQUENCY) * intensity * WAVE_AMPLITUDE;
    }
    
    return wave1 + wave2;
}

void main() {
    vec3 pos = initialPosition;
    vec3 originalNormal = normalize(pos);
    
    // Apply wave displacement
    float displacement = createWaves(pos) * 0.1;
    vec3 displaced = pos + originalNormal * displacement;
    
    // Calculate color based on position (simplified eclipse gradient)
    vec3 worldPos = (modelMatrix * vec4(displaced, 1.0)).xyz;
    vec3 viewDir = normalize(cameraPosition - worldPos);
    float rimFactor = 1.0 - abs(dot(originalNormal, viewDir));
    
    // Color gradient
    vec3 centerColor = vec3(0.078, 0.098, 0.086);
    vec3 purple = vec3(0.35, 0.0, 0.7);
    vec3 blue = vec3(0.26, 0.0, 0.93);
    vec3 magenta = vec3(0.6, 0.0, 0.6);
    vec3 orange = vec3(1.0, 0.4, 0.0);
    vec3 gold = vec3(1.0, 0.9, 0.4);
    
    vec3 color = centerColor;
    
    if (rimFactor > 0.2) {
        float t = smoothstep(0.2, 0.4, rimFactor);
        color = mix(color, purple, t);
    }
    if (rimFactor > 0.4) {
        float t = smoothstep(0.4, 0.6, rimFactor);
        color = mix(color, blue, t);
    }
    if (rimFactor > 0.6) {
        float t = smoothstep(0.6, 0.75, rimFactor);
        color = mix(color, magenta, t);
    }
    if (rimFactor > 0.75) {
        float t = smoothstep(0.75, 0.85, rimFactor);
        color = mix(color, orange, t);
    }
    if (rimFactor > 0.85) {
        float t = smoothstep(0.85, 1.0, rimFactor);
        color = mix(color, gold, t);
    }
    
    vColor = color;
    
    // Point size
    vec4 mvPosition = modelViewMatrix * vec4(displaced, 1.0);
    float zoomFactor = sqrt(uCameraDistance / 3.5);
    gl_PointSize = 6.0 * zoomFactor;
    gl_PointSize = clamp(gl_PointSize, 1.0, 12.0);
    
    gl_Position = projectionMatrix * mvPosition;
}
`;

// Simplified fragment shader
const fragmentShader = `
varying vec3 vColor;

void main() {
    vec2 center = gl_PointCoord - vec2(0.5);
    float dist = length(center);
    
    if (dist > 0.45) discard;
    
    float alpha = smoothstep(0.45, 0.15, dist);
    
    vec3 dotColor = vColor;
    
    // Add black border
    if (dist > 0.3) {
        float borderFactor = smoothstep(0.3, 0.45, dist);
        dotColor = mix(dotColor, vec3(0.0), borderFactor * 0.8);
    }
    
    gl_FragColor = vec4(dotColor, alpha);
}
`;

// Create sphere geometry with hexagonal packing
function createSphereGeometry(radius) {
  const points = [];
  const latLines = 120; // Reduced for performance
  const hexRowHeight = Math.PI / latLines;
  
  for (let lat = 0; lat <= latLines; lat++) {
    const theta = lat * hexRowHeight;
    const sinTheta = Math.sin(theta);
    const cosTheta = Math.cos(theta);
    
    const circumference = 2 * Math.PI * radius * sinTheta;
    const targetSpacing = (2 * Math.PI * radius) / 180;
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

// Initialize Three.js scene
function initScene() {
  // Scene
  scene = new THREE.Scene();
  scene.background = new THREE.Color(props.backgroundColor);
  
  // Camera
  camera = new THREE.PerspectiveCamera(
    60,
    props.width / props.height,
    0.1,
    1000
  );
  camera.position.set(0, 0, 3.5);
  camera.lookAt(0, 0, 0);
  
  // Renderer
  renderer = new THREE.WebGLRenderer({ 
    canvas: canvasRef.value,
    antialias: true,
    alpha: true 
  });
  renderer.setSize(props.width, props.height);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  
  // Create sphere geometry
  const positions = createSphereGeometry(props.radius);
  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
  geometry.setAttribute('initialPosition', new THREE.BufferAttribute(positions.slice(), 3));
  
  // Add random attributes
  const randoms = new Float32Array(positions.length / 3);
  for (let i = 0; i < randoms.length; i++) {
    randoms[i] = Math.random();
  }
  geometry.setAttribute('aRandom', new THREE.BufferAttribute(randoms, 1));
  
  // Create material
  material = new THREE.ShaderMaterial({
    vertexShader,
    fragmentShader,
    uniforms: {
      uTime: { value: 0.0 },
      uCameraDistance: { value: 3.5 }
    },
    transparent: true,
    depthTest: true,
    depthWrite: false,
    blending: THREE.NormalBlending
  });
  
  // Create sphere mesh
  sphere = new THREE.Points(geometry, material);
  scene.add(sphere);
  
  // Add background sphere
  const bgGeometry = new THREE.SphereGeometry(props.radius * 0.95, 64, 32);
  const bgMaterial = new THREE.MeshBasicMaterial({
    color: 0x141916,
    side: THREE.FrontSide
  });
  const bgSphere = new THREE.Mesh(bgGeometry, bgMaterial);
  bgSphere.renderOrder = -1;
  scene.add(bgSphere);
  
  // Setup controls if enabled
  if (props.enableRotation || props.enableZoom) {
    setupControls();
  }
}

// Setup orbit controls
async function setupControls() {
  const { OrbitControls } = await import('three/examples/jsm/controls/OrbitControls.js');
  
  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableRotate = props.enableRotation;
  controls.enablePan = false;
  controls.enableZoom = props.enableZoom;
  controls.enableDamping = true;
  controls.dampingFactor = 0.05;
  controls.rotateSpeed = 0.5;
  controls.autoRotate = props.autoRotate;
  controls.autoRotateSpeed = props.autoRotateSpeed;
  controls.minDistance = 1.5;
  controls.maxDistance = 20.0;
  controls.target.set(0, 0, 0);
  controls.update();
}

// Animation loop
function animate() {
  animationId = requestAnimationFrame(animate);
  
  const elapsedTime = clock.getElapsedTime();
  
  // Update uniforms
  if (material) {
    material.uniforms.uTime.value = elapsedTime;
    material.uniforms.uCameraDistance.value = camera.position.length();
  }
  
  // Update controls
  if (controls) {
    controls.update();
  }
  
  // Render
  renderer.render(scene, camera);
}

// Handle resize
function handleResize() {
  if (!camera || !renderer) return;
  
  camera.aspect = props.width / props.height;
  camera.updateProjectionMatrix();
  renderer.setSize(props.width, props.height);
}

// Lifecycle hooks
onMounted(() => {
  initScene();
  animate();
  window.addEventListener('resize', handleResize);
});

onUnmounted(() => {
  if (animationId) {
    cancelAnimationFrame(animationId);
  }
  
  if (controls) {
    controls.dispose();
  }
  
  if (renderer) {
    renderer.dispose();
  }
  
  if (material) {
    material.dispose();
  }
  
  if (sphere && sphere.geometry) {
    sphere.geometry.dispose();
  }
  
  window.removeEventListener('resize', handleResize);
});
</script>

<style scoped>
.waves-sphere-container {
  display: inline-block;
  position: relative;
}

.waves-sphere-container canvas {
  display: block;
  cursor: grab;
}

.waves-sphere-container canvas:active {
  cursor: grabbing;
}
</style>