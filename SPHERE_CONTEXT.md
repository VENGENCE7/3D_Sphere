# Waves Sphere - Project Context & Documentation

## Project Overview
A 3D animated sphere visualization built with Three.js featuring dual-wave collision animations and dynamic eclipse-style color gradients. The sphere displays two expanding waves that originate from different points, grow in amplitude as they expand, and create dramatic collision effects.

## Architecture

### Core Files Structure
```
src/
├── main.js                    # Application entry point
├── scene/
│   └── SceneManager.js        # Three.js scene, camera, controls setup
├── geometry/
│   └── EclipseSphere.js       # Sphere geometry and material management
└── shaders/
    ├── vertexShader.glsl      # Vertex shader with wave system & colors
    └── fragmentShader.glsl    # Fragment shader for dot rendering
```

### Vue Component Package
```
vue/
├── WavesSphere.vue           # Main Vue 3 component
├── SceneManager.js           # Scene management for Vue
├── config.js                 # Configuration and zoom presets
├── ExampleUsage.vue          # Simple usage example
├── vertexShader.glsl         # Wave animation shader
└── fragmentShader.glsl       # Fragment shader
```

## Technical Implementation

### 1. Sphere Construction
- **Geometry**: Hexagonal packing pattern with ~240 latitude lines
- **Points**: ~28,000 vertices rendered as dots
- **Radius**: 1.5 units
- **Background**: Black sphere at 0.95x radius prevents see-through gaps

### 2. Dual-Wave Collision System

#### Wave Origins and Behavior
- **Wave 1 Origin**: vec3(0.707, 0.707, 0.5)
- **Wave 2 Origin**: vec3(-0.707, -0.707, 0.65)
- **Expansion**: Waves expand outward at configurable speed
- **Amplitude Growth**: Waves grow from base amplitude to maximum as they approach collision
- **Collision Point**: Calculated as midpoint between origins
- **Cycle Duration**: 4 seconds for complete wave cycle

#### Wave Parameters (vertexShader.glsl)
```glsl
WAVE_FREQUENCY = 6.0      // Ripple frequency within waves
WAVE_SPEED = 0.25         // Wave expansion speed
WAVE_THICKNESS = 0.5      // Ring thickness
WAVE_AMPLITUDE = 0.8      // Base wave height
WAVE_MAX_AMPLITUDE = 2.2  // Maximum height at clash point
WAVE_FORM = 1.0          // Wave shape control
```

#### Wave Physics
- Waves start at their origins and expand outward
- Amplitude increases quadratically as waves approach collision: 
  ```glsl
  growthFactor = baseAmplitude + (maxAmplitude - baseAmplitude) * pow(progressToClash, 2.0)
  ```
- Waves fade out near collision point for smooth transition
- Combined wave amplitude is boosted by 1.5x when both waves overlap

### 3. Eclipse Color Gradient System

#### Color Calculation
The sphere uses a rim-based eclipse effect that creates a corona-like appearance:

| Eclipse Factor | Color Transition | Hex Code |
|----------------|------------------|----------|
| 0.00-0.25 | Center Black → Deep Violet | #141916 → #1F004D |
| 0.20-0.35 | → Purple | #5900B3 |
| 0.50-0.65 | → Magenta | #9900CC |
| 0.60-0.72 | → Pink | #D9266B |
| 0.70-0.80 | → Red | #FF1A33 |
| 0.80-0.90 | → Orange | #FF6600 |
| 0.88-0.95 | → Golden Yellow | #FFCC33 |
| 0.95-1.00 | → Bright Gold | #FFE566 |

The eclipse factor is calculated based on the dot product between the surface normal and view direction, creating the characteristic rim lighting effect.

### 4. Rendering System

#### Point Sizing Logic
```glsl
baseSize = 6.0                     // Base dot size
screenScale = 6.0                   // Screen scaling factor
zoomFactor = sqrt(uCameraDistance / 3.5)
perspectiveScale = screenScale * zoomFactor
randomSize = 0.95 + aRandom * 0.1  // 5-15% variation

gl_PointSize = clamp(baseSize * perspectiveScale * randomSize, 1.0, 12.0)
```

