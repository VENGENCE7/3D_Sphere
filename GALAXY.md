# Galaxy - Solar System Project Context & Documentation

## Overview
The Galaxy component is a custom solar system visualization featuring the Blob/Eclipse sphere as the Sun, with 8 planets orbiting in 4 distinct orbital paths, all set against a space-like starfield background.

## Architecture

### Core Files Structure
```
src/
└── components/
    └── galaxy/
        ├── GalaxyLauncher.js      # Entry point and initialization
        ├── SceneManager.js        # Three.js scene setup for galaxy
        ├── SolarSystem.js         # Main file that combines Sun, orbits, and planets
        ├── StarField.js           # Background star generation
        ├── Orbit.js               # Orbital path class with rotation logic
        ├── PlanetBlob.js          # Reusable Blob component for planets (similar to EclipseSphere)
        ├── planetsConfig.js       # Configuration file for all 8 planets
        └── shaders/
            ├── planetVertex.glsl  # Vertex shader for planet blobs
            ├── planetFragment.glsl # Fragment shader for planet blobs
            ├── starVertex.glsl    # Vertex shader for background stars
            └── starFragment.glsl  # Fragment shader for background stars
```

### File Responsibilities

1. **SolarSystem.js** (Main Coordinator)
   - Imports and creates the Sun (Blob/Eclipse sphere)
   - Creates 8 PlanetBlob instances using planetsConfig
   - Imports and manages Orbit instances
   - Assigns planets to their respective orbits
   - Coordinates animations between all elements
   - Handles the overall solar system logic

2. **Orbit.js** (Orbital Mechanics)
   - Defines orbital path geometry
   - Handles orbital inclination/rotation
   - Manages orbital speed
   - Provides position calculations for planets

3. **PlanetBlob.js** (Reusable Planet Component)
   - Similar structure to EclipseSphere but simplified
   - Blob-like organic shape as shown in planet.png
   - Smooth, rounded irregular form with liquid-like organic movement
   - **Surface Rendering**: Smooth continuous surface (NOT dots/points)
   - **Gradient System**: 
     - Colors fade from given color to black
     - Solid colors with smooth gradient shading
     - Soft, glowing appearance with highlight areas
   - **Organic Animation** (60 FPS optimized):
     - Liquid-like surface deformation
     - Smooth breathing/pulsing effects
     - Subtle wave movements across surface
     - Performance: 0.1-0.3 amplitude, 0.5-1.0 speed factors
   - Takes configuration object for customization
   - Handles blob geometry with smooth animated surface

4. **planetsConfig.js** (Planet Configuration)
   - Single configuration file for all 8 planets
   - Defines size, colors, and properties for each planet
   - Easy to modify without touching code

