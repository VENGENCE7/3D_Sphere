# Modular Shader System

This directory contains a modular shader system that separates the vertex shader into distinct, maintainable components.

## 📁 File Structure

```
src/shaders/
├── README.md                    # This file
├── shaderLoader.js             # Utility to combine modules
├── vertexShader-modular.glsl   # Main shader coordinator
├── waveSystem.glsl             # Wave generation and animation
├── colorSystem.glsl            # Eclipse color gradients
├── geometrySystem.glsl         # Point sizing and normals
├── fragmentShader.glsl         # Fragment shader (unchanged)
└── vertexShader.glsl          # Original monolithic shader (backup)
```

## 🎯 Module Overview

### 1. **Wave System** (`waveSystem.glsl`)
Handles all wave generation and animation logic:
- `createFoldingWaves()` - Main wave animation with clash effects
- `createBendingWaves()` - Fast surface ripples (currently disabled)
- `createAsymmetricDistortion()` - Organic drift motion
- `createSphericalShape()` - Master shape combination function

**Key Parameters:**
- `WAVE_FREQUENCY` (6.0) - Ripple frequency within waves
- `WAVE_SPEED` (0.25) - Wave expansion speed
- `WAVE_THICKNESS` (0.5) - Ring thickness
- `WAVE_AMPLITUDE` (0.8) - Base wave height
- `WAVE_MAX_AMPLITUDE` (2.2) - Maximum height at clash
- `WAVE_FORM` (1.0) - Wave shape control

### 2. **Color System** (`colorSystem.glsl`)
Manages eclipse color gradients and corona effects:
- `calculateEclipseColor()` - Main eclipse gradient calculation
- Complete color palette definitions
- Variable corona thickness based on position
- Special band handling for lower hemisphere

**Key Features:**
- Vertical gradient from deep violet → purple → blue → magenta → pink → red → orange → gold
- Corona band with variable thickness (thick at poles, thin at equator)
- Special colored bands in lower front-center region
- Smooth equator blending between upper/lower gradients

### 3. **Geometry System** (`geometrySystem.glsl`)
Handles geometric transformations and point rendering:
- `calculatePerturbedNormal()` - Normal vector calculation for lighting
- `calculatePointSize()` - Dynamic camera-based point sizing
- `calculateEdgeFade()` - Edge fade to prevent black strips
- `processGeometry()` - Main geometry processing pipeline

**Key Features:**
- Camera-distance responsive point sizing
- Gradient-based normal computation for wave displacement
- Edge fade system to maintain visibility
- Uniform dot sizing to prevent coverage gaps

### 4. **Main Shader** (`vertexShader-modular.glsl`)
Coordinates all modules and manages execution flow:
- Imports all module functions
- Handles uniforms and attributes
- Manages varying outputs to fragment shader
- Controls the overall rendering pipeline

## 🔧 Usage

### Basic Integration

```javascript
// In EclipseSphere.js
import { createVertexShader, createFragmentShader } from '../shaders/shaderLoader.js';

const material = new THREE.ShaderMaterial({
    vertexShader: createVertexShader(),
    fragmentShader: createFragmentShader(),
    uniforms: {
        uTime: { value: 0.0 },
        uCameraDistance: { value: 3.5 }
    },
    // ... other material properties
});
```

### Advanced Configuration

```javascript
import { shaderConfig, updateShaderConfig } from '../shaders/shaderLoader.js';

// Modify wave behavior
updateShaderConfig(material, {
    waveSpeed: 0.5,        // Faster waves
    waveAmplitude: 1.2,    // Taller waves
    waveFrequency: 8.0     // More ripples
});
```

### Direct Module Access

```javascript
import { getShaderModules } from '../shaders/shaderLoader.js';

const modules = getShaderModules();
// Access individual module code for debugging or customization
console.log(modules.waveSystem);
```

## 🎨 Customization Guide

### Modifying Wave Behavior
Edit `waveSystem.glsl`:
- Adjust wave parameters at the top of the file
- Modify wave origins in the clash detection section
- Change wave timing and cycling behavior
- Add new wave types by creating additional functions

### Changing Colors
Edit `colorSystem.glsl`:
- Modify color palette definitions
- Adjust gradient transition points
- Change corona coverage and thickness
- Alter special band positioning and colors

### Updating Geometry
Edit `geometrySystem.glsl`:
- Modify point sizing algorithms
- Adjust normal calculation methods
- Change edge fade behavior
- Update geometric transformation pipeline

### Coordinating Changes
Edit `vertexShader-modular.glsl`:
- Change execution order of modules
- Add new uniform inputs
- Modify varying outputs
- Update coordinate transformations

## 🔄 Module Dependencies

```
vertexShader-modular.glsl
├── waveSystem.glsl (provides wave displacement)
├── colorSystem.glsl (calculates final colors)
└── geometrySystem.glsl (handles transformations)
```

**Dependencies:**
- Color system depends on wave system for `totalDisplacement`
- Geometry system needs wave data for normal calculations
- Main shader coordinates all modules and provides shared uniforms

## 🚀 Benefits of Modular Structure

1. **Maintainability** - Each system can be modified independently
2. **Reusability** - Modules can be used in other shader projects
3. **Debugging** - Easier to isolate and fix issues in specific systems
4. **Collaboration** - Different developers can work on different modules
5. **Testing** - Individual modules can be tested separately
6. **Performance** - Unused modules can be easily disabled
7. **Documentation** - Each module has focused, clear documentation

## 🛠️ Development Workflow

1. **Adding New Features:**
   - Identify which module should contain the feature
   - Edit the appropriate module file
   - Update the main shader if needed
   - Test with `shaderLoader.js`

2. **Debugging Issues:**
   - Use `getShaderModules()` to inspect individual modules
   - Check module integration in `vertexShader-modular.glsl`
   - Verify parameter passing between modules

3. **Performance Optimization:**
   - Profile individual modules
   - Disable unused features by returning early in functions
   - Optimize cross-module data sharing

## 📝 Notes

- The `#include` directives are processed by `shaderLoader.js`, not WebGL
- Original `vertexShader.glsl` is kept as backup reference
- All modules maintain the same functionality as the original monolithic shader
- Module parameters can be made into uniforms for runtime control

## 🔮 Future Enhancements

- Add uniform parameters for runtime module configuration
- Create additional specialized modules (lighting, particles, etc.)
- Implement conditional compilation for different quality levels
- Add module versioning and compatibility checking