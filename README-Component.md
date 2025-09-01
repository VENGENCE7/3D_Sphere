# WavesSphere Component

A complete, self-contained animated 3D sphere component with liquid wave effects and eclipse-style color gradients. Built with Three.js and designed for easy integration into any web project.

## 🚀 Quick Start

### Option 1: Bundle (Recommended)

```html
<!DOCTYPE html>
<html>
<head>
    <title>WavesSphere Demo</title>
    <style>
        #container {
            width: 100vw;
            height: 100vh;
        }
    </style>
</head>
<body>
    <div id="container"></div>
    
    <!-- Three.js -->
    <script src="https://unpkg.com/three@latest/build/three.min.js"></script>
    
    <!-- WavesSphere Bundle -->
    <script src="waves-sphere-bundle.js"></script>
    
    <script>
        const sphere = new WavesSphere(document.getElementById('container'));
        sphere.start();
    </script>
</body>
</html>
```

### Option 2: ES6 Modules

```javascript
import WavesSphere from './src/components/WavesSphere.js';

const container = document.getElementById('container');
const sphere = new WavesSphere(container, {
    autoRotate: true,
    waveSpeed: 0.3,
    cameraDistance: 4.0
});

sphere.start();
```

### Option 3: React Integration

```jsx
import WavesSphereComponent from './examples/react-integration.jsx';

function App() {
    return (
        <div style={{ width: '100vw', height: '100vh' }}>
            <WavesSphereComponent
                config={{
                    autoRotate: true,
                    waveSpeed: 0.25,
                    cameraDistance: 4.0
                }}
                autoStart={true}
            />
        </div>
    );
}
```

### Option 4: Auto-Detection (Vanilla JS)

```html
<!-- Auto-detected sphere with data attributes -->
<div 
    data-waves-sphere
    data-sphere-auto-rotate="true"
    data-sphere-wave-speed="0.3"
    data-sphere-camera-distance="5.0"
    style="width: 800px; height: 600px;"
></div>

<!-- Include scripts and integration -->
<script src="https://unpkg.com/three@latest/build/three.min.js"></script>
<script src="waves-sphere-bundle.js"></script>
<script src="vanilla-js-integration.js"></script>
```

## 📋 API Reference

### Constructor

```javascript
const sphere = new WavesSphere(container, options);
```

**Parameters:**
- `container` (HTMLElement): DOM element to render the sphere in
- `options` (Object): Configuration options (see Configuration section)

### Methods

#### Animation Control
```javascript
sphere.start()           // Start animation
sphere.stop()            // Stop animation
sphere.reinit()          // Reinitialize component
```

#### Zoom Control
```javascript
sphere.zoomIn(factor, smooth)      // Zoom in (factor: 0.8, smooth: true)
sphere.zoomOut(factor, smooth)     // Zoom out (factor: 1.25, smooth: true)
sphere.zoomTo(distance, smooth)    // Zoom to specific distance
sphere.resetZoom(smooth)           // Reset to default zoom
sphere.getZoomLevel()              // Get normalized zoom level (0-1)
sphere.setZoomLevel(level, smooth) // Set normalized zoom level (0-1)
```

#### Configuration
```javascript
sphere.updateConfig(newConfig)     // Update configuration
sphere.isInitialized()             // Check if properly initialized
sphere.getMemoryUsage()            // Get Three.js memory stats
```

#### Lifecycle
```javascript
sphere.destroy()                   // Complete cleanup and removal
sphere.dispose()                   // Alias for destroy()
```

## ⚙️ Configuration Options

### Basic Settings

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `radius` | number | 1.5 | Sphere radius (0.5 - 5.0) |
| `pointBaseSize` | number | 6.0 | Base point size (1.0 - 20.0) |
| `cameraDistance` | number | 3.5 | Default camera distance (1.0 - 20.0) |
| `minZoom` | number | 2.0 | Minimum zoom distance (0.5 - 10.0) |
| `maxZoom` | number | 15.0 | Maximum zoom distance (5.0 - 50.0) |