### Planet Configuration Structure (planetsConfig.js)
```javascript
// Fully customizable planet configuration
// All planets use blob-like organic shapes as shown in planet.png

export const planetsConfig = [
  {
    // Planet 1 - Orbit 1 (Gray)
    id: 'planet1',
    orbitIndex: 0,  // First orbit
    
    // Visual Properties (Blob Style)
    size: 0.3,  // Blob size (0.1 to 1.0 recommended)
    blobness: 0.15,  // How irregular the shape is (0 = sphere, 0.3 = very blobby)
    
    // Text Label (shown inside blob)
    text: 'MERCURY',  // Change to any text you want
    textColor: '#FFFFFF',  // Any hex color
    textSize: 0.08,  // Text scale relative to planet
    textFont: 'Arial',  // Font family
    textWeight: 'bold',  // Font weight (normal, bold)
    
    // Color Configuration (Gradient to black)
    color: {
      base: '#B9B9B9',  // Light gray primary blob color
      gradient: ['#B9B9B9', '#8A8A8A', '#5A5A5A', '#2A2A2A', '#000000'],  // Fade to black
      glowIntensity: 0.3  // Soft glow strength
    },
    
    // Liquid Animation Settings (60 FPS optimized)
    liquidMovement: {
      enabled: true,
      waveSpeed: 0.5,       // Slow wave speed for 60 FPS
      waveAmplitude: 0.15,  // Subtle deformation
      breathingSpeed: 0.3,  // Gentle breathing
      breathingScale: 0.05, // Small scale changes
      noiseScale: 2.5,      // Organic noise pattern size
      flowSpeed: 0.2        // Liquid flow animation
    },
    
    // Material Properties
    material: {
      metalness: 0.3,  // 0 = matte, 1 = metallic
      roughness: 0.8,  // 0 = smooth, 1 = rough
      emissiveIntensity: 0.1  // Glow strength
    },
    
    // Animation
    rotation: {
      speed: 0.005,  // Self-rotation speed
      axis: { x: 0, y: 1, z: 0.1 }  // Rotation axis tilt
    },
    
    // Orbital Position
    startAngle: 0,  // Starting position in radians (0 to 2*PI)
    
    // Optional Features
    features: {
      hasRings: false,  // Enable/disable rings
      ringColor: '#CCCCCC',
      ringOpacity: 0.5,
      hasAtmosphere: false,  // Enable/disable atmosphere
      atmosphereColor: '#88CCFF',
      atmosphereScale: 1.2
    }
  },
  
  {
    // Planet 2 - Orbit 1 (Gray - opposite side)  
    id: 'planet2',
    orbitIndex: 0,
    size: 0.4,
    blobness: 0.15,
    text: 'VENUS',  // Customize this text
    textColor: '#FFFFFF',
    textSize: 0.1,
    textFont: 'Arial',
    textWeight: 'bold',
    color: {
      base: '#B9B9B9',  // Gray (same as planet 1)
      gradient: ['#B9B9B9', '#8A8A8A', '#5A5A5A', '#2A2A2A', '#000000'],  // Fade to black
      glowIntensity: 0.3
    },
    
    // Liquid Animation Settings (60 FPS optimized)
    liquidMovement: {
      enabled: true,
      waveSpeed: 0.5,
      waveAmplitude: 0.15,
      breathingSpeed: 0.3,
      breathingScale: 0.05,
      noiseScale: 2.5,
      flowSpeed: 0.2
    },
    material: {
      metalness: 0.2,
      roughness: 0.7,
      emissiveIntensity: 0.15
    },
    rotation: {
      speed: 0.003,
      axis: { x: 0.05, y: 1, z: 0 }
    },
    startAngle: Math.PI,  // Opposite side (180°)
    features: {
      hasRings: false,
      hasAtmosphere: true,
      atmosphereColor: '#FFCC66',
      atmosphereScale: 1.1
    }
  },
  
  {
    // Planet 3 - Middle Orbit
    id: 'planet3',
    orbitIndex: 1,  // Middle orbit
    size: 0.35,
    blobness: 0.15,
    text: 'EARTH',  // Customize this text
    textColor: '#FFFFFF',
    textSize: 0.09,
    textFont: 'Arial',
    textWeight: 'bold',
    color: {
      base: '#CE7F01',  // Orange-brown primary blob color
      highlight: '#EE9F21',  // Lighter orange highlight
      shadow: '#AE5F00',  // Darker orange-brown shadow
      glowIntensity: 0.3
    },
    material: {
      metalness: 0.1,
      roughness: 0.6,
      emissiveIntensity: 0.05
    },
    rotation: {
      speed: 0.01,
      axis: { x: 0.4, y: 1, z: 0 }  // Tilted axis
    },
    startAngle: 0,
    features: {
      hasRings: false,
      hasAtmosphere: false
    }
  },
  
  {
    // Planet 4 - Middle Orbit
    id: 'planet4',
    orbitIndex: 1,  // Middle orbit
    size: 0.38,
    blobness: 0.15,
    text: 'MARS',  // Customize this text
    textColor: '#FFFFFF',
    textSize: 0.09,
    textFont: 'Arial',
    textWeight: 'bold',
    color: {
      base: '#00C77F',  // Green primary blob color
      highlight: '#00E79F',  // Lighter green highlight
      shadow: '#00A75F',  // Darker green shadow
      glowIntensity: 0.3
    },
    material: {
      metalness: 0.15,
      roughness: 0.65,
      emissiveIntensity: 0.08
    },
    rotation: {
      speed: 0.008,
      axis: { x: 0.2, y: 1, z: 0 }
    },
    startAngle: Math.PI,  // Opposite side (180 degrees)
    features: {
      hasRings: false,
      hasAtmosphere: false
    }
  },
  
  // Add planets 5-6 with your custom configurations...
]

// Example custom planet configuration:
/*
{
  id: 'customPlanet',
  orbitIndex: 2,  // Outer orbit
  size: 0.6,
  text: 'MY PLANET',  // Your custom text
  textColor: '#00FF00',  // Green text
  textSize: 0.12,
  color: {
    base: '#FF00FF',  // Purple planet
    gradient: ['#FF00FF', '#CC00CC', '#990099'],
    emissive: '#440044',
    specular: '#FFFFFF'
  },
  material: {
    metalness: 0.5,
    roughness: 0.5,
    emissiveIntensity: 0.2
  },
  rotation: {
    speed: 0.02,
    axis: { x: 0.3, y: 1, z: 0.3 }
  },
  startAngle: Math.PI / 2,  // 90 degrees
  features: {
    hasRings: true,  // This planet has rings!
    ringColor: '#FFAA00',
    ringOpacity: 0.6,
    hasAtmosphere: false
  }
}
*/
```

