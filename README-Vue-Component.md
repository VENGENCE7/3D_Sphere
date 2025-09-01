# Waves Sphere Vue Component

A simplified, reusable Vue 3 component for displaying an animated 3D sphere with wave effects.

## Installation

### Prerequisites
```bash
npm install three
```

### Usage

1. Copy `WavesSphere.vue` to your components directory
2. Import and use in your Vue application:

```vue
<template>
  <div>
    <WavesSphere 
      :width="800" 
      :height="600"
      :enable-rotation="true"
      :enable-zoom="true"
    />
  </div>
</template>

<script setup>
import WavesSphere from '@/components/WavesSphere.vue';
</script>
```

## Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `width` | Number | 800 | Canvas width in pixels |
| `height` | Number | 600 | Canvas height in pixels |
| `radius` | Number | 1.5 | Sphere radius |
| `backgroundColor` | String | '#000000' | Background color |
| `enableRotation` | Boolean | true | Enable mouse rotation |
| `enableZoom` | Boolean | true | Enable mouse zoom |
| `autoRotate` | Boolean | false | Auto-rotate sphere |
| `autoRotateSpeed` | Number | 1.0 | Auto-rotation speed |

## Features

- **Simplified wave animation** - Two circular waves that expand and clash
- **Eclipse-style gradient** - Smooth color transitions from center to edge
- **Interactive controls** - Optional mouse rotation and zoom
- **Responsive** - Adapts to container size changes
- **Performance optimized** - Reduced geometry complexity for web use
- **Self-contained** - All shaders included inline
- **Vue 3 Composition API** - Modern Vue.js patterns
- **Automatic cleanup** - Proper disposal on component unmount

## Examples

### Basic Usage
```vue
<WavesSphere />
```

### Custom Size
```vue
<WavesSphere :width="600" :height="400" />
```

### Auto-rotating
```vue
<WavesSphere 
  :auto-rotate="true"
  :auto-rotate-speed="2"
/>
```

### Static Display (No Interaction)
```vue
<WavesSphere 
  :enable-rotation="false"
  :enable-zoom="false"
/>
```

### Responsive Container
```vue
<template>
  <div ref="container" class="sphere-container">
    <WavesSphere 
      :width="dimensions.width" 
      :height="dimensions.height"
    />
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue';
import WavesSphere from '@/components/WavesSphere.vue';

const container = ref(null);
const dimensions = reactive({ width: 800, height: 600 });

onMounted(() => {
  const updateSize = () => {
    if (container.value) {
      dimensions.width = container.value.clientWidth;
      dimensions.height = container.value.clientHeight;
    }
  };
  
  updateSize();
  window.addEventListener('resize', updateSize);
});
</script>

<style>
.sphere-container {
  width: 100%;
  height: 600px;
}
</style>
```

## Customization

### Modifying Colors
Edit the color values in the vertex shader within the component:

```javascript
// In WavesSphere.vue vertex shader
vec3 centerColor = vec3(0.078, 0.098, 0.086);  // Dark center
vec3 purple = vec3(0.35, 0.0, 0.7);            // Purple ring
vec3 blue = vec3(0.26, 0.0, 0.93);             // Blue ring
vec3 magenta = vec3(0.6, 0.0, 0.6);            // Magenta ring
vec3 orange = vec3(1.0, 0.4, 0.0);             // Orange ring
vec3 gold = vec3(1.0, 0.9, 0.4);               // Gold edge
```

### Adjusting Wave Parameters
Modify wave settings in the vertex shader:

```javascript
// In createWaves function
float WAVE_FREQUENCY = 6.0;    // Ripple frequency
float WAVE_SPEED = 0.25;        // Expansion speed
float WAVE_AMPLITUDE = 0.8;     // Wave height
```

### Performance Tuning
Adjust geometry density:

```javascript
// In createSphereGeometry function
const latLines = 120;  // Reduce for better performance
```

## Browser Compatibility

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

Requires WebGL 2.0 support.

## License

MIT