### Wave System

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `waveFrequency` | number | 6.0 | Ripple frequency within waves (1.0 - 20.0) |
| `waveSpeed` | number | 0.25 | Wave expansion speed (0.1 - 1.0) |
| `waveThickness` | number | 0.5 | Ring thickness (0.1 - 1.0) |
| `waveAmplitude` | number | 0.8 | Base wave height (0.1 - 2.0) |
| `waveMaxAmplitude` | number | 2.2 | Maximum height at clash (0.5 - 5.0) |
| `waveCycle` | number | 4.0 | Wave repeat cycle in seconds (1.0 - 20.0) |
| `waveForm` | number | 1.0 | Wave shape control (0.5 - 3.0) |

### Interaction

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `autoRotate` | boolean | true | Enable auto-rotation |
| `autoRotateSpeed` | number | 0.0008 | Auto-rotation speed (0.0001 - 0.01) |
| `enableControls` | boolean | true | Enable mouse/touch controls |
| `damping` | number | 0.1 | Rotation damping factor (0.01 - 0.5) |

### Performance

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `pixelRatio` | number | auto | Device pixel ratio (1-2) |
| `enableStats` | boolean | false | Show performance statistics |
| `backgroundColor` | number | 0x000000 | Background color (hex) |

## 🎨 Preset Configurations

Use predefined configurations for common scenarios:

```javascript
import { getPresetConfig } from './src/config/WavesSphereConfig.js';

// Available presets: 'default', 'calm', 'energetic', 'large', 'small', 'static', 'performance', 'quality'
const config = getPresetConfig('energetic');
const sphere = new WavesSphere(container, config);
```

### Preset Descriptions

- **`default`** - Standard configuration, balanced performance and quality
- **`calm`** - Slow, gentle waves with minimal rotation
- **`energetic`** - Fast, dramatic waves with quick rotation
- **`large`** - Big sphere with proportionally scaled effects
- **`small`** - Compact sphere with detailed effects
- **`static`** - No auto-rotation, manual control only
- **`performance`** - Optimized for performance, lower quality
- **`quality`** - Optimized for quality, higher resource usage

## 🔧 Advanced Usage

### Configuration Builder

```javascript
import { createConfig } from './src/config/WavesSphereConfig.js';

const config = createConfig()
    .radius(2.0)
    .waveSpeed(0.4)
    .waveAmplitude(1.2)
    .autoRotate(true, 0.002)
    .cameraDistance(5.0)
    .zoomRange(2.0, 20.0)
    .build();

const sphere = new WavesSphere(container, config);
```

### URL Parameter Configuration

```javascript
import { configFromParams } from './src/config/WavesSphereConfig.js';

// Parse from current URL: ?sphere-radius=2.0&sphere-wave-speed=0.5
const config = configFromParams(window.location.search);
const sphere = new WavesSphere(container, config);
```

### Multiple Spheres

```javascript
const configs = [
    { radius: 1.0, waveSpeed: 0.2 },
    { radius: 1.5, waveSpeed: 0.3 },
    { radius: 2.0, waveSpeed: 0.4 }
];

const spheres = configs.map((config, index) => {
    const container = document.getElementById(`sphere-${index}`);
    const sphere = new WavesSphere(container, config);
    sphere.start();
    return sphere;
});
```

### Event Handling

```javascript
// Custom events for vanilla JS integration
document.addEventListener('wavesSphereCreated', (event) => {
    console.log('Sphere created:', event.detail.id);
});

document.addEventListener('wavesSphereDestroyed', (event) => {
    console.log('Sphere destroyed:', event.detail.id);
});
```

### React Hooks