### Text Display Features
- **Text Inside Blob**: Each planet blob contains text that is ALWAYS visible from the front
- **Front-Facing Visibility**: Text is always readable when viewing from the front, regardless of planet rotation
- **Text Properties**:
  - Customizable text content (planet names or other labels)
  - Adjustable text color for visibility against blob colors
  - Scalable text size based on planet size
  - Font styling options (bold, font family)
- **Text Implementation**:
  - Uses Three.js TextGeometry or CSS3DObject for rendering
  - Positioned at center of blob
  - Billboarding effect to always face viewer
  - Depth test disabled to show through blob surface
  - Text remains oriented toward camera even as planet rotates

### Interaction System

#### Camera Controls
- **Zoom In/Out Only**: 
  - Mouse wheel for zoom control
  - Touch pinch gestures for mobile
  - Zoom limits: Min 5 units, Max 30 units from center
  - Smooth zoom transitions
  - No rotation or panning - fixed viewing angle

#### Solar System Animation
- **Central Sun**: The existing Blob/Eclipse sphere at the center
  - Maintains all its animations (waves, colors, membrane)
  - Acts as the gravitational center
  - Stationary at origin (0, 0, 0)

- **Planetary Orbits**:
  - All 8 planets continuously orbit around the central Sun
  - Each orbit at different speeds (inner = fastest, outer = slowest)
  - Smooth circular/elliptical paths
  - Orbits at different inclinations:
    - Orbit 1: 0° (flat)
    - Orbit 2: -162.171°
    - Orbit 3: 14.37°
    - Orbit 4: 45°
  
- **Planet Behavior**:
  - Planets rotate on their own axis while orbiting
  - Text labels inside planets always face the viewer
  - Planets maintain consistent spacing on their orbits
  - No collision between planets (180° apart on same orbit)
  - **Dynamic Sizing**: Planets appear smaller when farther from camera, larger when closer
  - **Organic Size Changes**: Smooth, organic shrinking/growing as planets orbit (breathing effect)
  - Size transitions are gradual and liquid-like, not abrupt

## Implementation Status

### Current State
- Basic launcher file exists
- Tab navigation integration complete
- Scene manager needs implementation
- Solar system needs creation

## Design Specifications

### Visual Elements

