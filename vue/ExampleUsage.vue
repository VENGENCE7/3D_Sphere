<template>
  <div class="app">
    <!-- Single WavesSphere component with zoom control -->
    <WavesSphere
      :zoom-level="zoomLevel"
      width="100%"
      height="100vh"
    />
  </div>
</template>

<script>
import { ref } from 'vue'
import WavesSphere from './WavesSphere.vue'

export default {
  name: 'ExampleUsage',
  components: {
    WavesSphere
  },
  
  setup() {
    // Single zoom control value from 0 to 1
    // 0 = far away (zoomed out)
    // 1 = close up (zoomed in)
    const zoomLevel = ref(0.5) // Start at 50% zoom
    
    // Example: Change zoom programmatically
    // You can update this value based on scroll, time, or any other trigger
    
    // Example function to set zoom
    const setZoom = (value) => {
      // Ensure value is between 0 and 1
      zoomLevel.value = Math.max(0, Math.min(1, value))
    }
    
    // Example: Animate zoom on page load
    setTimeout(() => {
      // Start far
      zoomLevel.value = 0.2
      
      // Zoom in after 1 second
      setTimeout(() => {
        zoomLevel.value = 0.6
      }, 1000)
      
      // Settle at normal after 2 seconds
      setTimeout(() => {
        zoomLevel.value = 0.5
      }, 2000)
    }, 500)
    
    return {
      zoomLevel,
      setZoom
    }
  }
}
</script>

<style scoped>
.app {
  width: 100%;
  height: 100vh;
  overflow: hidden;
  background: #000000;
}
</style>