```jsx
import { useEffect, useRef } from 'react';

function useWavesSphere(config, autoStart = true) {
    const containerRef = useRef(null);
    const sphereRef = useRef(null);
    
    useEffect(() => {
        if (containerRef.current) {
            sphereRef.current = new WavesSphere(containerRef.current, config);
            if (autoStart) sphereRef.current.start();
        }
        
        return () => {
            if (sphereRef.current) {
                sphereRef.current.destroy();
            }
        };
    }, [config, autoStart]);
    
    return [containerRef, sphereRef.current];
}

// Usage
function MyComponent() {
    const [containerRef, sphere] = useWavesSphere({
        autoRotate: true,
        waveSpeed: 0.3
    });
    
    return <div ref={containerRef} style={{ width: '100%', height: '400px' }} />;
}
```

## 🎮 Controls

### Mouse/Touch Controls (Default)
- **Drag**: Rotate the sphere
- **Scroll**: Zoom in/out
- **Touch**: Single finger to rotate

### Programmatic Controls
```javascript
// Zoom controls
sphere.zoomIn();           // Quick zoom in
sphere.zoomOut();          // Quick zoom out
sphere.resetZoom();        // Return to default
sphere.setZoomLevel(0.7);  // Set to 70% zoom

// Animation controls
sphere.start();            // Start animation
sphere.stop();             // Pause animation

// Configuration updates
sphere.updateConfig({
    waveSpeed: 0.5,
    autoRotateSpeed: 0.002
});
```

## 🔍 Troubleshooting

### Common Issues

**1. Sphere doesn't appear**
- Ensure Three.js is loaded before WavesSphere
- Check that the container has dimensions (width/height)
- Verify WebGL is supported in the browser

**2. Poor performance**
- Use the 'performance' preset
- Lower the pixelRatio to 1
- Reduce pointBaseSize
- Disable auto-rotation

**3. Controls not working**
- Ensure enableControls is true
- Check that the container is receiving pointer events
- Verify the canvas is properly sized

**4. Memory leaks**
- Always call destroy() when removing spheres
- Use the getMemoryUsage() method to monitor resources

### Debug Information

```javascript
// Check initialization status
console.log('Initialized:', sphere.isInitialized());

// Monitor memory usage
console.log('Memory:', sphere.getMemoryUsage());

// Get current configuration
console.log('Config:', sphere.config);
```

## 📱 Browser Support

- **Chrome/Edge**: Full support
- **Firefox**: Full support
- **Safari**: Full support (iOS 12+)
- **Mobile**: Touch controls supported

**Requirements:**
- WebGL support
- ES6 features (can be polyfilled)
- Three.js r150+

## 📦 File Structure

```
src/
├── components/
│   └── WavesSphere.js           # Main component class
├── assets/
│   └── waves-sphere-bundle.js   # Complete bundle
├── config/
│   └── WavesSphereConfig.js     # Configuration system
├── shaders/                     # Modular shaders (optional)
└── examples/                    # Integration examples
    ├── basic-usage.html
    ├── multiple-spheres.html
    ├── react-integration.jsx
    └── vanilla-js-integration.js
```

## 🚀 Performance Tips

1. **Use the bundle** for simplest integration
2. **Limit sphere count** to 2-3 on mobile devices
3. **Use presets** instead of custom configs when possible
4. **Monitor memory usage** in long-running applications
5. **Destroy spheres** when navigating away from pages

## 🔄 Migration Guide

### From Original Implementation

```javascript
// Old way (original files)
import { EclipseSphere } from './src/geometry/EclipseSphere.js';
import { SceneManager } from './src/scene/SceneManager.js';

// New way (component)
import WavesSphere from './src/components/WavesSphere.js';
const sphere = new WavesSphere(container);
```

### Configuration Mapping

| Old | New |
|-----|-----|
| Manual shader loading | Built-in shaders |
| Separate scene management | Integrated |
| Manual controls setup | Built-in controls |
| Custom update loop | Built-in animation |

## 📄 License

This component is part of the WavesSphere project. See main project license for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes with the provided examples
4. Submit a pull request

## 📞 Support

- Check the troubleshooting section
- Review the examples
- File issues on the project repository

---

**Happy coding with WavesSphere! 🌊✨**