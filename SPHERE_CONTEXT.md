# Waves Sphere - Project Context & Documentation

## Project Overview
A 3D animated sphere visualization built with Three.js featuring a dynamic wave band system in the lower hemisphere with liquid-like organic movement and eclipse-style color gradients. The sphere displays a smile-shaped wave pattern with customizable movement controls and camera-aware positioning.

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

### 2. Wave Band System (Lower Hemisphere)

#### Overview
The sphere features a dynamic wave band in the lower hemisphere that creates a smile-shaped pattern with liquid-like organic movement. The wave is camera-aware and maintains its position relative to the viewer.

#### Wave Control Parameters (vertexShader.glsl lines 510-570)
```glsl
// Movement Controls
WAVE_VERTICAL_ENABLED = 0.0     // Master vertical movement control
WAVE_HORIZONTAL_ENABLED = 1.0   // Horizontal oscillation on/off
WAVE_HORIZONTAL_SPEED = 0.2     // Speed of left-right oscillation
WAVE_HORIZONTAL_AMPLITUDE = 0.08 // How far wave moves left-right

// Position Controls  
WAVE_ANGULAR_START = 0.215      // Start position (8 o'clock)
WAVE_ANGULAR_END = 0.75        // End position (3.5 o'clock)
WAVE_LAT_START = 0.35          // Starting latitude (left side)
WAVE_LAT_END = 0.45            // Ending latitude (right side)
WAVE_LAT_MIDDLE = 0.65         // Middle dip toward south pole

// Organic Flow Controls
WAVE_ORGANIC_INTENSITY = 0.9    // Overall organic movement
WAVE_FLOW_SPEED_1 = 0.25       // Primary flow speed
WAVE_FLOW_SPEED_2 = 0.15       // Secondary flow speed
WAVE_BREATHING_SPEED = 0.5     // Breathing effect speed
```

#### Wave Behavior
- **Smile Shape**: Creates a parabolic curve that dips toward the south pole
- **Camera-Aware**: Always stays visible from the viewer's perspective
- **Liquid Flow**: Multiple layers of sinusoidal movement for organic feel
- **6 Segments**: 3 dips and 3 rises with individual amplitude controls
- **Gradient Integration**: Special color gradient within the wave band

### 3. Eclipse Color Gradient System - Detailed Hemisphere Documentation

#### Upper Hemisphere (verticalPosition > 0)

The upper hemisphere features a complex radial gradient system that creates a corona-like effect. The colors transition from dark center to bright edge based on the eclipse factor (rim distance).

##### Color Definitions (lines 329-350)
```glsl
vec3 centerBlack = vec3(0.078, 0.098, 0.086);    // #14190F - Center black
vec3 darkBlue = vec3(0.1, 0.0, 0.59);            // #1A0096 - Dark blue
vec3 blue = vec3(0.1843, 0.0, 0.8353);           // #2F00D5 - Blue
vec3 violetPurple = vec3(0.545, 0., 0.875);      // #8B00DF - Violet Purple
vec3 lightpink = vec3(0.98, 0.067, 0.961);       // #FA11F5 - Light Pink
vec3 brightRed = vec3(1., 0.259, 0.361);         // #FF425C - Orange-red
vec3 goldenYellow = vec3(1.0, 0.616, 0.0);       // #FF9D00 - Golden yellow
vec3 brightGold = vec3(1.0, 0.9, 0.4);           // #FFE666 - Bright gold corona
```

##### Gradient Bands with Latitude Adjustments (lines 410-476)
The upper hemisphere gradient adapts based on latitude position:

**Band 0 (0-8%)**: Black to Dark Blue
- Smooth transition from center
- Creates the dark core of the eclipse

**Band 1 (8-25%)**: Dark Blue to Blue
- Intensified blue (multiplied by 1.2)
- Forms the deep blue ring

