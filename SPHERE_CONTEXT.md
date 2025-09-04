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

### 2. Organic Membrane Deformation System

#### Overview
The sphere now uses an organic membrane deformation system powered by Simplex noise for natural, living surface movement instead of dual-wave collisions.

#### Deformation Parameters (vertexShader.glsl)
```glsl
// Master Controls
ENABLE_ORGANIC_MOVEMENT = 1.0   // Toggle system on/off
MEMBRANE_SPEED = 0.25           // Overall animation speed
BULGE_AMPLITUDE = 0.15          // Maximum bulge height (outward)
GROOVE_AMPLITUDE = -0.10        // Maximum groove depth (inward)

// Scale Controls
NOISE_SCALE = 2.5               // Size of primary deformations
SECONDARY_SCALE = 2.0           // Size of detail ripples

// Motion Characteristics
PULSE_INTENSITY = 0.1           // Bulge pulsing strength
BREATHE_INTENSITY = 0.1         // Groove breathing strength
VERTEX_VARIATION = 0.3          // Per-vertex randomization
```

#### Deformation Behavior
- **Bulges**: Smooth outward movements creating raised areas
- **Grooves**: Smooth inward movements creating valleys
- **Multi-layer noise**: Primary noise for large features, secondary for detail
- **Temporal variation**: Continuous flow with multiple time-based offsets
- **Displacement limit**: Clamped to ±0.25 units to maintain sphere shape

### 3. Eclipse Color Gradient System

#### Color Calculation
The sphere uses a rim-based eclipse effect that creates a corona-like appearance. Colors vary based on hemisphere and latitude:

##### Upper Hemisphere Colors (Fixed Gradient Transitions)
| Eclipse Factor | Color Transition | Hex Code | Notes |
|----------------|------------------|----------|-------|
| 0.00-0.25 | Center Black → Deep Violet | #141916 → #1F004D | Core |
| 0.25-0.35 | Deep Violet → Dark Blue | #1F004D → #1A0096 | |
| 0.35-0.40 | Dark Blue → Blue | #1A0096 → #2F00D5 | |
| 0.40-0.58 | Blue → Magenta | #2F00D5 → #9700DC | Smooth blend |
| 0.58-0.68 | Magenta → Neon Purple | #9700DC → #BF47FF | |
| 0.68-0.70 | Neon Purple → Light Pink | #BF47FF → #FF35B1 | Short transition |
| 0.70-0.72 | Light Pink → Pink | #FF35B1 → #D92673 | |
| 0.72-0.80 | Pink → Red | #D92673 → #FF1A33 | |
| 0.80-0.92 | Red → Hot Pink | #FF1A33 → #FF466C | Whiter near equator |
| 0.92-0.95 | → Golden Yellow | #FFCC33 | Thicker at pole |
| 0.95-1.00 | → Bright Gold | #FFE666 | Corona effect |

##### Lower Hemisphere Colors
| Eclipse Factor | Color Transition | Hex Code | Notes |
|----------------|------------------|----------|-------|
| 0.00-0.30 | Center Black → Deep Violet | #141916 → #1F004D | |
| 0.30-0.50 | → Bright Red | #FF1B17 | Special band region |
| 0.50-0.58 | → Deep Purple | #1C0034 | Limited to -0.174 to -0.425 latitude |
| 0.58-0.68 | → Wine Purple | #511030 | |
| 0.68-0.78 | → Red | #FF1A33 | |
| 0.78-0.98 | → Golden Yellow | #FFCC33 | |

#### Special Effects
- **Corona at North Pole**: Yellow corona is thickest at the north pole and diminishes toward the equator
- **Equator Transition**: Hot pink becomes whiter near the equator with 50% transparent corona glow
- **Gradient Shifting**: Bulges shift colors toward lower spectrum (darker blues/violets)
- **Deformation Darkening**: Both bulges and grooves receive darker colors for depth perception

The eclipse factor is calculated based on the dot product between the surface normal and view direction, creating the characteristic rim lighting effect.

### 4. Rendering System

#### Point Sizing Logic
```glsl
baseSize = 4.8                     // Base dot size (adjustable)
randomSize = 0.95 + aRandom * 0.1  // 5-15% variation

// Dynamic zoom scaling
if (uCameraDistance <= 2.0) {
    perspectiveScale = 2.0;        // 200% size at max zoom
} else if (uCameraDistance <= 3.5) {
    // Smooth interpolation for close zoom
    t = (3.5 - uCameraDistance) / 1.5;
    perspectiveScale = 1.0 + (1.0 * t);
} else {
    // Scale down for distant view
    perspectiveScale = sqrt(3.5 / uCameraDistance) * 0.8;
}

gl_PointSize = clamp(baseSize * perspectiveScale * randomSize, 0.5, 20.0)
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
1. **Organic Membrane Animation**: Simplex noise-based deformation for living surface movement
2. **Eclipse Gradient**: Corona-style color system with rim lighting and hemisphere variations
3. **Gradient Transitions**: Fixed smooth transitions without gaps or overlaps
4. **Zoom Control**: Simple 0-1 prop for Vue component with proper dot scaling
5. **Interactive Controls**: Mouse/touch rotation with smooth damping
6. **Performance Optimized**: Efficient shader-based animation
7. **Vue.js Ready**: Self-contained component package

## Configuration Quick Reference
| Parameter | Default | Range | Effect |
|-----------|---------|-------|--------|
| zoom-level (Vue) | 0.5 | 0-1 | Camera distance control |
| MEMBRANE_SPEED | 0.25 | 0.1-1.0 | Organic animation speed |
| BULGE_AMPLITUDE | 0.15 | 0.05-0.3 | Maximum bulge height |
| GROOVE_AMPLITUDE | -0.10 | -0.2-0 | Maximum groove depth |
| NOISE_SCALE | 2.5 | 1.0-5.0 | Size of deformations |
| PULSE_INTENSITY | 0.1 | 0-0.3 | Bulge pulsing strength |
| pointBaseSize | 4.8 | 1.0-20.0 | Base dot size |

---
*Last Updated: December 2024*
*Three.js Version: Latest*
*Vue Version: 3.x*

## Recent Changes
- Fixed gradient transitions to eliminate gaps and overlaps in color blending
- Replaced dual-wave collision system with organic membrane deformation using Simplex noise
- Updated color gradient system with proper smoothstep ranges
- Fixed dot scaling to properly respond to baseSize changes
- Added gradient shifting for bulges toward lower spectrum colors
- Improved documentation with complete color tables for both hemispheres