#### 1. Space Background
- Starfield with varying star sizes and brightness
- Static stars to resemble deep space
- Dark space-like background color (#000000 or deep blue)
- Possible nebula or galaxy textures in background

#### 2. The Sun (Center)
- **Uses existing Blob/Eclipse sphere** from the Blob component
- Positioned at origin (0, 0, 0)
- Maintains all its wave animations and color gradients
- Acts as the gravitational center of the solar system
- Possible emission of light affecting planets

#### 3. Orbital System
- **4 Orbital Rings** at different distances from the Sun:
  - Orbit 1: Closest to the Sun
  - Orbit 2: Inner-middle distance
  - Orbit 3: Outer-middle distance
  - Orbit 4: Farthest from the Sun
- Orbital paths visible as subtle rings (optional)
- Each orbit at a different inclination for visual interest

#### 4. Planets
- **8 Total Planets** (2 per orbit, same color pair per orbit):
  - Orbit 1: 2 gray planets (#B9B9B9) - fastest rotation
  - Orbit 2: 2 cyan planets (#00C5C5) - fast rotation
  - Orbit 3: 2 orange planets (#CE7F01) - slow rotation
  - Orbit 4: 2 green planets (#00C77F) - slowest rotation
- **Visual Style** (as per planet.png):
  - Blob-like organic shape (not perfect spheres)
  - Smooth, glossy surface with soft edges
  - Gradient shading from light to darker edges
  - Subtle glow/highlight on upper portion
  - No surface details or textures - just smooth blobs
- Different sizes for each planet
- Unique colors for each planet (yellow, blue, red, green, etc.)
- Text label floating inside each blob

### Animation System

#### Orbital Motion
- Planets orbit around the Sun at different speeds
- Inner planets move faster (Kepler's laws)
- Planets on same orbit have different starting positions (180° apart)
- Smooth elliptical or circular paths
- Independent rotation of each planet on its axis

#### Sun Animation
- Maintains all Blob animations:
  - Wave band system
  - Color gradients
  - Organic membrane movement
  - Possible pulsing to simulate solar activity

### Interaction Controls
- Camera controls to view from different angles
- Zoom in/out to see full system or focus on planets
- Click on planets for information (optional)
- Speed control for orbital motion
- Pause/play animation

## Technical Requirements

### Performance Targets
- Target: 60 FPS with all planets and Sun animations
- WebGL 2.0 support required
- Efficient rendering for multiple animated objects

### Shader System
- Background star rendering (point sprites)
- Planet shading with proper lighting from Sun
- Possible glow effects for Sun
- Atmospheric effects for planets

## Development Tasks

### Phase 1: Core Structure
- [x] Update GALAXY.md with solar system specifications
- [ ] Create space background with stars
- [ ] Import and position the Blob/Eclipse sphere as the Sun
- [ ] Set up scene manager for solar system

### Phase 2: Orbital System
- [ ] Create 4 orbital paths around the Sun
- [ ] Add 2 planets to each orbit (8 planets total)
- [ ] Implement orbital motion for planets
- [ ] Add planet rotation on axis

### Phase 3: Visual Enhancement
- [ ] Add different colors/textures to planets
- [ ] Implement orbital path visualization
- [ ] Add lighting effects from Sun
- [ ] Create planet atmosphere effects

### Phase 4: Interaction & Controls
- [ ] Implement camera controls
- [ ] Add zoom functionality
- [ ] Create speed controls for orbits
- [ ] Add pause/play functionality

## Configuration Parameters
```javascript
// Solar System Configuration
solarSystemConfig = {
  // Background
  starCount: 5000,            // Background stars
  starFieldRadius: 100,       // Distribution radius
  
  // Sun (Blob)
  sunScale: 1.0,              // Scale of the Blob sphere
  sunPosition: [0, 0, 0],     // Center of system
  
  // Orbital Configuration
  orbits: [
    {
      radius: 5,              // Orbit 1 - Closest
      speed: 0.003,           // Fastest
      inclination: 0,         // Orbital tilt (flat on XZ plane)
      planets: 2,
      planetColor: '#B9B9B9'  // Gray planets
    },
    {
      radius: 8,              // Orbit 2 - Inner-middle
      speed: 0.002,           // Fast speed
      inclination: -162.171,  // Specific rotation angle in degrees
      planets: 2,
      planetColor: '#00C5C5'  // Cyan planets
    },
    {
      radius: 11,             // Orbit 3 - Outer-middle
      speed: 0.0015,          // Slow speed
      inclination: 14.37,     // Specific rotation angle in degrees
      planets: 2,
      planetColor: '#CE7F01'  // Orange planets
    },
    {
      radius: 14,             // Orbit 4 - Farthest
      speed: 0.001,           // Slowest
      inclination: 45,        // 45 degree tilt
      planets: 2,
      planetColor: '#00C77F'  // Green planets
    }
  ],
  
  // Planet Configuration (defined per orbit in orbits array above)
  planetRotationSpeed: 0.01,  // Self-rotation speed
  
  // Camera
  initialCameraPosition: [15, 10, 15],
  cameraLookAt: [0, 0, 0]
}
```

## Integration with Main App

### Tab Navigation
- Accessible via "Galaxy" tab
- Shares container with Blob view
- Proper cleanup on view switch
- Memory management for large particle counts

## Notes & Ideas
[Space for brainstorming and requirements]
- Consider adding asteroid belts
- Possible comet trails
- Black hole gravitational effects
- Star formation regions
- Interactive star selection
- Constellation patterns
- Time-lapse evolution

## References
- Three.js particle systems
- GPU instancing techniques
- Astronomical visualization best practices
- Performance optimization strategies

---
*Created: December 2024*
*Status: Planning Phase*