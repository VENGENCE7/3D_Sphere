# Eclipse Effect 3D Sphere - Three.js Implementation

## Project Overview

A sophisticated 3D animated sphere visualization featuring liquid-like wave animations and a vertical gradient color system. Built with Three.js and WebGL shaders, this project demonstrates advanced real-time graphics techniques including procedural wave generation, vertical gradient mapping, and hexagonal dot packing patterns. The visualization consists of two spheres: an outer animated dot sphere and an inner solid black sphere for background fill.

## Visual Features

### 🌊 Liquid Wave System
- **Multi-source wave generation**: 5 distinct wave origins creating interference patterns
- **Controlled displacement**: Maximum 0.15 units to maintain spherical shape
- **Smooth animation**: Time-based animation with varying speeds per wave source
- **Folding effects**: Waves create natural folding and bending surface patterns
- **Organic motion**: Mathematical wave combinations producing liquid-like behavior
- **Surface ripples**: Secondary high-frequency ripples for detailed texture

### 🌈 Vertical Gradient System
The sphere uses a vertical gradient based on Y-position, creating distinct color zones from top to bottom:

**Upper Hemisphere (Top to Equator):**
- **90-100%**: Yellow (#FFFF33) at the top pole
- **80-90%**: Orange to Amber transition
- **65-80%**: Pink (#FF1A80) to Orange
- **50-65%**: Hot Pink to Pink bands
- **35-50%**: Magenta (#8000FF) to Hot Pink
- **20-35%**: Purple to Magenta
- **10-20%**: Deep Purple transition
- **0-10%**: Near black/deep purple at equator

**Lower Hemisphere (Equator to Bottom):**
- **Front Face**: 70% dark colors (deep purple), quick transition to yellow in bottom 10%
- **Back Face**: Gradual transition similar to upper hemisphere
- **Smooth Blending**: Uses `frontness` factor to blend between front/back at meridian

**Key Implementation Details:**
- Vertical position-based gradient (not viewing angle)
- Different distributions for front vs back in lower hemisphere
- Minimum gradient position of 0.05 to avoid pure black
- Smooth interpolation at meridian to prevent black strips

### 🔦 Lighting System (Simplified)
- **No shadows**: All shadow calculations removed for uniform brightness
- **No sun effects**: Sun illumination removed to prevent white/bright spots
- **Uniform lighting**: `vSunLight = 1.0` everywhere
- **No brightness boost**: Original colors maintained without multiplication

### 🎯 Dynamic Point Sizing
The sphere implements camera-distance-based point sizing to maintain optimal visual density:

**Point Size Formula:**
```glsl
float screenScale = 3.0; // Optimized to prevent overlap
float perspectiveScale = screenScale / uCameraDistance;
gl_PointSize = baseSize * perspectiveScale;
gl_PointSize = clamp(gl_PointSize, 1.5, 12.0);
```

**Key Features:**
- **Camera-responsive**: Dots get smaller when zoomed out, larger when zoomed in
- **Overlap prevention**: Reduced screenScale (3.0) prevents dot overlap at distance
- **Size clamping**: Range of 1.5-12.0 pixels ensures visibility without overlap
- **Real-time updates**: Camera distance uniform updated every frame

## Technical Implementation

### Shader Architecture

#### Vertex Shader Features
```glsl
// Multiple wave sources with different origins and directions
float createFoldingWaves(vec3 p) {
    float time = uTime;
    
    // Wave 1: Originating from top-left, moving diagonally
    vec3 origin1 = vec3(-0.8, 0.8, 0.5);
    float dist1 = length(p - origin1);
    float wave1 = sin(dist1 * 8.0 - time * 2.0) * exp(-dist1 * 0.8) * 0.12;
    
    // Additional waves from different origins...
    // Combined with clamping to maintain shape
    return clamp(totalWave, -0.15, 0.15);
}
```

**Key Vertex Shader Techniques:**
- **Multi-source wave generation**: 5 distinct wave origins with exponential decay
- **Procedural displacement**: Mathematical functions create liquid-like motion
- **Normal recalculation**: Gradient-based normal computation for proper lighting
- **World-space transformation**: Fixed eclipse positioning independent of rotation
- **Dynamic point sizing**: Doubled base size (3.0), max 14.0, with depth-based scaling
- **Shadow occlusion sampling**: Checks neighboring heights for shadow casting

#### Fragment Shader Features
```glsl
// Enhanced glow and corona effects
if (vIntensity > 0.7) {
    float glow = 1.0 - dist * 1.5;
    dotColor += vColor * glow * 0.4;
    
    // Corona effect for extreme highlights
    if (vIntensity > 0.9) {
        float corona = smoothstep(0.5, 0.0, dist);
        dotColor += vec3(1.0, 0.9, 0.7) * corona * 0.2;
    }
}
```

**Fragment Processing:**
- **Point sprite rendering**: Circular dots with smooth antialiasing
- **Intensity-based glow**: Bright areas exhibit radiant halos
- **Corona effects**: Extreme highlights get additional white-gold glow
- **Shadow darkening**: Valley areas rendered progressively darker

### Geometry Generation

**Hexagonal Packing Pattern (Outer Sphere):**
- **180 latitude lines** with hexagonal offset pattern
- **Variable longitude points**: More at equator, fewer at poles
- **Hexagonal arrangement**: Every other row offset by half spacing
- **No longitude overlap**: Clean spherical closure
- **Buffer attributes**: Position, initial position, and random values

**Inner Solid Sphere:**
- **Simple black sphere**: No waves or animations
- **Radius**: 0.91x of outer sphere (user adjusted)
- **30x30 segments**: Basic resolution for smooth appearance
- **MeshBasicMaterial**: Pure black (0x000000) with no shaders
- **Purpose**: Fills gaps between dots to prevent transparency

### Lighting System

**World-Space Eclipse Lighting:**
```javascript
// Fixed world-space light direction
vec3 sunPosition = vec3(5.0, 6.0, 7.0);
vec3 sunDir = normalize(sunPosition - worldPosition);

// Shadow occlusion calculation
float shadowOcclusion = calculateShadowOcclusion(pos, sunDir, totalDisplacement);
shadowOcclusion = max(shadowOcclusion, 0.3); // Never completely dark
```

**Advanced Lighting Features:**
- **Fixed light source**: World-space lighting creates consistent eclipse effect
- **Shadow occlusion**: Neighboring wave heights affect local illumination
- **Rim lighting**: Edge definition through view-angle dependent highlighting
- **Valley shadows**: Deep displacement areas receive reduced illumination

## Color Theory Implementation

### Eclipse Gradient Algorithm
```glsl
// Calculate rim-based eclipse effect
vec3 worldViewDir = normalize(cameraPosition - worldPosition);
float rimFactor = 1.0 - abs(dot(worldNorm, worldViewDir)); // 0 at center, 1 at edges
float eclipseRim = pow(rimFactor, 1.5); // Sharper edge transition

// Fixed world-space orientation
float worldOrientation = dot(worldNorm, normalize(vec3(1.0, 0.5, 0.0)));
float eclipsePosition = (worldOrientation + 1.0) * 0.5;

// Combine rim and orientation
float eclipseFactor = eclipseRim * 0.7 + eclipsePosition * 0.3;
```

**Key Color Principles:**
- **Position-locked**: Colors tied to world coordinates, not object rotation
- **Limited yellow**: Restricted to extreme edge highlights (80-100% eclipse factor)
- **Dynamic response**: Colors respond to wave displacement through shadow modulation
- **Gradient smoothing**: Mathematical interpolation between color zones

## Interactive Controls

### Mouse/Touch Integration
- **Drag to rotate**: Smooth sphere rotation with momentum damping
- **Scroll to zoom**: Camera distance control (2-15 units extended range)
- **Touch support**: Mobile-friendly single-touch rotation
- **Smooth interpolation**: 0.1 damping factor for fluid motion
- **Auto-rotation**: Subtle continuous rotation (0.0008 rad/frame) when not interacting
- **Movement detection**: Responsive rotation controls

### Control Mathematics
```javascript
// Smooth rotation damping
currentRotationX += (targetRotationX - currentRotationX) * 0.1;
currentRotationY += (targetRotationY - currentRotationY) * 0.1;

// Auto-rotation when not interacting
if (!this.isMouseDown) {
    this.targetRotationY += 0.0008;
}

// Constraint application
targetRotationX = Math.max(-Math.PI / 2, Math.min(Math.PI / 2, targetRotationX));

// Extended zoom range
camera.position.z = Math.max(2, Math.min(15, camera.position.z));
```

## Performance Optimization

### Rendering Efficiency
- **Single draw call**: All dots rendered as Points geometry
- **Additive blending**: GPU-accelerated color blending for glow effects
- **Optimized shaders**: Efficient mathematical operations in GLSL
- **Level-of-detail**: Distance-based point sizing for performance scaling

### Memory Management
- **Buffer geometry**: Efficient vertex data storage
- **Attribute reuse**: Shared vertex attributes across rendering passes
- **Texture-free**: Pure mathematical color generation (no texture sampling)

## Mathematical Foundation

### Wave Function Composition
The wave system combines multiple mathematical functions:

1. **Wave Source 1**: Origin (-0.8, 0.8, 0.5), frequency 8.0, speed 2.0, amplitude 0.12
2. **Wave Source 2**: Origin (0.9, -0.7, -0.4), frequency 6.0, speed 1.5, amplitude 0.10
3. **Wave Source 3**: Origin (0.2, 0.1, 1.2), frequency 10.0, speed 2.5, amplitude 0.08
4. **Wave Source 4**: Origin (-1.0, 0.3, -0.8), frequency 7.0, speed 1.8, amplitude 0.09
5. **Wave Source 5**: Origin (0.6, -0.9, 0.2), frequency 9.0, speed 2.2, amplitude 0.07
6. **Base Undulation**: `sin(theta * 2.0 + time * 0.5) * cos(phi * 1.5 + time * 0.3) * 0.03`
7. **Secondary Ripples**: Fast-moving surface ripples with frequencies 8.0-10.0
8. **Total Displacement**: Clamped between -0.35 and 0.35 to maintain sphere shape

### Normal Vector Calculation
```glsl
// Gradient-based normal computation
vec3 perturbedNormal = normalize(originalNormal + 
    tangent1 * (dispT1 - shapeDisplacement) * 30.0 + 
    tangent2 * (dispT2 - shapeDisplacement) * 30.0);
```

### Eclipse Position Mapping
```glsl
// Calculate rim-based eclipse effect
vec3 worldViewDir = normalize(cameraPosition - worldPosition);
float rimFactor = 1.0 - abs(dot(worldNorm, worldViewDir)); // 0 at center, 1 at edges
float eclipseRim = pow(rimFactor, 1.5); // Sharper edge transition

// Fixed world-space orientation
float worldOrientation = dot(worldNorm, normalize(vec3(1.0, 0.5, 0.0)));
float eclipsePosition = (worldOrientation + 1.0) * 0.5;

// Combine rim and orientation
float eclipseFactor = eclipseRim * 0.7 + eclipsePosition * 0.3;
```

## Build & Development

### Project Structure
```
waves-sphere/
├── index.html          # Main HTML entry point
├── src/
│   ├── main.js         # Application entry point
│   ├── scene/
│   │   └── SceneManager.js     # Three.js scene management
│   ├── geometry/
│   │   └── EclipseSphere.js    # Sphere geometry and material
│   ├── controls/
│   │   └── InteractionControls.js  # Mouse/touch controls
│   └── shaders/
│       ├── vertexShader.glsl   # Vertex displacement and waves
│       └── fragmentShader.glsl # Point rendering and colors
├── package.json        # Vite build configuration
├── CLAUDE.md          # Project documentation
└── dist/              # Production build output
```

### Build Process
- **Vite bundling**: Modern ES module bundling
- **No TypeScript**: Pure JavaScript/HTML for simplicity
- **CDN Three.js**: External Three.js library loading
- **Single file output**: Self-contained HTML with embedded shaders

### Development Commands
```bash
pnpm install          # Install dependencies
pnpm run dev          # Development server (http://localhost:5173)
pnpm run build        # Production build
pnpm run preview      # Preview production build
```

## Advanced Features Implemented

### 1. **Fixed World-Space Eclipse**
- Colors remain stationary while sphere rotates
- Golden yellow corona appears only at visible rim edges
- Eclipse shadow pattern maintains consistent directionality
- Deep violet used instead of pure black for shadow regions

### 2. **Liquid Wave Physics**
- Multiple wave sources creating complex interference patterns
- Exponential decay from wave origins for natural motion
- Controlled displacement range (-0.35 to 0.35) maintaining spherical shape
- Secondary ripples and surface texture for detailed appearance

### 3. **Dynamic Shadow Casting**
- Wave peaks cast shadows on valleys
- Height-based occlusion calculations with 0.5 unit sampling
- Progressive shadow darkening with minimum 0.3 occlusion (never completely dark)
- Front-positioned sun at vec3(5.0, 6.0, 7.0)

### 4. **Hexagonal Dot Packing**
- Honeycomb arrangement with row offsets
- Variable density based on latitude (more at equator)
- Dual sphere structure: dots + solid black background
- No z-fighting through 0.99x radius offset

## Technical Achievements

### Shader Innovation
- **Complex wave mathematics**: Multi-layered procedural generation
- **World-space color mapping**: Position-independent gradient system
- **Real-time shadow computation**: Height-based occlusion in vertex shader
- **Dynamic normal calculation**: Proper lighting for displaced geometry

### Visual Excellence  
- **Eclipse authenticity**: Rim-based corona effect with world-space color mapping
- **Liquid motion**: Complex wave interference creating organic surface animation
- **Sphere integrity**: Maintains shape through clamped displacement values
- **Color accuracy**: Deep violet shadows (#260059) → Purple (#8000FF) → Pink (#FF1A80) → Orange (#FF5500) → Golden yellow corona
- **Smooth animation**: 60fps performance with hexagonal dot pattern
- **Full sphere coverage**: Both front and back surfaces properly colored and lit

### User Experience
- **Intuitive controls**: Natural mouse/touch interaction
- **Responsive design**: Adapts to all screen sizes
- **Immediate feedback**: Real-time response to user input
- **Visual impact**: Stunning eclipse effect with cosmic energy aesthetics

## Future Enhancement Possibilities

### Advanced Features
- **Particle systems**: Add cosmic dust or energy particles
- **Sound integration**: Audio-reactive wave modulation
- **Multiple eclipse sources**: Complex multi-directional lighting
- **Texture layering**: Additional surface detail through normal mapping

### Performance Optimizations
- **Instanced rendering**: Support for multiple spheres
- **Level-of-detail**: Adaptive quality based on distance
- **Occlusion culling**: Skip rendering of hidden portions
- **Temporal upsampling**: Advanced frame interpolation

---

## Technical Summary

This Three.js eclipse sphere represents a sophisticated implementation of:
- **Advanced WebGL shader programming**
- **Complex mathematical wave generation** 
- **Real-time shadow casting and occlusion**
- **World-space color mapping systems**
- **High-performance 3D graphics techniques**

The project successfully combines artistic vision with technical excellence, creating a visually stunning and mathematically complex 3D visualization that showcases the power of modern web graphics capabilities.

**Key Technical Features:**
- **Hexagonal Packing**: 180 latitude lines with honeycomb offset pattern
- **Multi-Source Wave System**: 5 wave origins with different frequencies and speeds
- **Dual Sphere Structure**: Point cloud + solid black background sphere
- **Vertical Gradient System**: Y-position based color mapping with front/back variation
- **Optimized Rendering**: Single draw call with point sprites, normal blending
- **Dynamic Point Sizing**: Camera-distance responsive dot scaling
- **Extended Interaction**: Zoom range 2-15 units, auto-rotation when idle

**Total Implementation**: Modular ES6 architecture with sophisticated shader code + interactive controls + optimized rendering pipeline = Professional-grade interactive WebGL visualization.

## Recent Changes & Current State

### Latest Updates (Most Recent):
1. **Dynamic Camera-Based Point Sizing** - Dots scale based on camera distance
   - `screenScale = 3.0` optimized to prevent overlap when zoomed out
   - Size range clamped to 1.5-12.0 pixels
   - Real-time camera distance uniform updates
   - Prevents dot overlap at far distances while maintaining visibility
   
2. **Fixed Color Blending** - Resolved white appearance when zoomed out
   - Changed from `THREE.AdditiveBlending` to `THREE.NormalBlending`
   - Prevents color addition/brightening when dots overlap
   - Colors now display correctly at all zoom levels
   
3. **Inner sphere adjustment** - Reduced inner sphere radius
   - Changed from 0.91x to 0.9x radius for better background coverage
   - Maintains solid black background without interfering with dot layer

4. **Uniform dot sizing base** - All dots same base size (8.0) to prevent black patches
   - Removed fold size variation, edge size reduction, distance-based sizing
   - Only minimal random variation (5%) for organic appearance
   - Simplified fragment shader with minimal edge fade

### Current Point Sizing System:
```glsl
float baseSize = 8.0;                    // Base size for all dots
float screenScale = 3.0;                 // Camera scaling factor
float perspectiveScale = screenScale / uCameraDistance;
gl_PointSize = baseSize * perspectiveScale;
gl_PointSize = clamp(gl_PointSize, 1.5, 12.0);  // Prevent overlap/invisibility
```

### Material Configuration:
```javascript
blending: THREE.NormalBlending,    // Fixed color blending
transparent: true,
depthTest: true,
depthWrite: false
```

### Fixed Issues:
- ✅ White/bright colors when zoomed out (blending mode fix)
- ✅ Dot overlap at far distances (dynamic sizing with proper scaling)
- ✅ Black patches showing through waves (uniform dot sizing)
- ✅ Sun effects causing bright spots (removed sun illumination)
- Front/back gradient blending needs smoothing