**Band 2 (25-35/42%)**: Blue to Violet Purple
- End position varies by latitude (purpleEnd)
- At equator: ends at 80%, at poles: ends at 35%

**Band 3 (35/42-42/50%)**: Violet Purple to Light Pink
- Position varies dramatically with latitude
- Near equator: stays violet purple
- At poles: transitions to pink

**Band 4-5 (42/50-70/73%)**: Pink to Red Gradient
- Equator behavior: remains in violet spectrum
- Near equator (lat < 0.2): lighter pink
- Poles: smooth pink to red gradient

**Band 6 (70/73-90/96%)**: Red to Yellow
- Creates natural orange through mixing
- Near equator: lighter transition
- Poles: full red to yellow blend

**Band 7 (90/96-97/99%)**: Yellow Zone
- At equator: fades from violet to black edge
- Other latitudes: solid yellow transitioning to golden

**Band 8 (97/99-100%)**: Golden Corona
- Ultra-thin everywhere
- 1% band at equator, 3% at poles
- Bright gold enhancement at poles

##### North Pole Lighting (lines 481-495)
- Base brightness: 80% everywhere
- Additional 50% at pole
- White highlight mixing for glow effect
- Stronger effect above 0.5 vertical position

#### Lower Hemisphere (verticalPosition < 0)

The lower hemisphere has a more complex structure with base gradients, wave bands, and special rim effects.

##### Base Gradient Structure (lines 588-644)