#### Camera & Controls
- **Perspective**: 75° FOV
- **Default Distance**: 3.5 units
- **Zoom Range**: 2.0 (closest) to 15.0 (farthest)
- **Auto-rotation**: Disabled by default (can be enabled)
- **Controls**: Mouse/touch rotation with smooth damping (0.1)

### 5. Vue Component Features

#### Zoom Control System
The Vue component provides a simple zoom interface:
- **Single Prop**: `zoom-level` (0 to 1)
  - 0 = far away (camera at 15.0 units)
  - 1 = close up (camera at 2.0 units)
- **Automatic Scaling**: Point sizes adjust automatically based on zoom
- **Smooth Transitions**: Built-in easing for zoom changes

#### Configuration
```javascript
defaultConfig = {
  radius: 1.5,
  pointBaseSize: 6.0,
  defaultCameraDistance: 3.5,
  minZoom: 2.0,    // Closest zoom
  maxZoom: 15.0,   // Farthest zoom
  backgroundColor: 0x000000,
  sphereBackgroundColor: 0x141916
}
```

## Usage Instructions

### Basic HTML Integration
```html
<!DOCTYPE html>
<html>
<head>
    <script type="module" src="./src/main.js"></script>
</head>
<body>
    <!-- Sphere renders automatically -->
</body>
</html>
```

### Vue.js Integration
```vue
<template>
  <WavesSphere 
    :zoom-level="0.5"
    width="100%"
    height="100vh"
  />
</template>

<script setup>
import WavesSphere from './vue/WavesSphere.vue';
import { ref } from 'vue';

const zoomLevel = ref(0.5); // Control zoom: 0 = far, 1 = close
</script>
```

### Programmatic Zoom Control
```javascript
// Example: Animate zoom on scroll
const handleScroll = (event) => {
  const delta = event.deltaY * -0.001;
  zoomLevel.value = Math.max(0, Math.min(1, zoomLevel.value + delta));
}

// Example: Zoom animation sequence
setTimeout(() => {
  zoomLevel.value = 0.2;  // Start far
  setTimeout(() => {
    zoomLevel.value = 0.6;  // Zoom in
  }, 1000);
  setTimeout(() => {
    zoomLevel.value = 0.5;  // Settle at normal
  }, 2000);
}, 500);
```

## Performance Characteristics
- **Frame Rate**: 60 FPS with ~28,000 animated points
- **Memory**: ~50MB for geometry and textures
- **GPU**: Requires WebGL 2.0 support
- **Optimization**: Single-pass rendering, efficient shader calculations

## Browser Requirements
- WebGL 2.0 support
- Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
- GPU acceleration recommended

## Development Commands
```bash
npm install          # Install dependencies
npm run dev         # Start development server
npm run build       # Build for production
npm run preview     # Preview production build
```

## Key Features Summary
1. **Dual-Wave Animation**: Two expanding waves that collide and create interference patterns
2. **Eclipse Gradient**: Corona-style color system with rim lighting
3. **Zoom Control**: Simple 0-1 prop for Vue component
4. **Interactive Controls**: Mouse/touch rotation with smooth damping
5. **Performance Optimized**: Efficient shader-based animation
6. **Vue.js Ready**: Self-contained component package

## Configuration Quick Reference
| Parameter | Default | Range | Effect |
|-----------|---------|-------|--------|
| zoom-level (Vue) | 0.5 | 0-1 | Camera distance control |
| WAVE_SPEED | 0.25 | 0.1-1.0 | Wave expansion speed |
| WAVE_AMPLITUDE | 0.8 | 0.1-2.0 | Base wave height |
| WAVE_MAX_AMPLITUDE | 2.2 | 0.5-5.0 | Peak amplitude at collision |
| WAVE_FREQUENCY | 6.0 | 1.0-20.0 | Ripples within waves |
| pointBaseSize | 6.0 | 1.0-20.0 | Base dot size |

---
*Last Updated: September 2025*
*Three.js Version: Latest*
*Vue Version: 3.x*