**Near Equator (0-20% depth)**:
- Black (#14190F) to Deep Purple (#1C0034)
- Smooth transition into lower regions

**Mid Region (20-50% depth)**:
- Deep Purple (#1C0034) to Wine Purple (#511030)
- Creates the main body color

**Lower Region (50-80% depth)**:
- Wine Purple to Dark Violet (#1A0036 * 0.5)
- Darkened for depth

**Near South Pole (80-100% depth)**:
- Dark Violet to Deep Indigo (#230636)
- Darkest region before rim glow

##### Equator Rim Special Effect (lines 615-665)
Only active when depth < 0.3 AND eclipseFactor > 0.6:

**Three-Stage Gradient**:
1. **60-75% rim**: Black → Blue (#2F00D5)
2. **75-88% rim**: Blue → Violet (#8804FF)
3. **88-95% rim**: Full Violet with edge glow (20% brighter)

- Uses smoothstep for seamless transitions
- Maximum 80% blend factor
- Depth-based fading (stronger at equator)

##### Wave Band System (lines 707-997)

**Wave Colors** (lines 353-361):
```glsl
vec3 deepEquatorPurple = vec3(0.098, 0.0, 0.22);  // #190038
vec3 brightMagenta = vec3(0.733, 0.129, 0.612);   // #BB219C
vec3 vibrantPink = vec3(0.863, 0.298, 0.647);     // #DC4CA5
vec3 waveRed = vec3(1.0, 0.102, 0.176);           // #FF1A2D
vec3 deepWine = vec3(0.396, 0.067, 0.216);        // #651137
vec3 equatorViolet = vec3(0.533, 0.016, 1.0);     // #8804FF
```

**Vertical Gradient Within Wave** (lines 810-843):
The wave band has its own internal vertical gradient:

1. **0-8%**: Deep Equator Purple → Bright Magenta
2. **8-20%**: Bright Magenta → Soft Pink (with pulsing)
3. **20-33%**: Soft Pink → Vibrant Pink (with morphing)
4. **33-48%**: Vibrant Pink → Wave Red (with intensity pulsing)
5. **48-68%**: Wave Red → Deep Wine (with flow effects)
6. **68-100%**: Deep Wine → Base gradient color (smooth fade)

**Dynamic Color Movement**:
- Color flow speed: 0.8
- Pulse speed: 2.0
- Breathing effects create organic variation
- Colors morph between adjacent values

**Segment-Specific Colors** (lines 845-916):
- Right side dips: Use lighter purple (#892DB4)
- Left side near south: Use wave red (#FF1A2D)
- Final 15% horizontal fade: Deep Purple → Wine Purple

##### South Pole Rim Glow (lines 920-962)
Active when verticalPosition < -0.11 AND eclipseFactor > 0.75:

**Color Progression**:
1. **0-40%**: Deep Dark (#0A0021) → Bright Red-Orange (#F84527)
2. **40-70%**: Bright Red-Orange → Golden Yellow (#FF9D00)
3. **70-100%**: Golden Yellow → Deep Golden (1.0, 0.7, 0.1)

- Thickness varies by latitude (thicker at pole)
- Smooth transitions using smoothstep
- Intensity modulated by vertical position

##### Hemisphere Blending (lines 969-994)
- Upper hemisphere dominates above 0.15
- Lower hemisphere dominates below -0.15
- Blending zone: -0.15 to 0.15
- Brightening applied to prevent black bleeding
- Minimum brightness ensured in blend zone

### 4. Organic Membrane System (Upper Hemisphere Only)

#### Implementation (lines 160-276)
The organic membrane deformation only affects the front-facing upper hemisphere dots.

##### Control Parameters (lines 169-188)
```glsl
ENABLE_ORGANIC_MOVEMENT = 1.0    // Master toggle
MEMBRANE_SPEED = 0.3             // Animation speed
BULGE_AMPLITUDE = 0.2            // Maximum outward movement
GROOVE_AMPLITUDE = -0.05         // Maximum inward movement (shallow)
NOISE_SCALE = 2.5                // Size of primary deformations
SECONDARY_SCALE = 2.0            // Size of detail ripples
PULSE_INTENSITY = 0.3            // Bulge pulsing strength
BREATHE_INTENSITY = 0.3          // Groove breathing strength
```

##### Front-Facing Detection (lines 197-211)
- Calculates dot product with camera direction
- Smooth transition using smoothstep(-0.3, 0.3, facingFactor)
- Returns 0 deformation for back-facing points

##### Noise Layers (lines 213-227)
- Primary noise: Large smooth bulges
- Secondary noise: Smaller ripples (30% strength)
- Combined with configurable weights
- Multiple time offsets for complex motion

##### Deformation Behavior
- Bulges: Create outward movement with pulsing
- Grooves: Create inward movement with breathing
- Per-vertex variation for organic feel
- Clamped to -0.10 to +0.25 to maintain shape

### 5. Wave Band Implementation Details

#### Camera-Facing Calculation (lines 575-588)
```glsl
// Calculate angle relative to camera
vec3 cameraViewDir = normalize(cameraPosition);
vec3 toPoint = normalize(originalWorldPos);
vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), cameraViewDir));
vec3 up = cross(cameraViewDir, right);
float angle = atan(dot(toPoint, right), dot(toPoint, cameraViewDir));
```

#### Wave Progress Calculation (lines 631-635)
- Progress goes from 0.0 (left) to 1.0 (right)
- Flipped direction for right-side visibility
- Used for smile curve interpolation

#### Smile Curve Generation (lines 740-751)
```glsl
// Parabolic smile curve
float smileCurve = pow(4.0 * waveProgress * (1.0 - waveProgress), 1.2);
// Add asymmetry for natural look
float asymmetry = sin(waveProgress * PI) * 0.1;
smileCurve = smileCurve * (1.0 + asymmetry);
// Interpolate between start/end and middle latitudes
float baseLat = mix(WAVE_LAT_START, WAVE_LAT_MIDDLE, smileCurve);
```

#### Liquid Flow Layers (lines 754-757)
- Primary flow: sin(uTime * 0.12) * 0.04
- Secondary wave: cos(uTime * 0.18) * 0.025
- Ripple effect: sin(uTime * 0.25) * 0.015
- Combined for organic movement

#### 6-Segment Wave Structure (lines 771-806)
1. **Segment 1 (DIP)**: 17.5% width, animated amplitude
2. **Segment 2 (RISE)**: 40% width, flow animation
3. **Segment 3 (DIP)**: 5% width, stronger animation
4. **Segment 4 (RISE)**: 50% width, wave motion
5. **Segment 5 (DIP)**: 35% width, subtle movement
6. **Segment 6 (RISE)**: 80% width, fade animation

### 6. Rendering System

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
1. **Wave Band System**: Smile-shaped wave in lower hemisphere with liquid flow
2. **Camera-Aware Positioning**: Wave stays visible from viewer perspective
3. **Eclipse Gradient**: Separate upper/lower hemisphere color systems
4. **Equator Rim Effect**: Blue to violet gradient at equator rim
5. **6-Segment Wave Animation**: Individual control for dips and rises
6. **60FPS Optimized**: All animations tuned for smooth performance
7. **Organic Membrane**: Front-facing deformation in upper hemisphere
8. **Dynamic Dot Sizing**: Automatic scaling based on camera distance
9. **Vue.js Ready**: Self-contained component package

## Configuration Quick Reference

### Wave Controls
| Parameter | Default | Line | Effect |
|-----------|---------|------|--------|
| WAVE_VERTICAL_ENABLED | 0.0 | 512 | Master vertical movement |
| WAVE_HORIZONTAL_ENABLED | 1.0 | 518 | Horizontal oscillation |
| WAVE_HORIZONTAL_SPEED | 0.2 | 519 | Left-right speed |
| WAVE_ANGULAR_START | 0.215 | 545 | Start position (8 o'clock) |
| WAVE_ANGULAR_END | 0.75 | 546 | End position (3.5 o'clock) |
| WAVE_LAT_START | 0.35 | 550 | Left side latitude |
| WAVE_LAT_END | 0.45 | 551 | Right side latitude |
| WAVE_LAT_MIDDLE | 0.65 | 552 | Middle dip depth |
| WAVE_ORGANIC_INTENSITY | 0.9 | 528 | Organic movement amount |
| WAVE_BREATHING_SPEED | 0.5 | 534 | Breathing effect speed |

### Membrane Controls
| Parameter | Default | Line | Effect |
|-----------|---------|------|--------|
| ENABLE_ORGANIC_MOVEMENT | 1.0 | 169 | Toggle membrane system |
| MEMBRANE_SPEED | 0.3 | 171 | Animation speed |
| BULGE_AMPLITUDE | 0.2 | 172 | Maximum bulge height |
| GROOVE_AMPLITUDE | -0.05 | 173 | Maximum groove depth |
| NOISE_SCALE | 2.5 | 176 | Deformation size |

---
*Last Updated: December 2024*
*Three.js Version: Latest*
*Vue Version: 3.x*

## Recent Changes
- Implemented wave band system in lower hemisphere with smile-shaped curve
- Added camera-aware positioning for wave to stay visible
- Created 6-segment wave with individual dip/rise controls
- Added equator rim effect with blue-violet gradient
- Implemented liquid-like flow with multiple animation layers
- Optimized all movements for smooth 60FPS performance
- Added horizontal oscillation instead of full rotation
- Flipped wave for right-side primary visibility
- Updated documentation with complete implementation details

## Critical Implementation Notes

### Wave Visibility
- Wave only appears when eclipseFactor < 0.6 (line 707)
- Camera facing weight must be > 0.1 (line 638)
- Limited to lower hemisphere (verticalPosition < 0)
- Angular range: 0.215 to 0.75 (normalized angle)

### Color Blending
- Wave colors blend with base gradient using rimFade (lines 961-970)
- Smooth transitions using smoothstep throughout
- Dynamic color animation with time-based morphing
- Segment-specific colors for left/right sides

### Performance Considerations
- All sin/cos speeds reduced by 5-10x for 60FPS
- Animation amplitudes reduced by 50%
- Multiple optimization layers for smooth rendering
- Camera calculations optimized for minimal overhead