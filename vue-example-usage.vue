<template>
  <div id="app">
    <h1>Waves Sphere Vue Component Examples</h1>
    
    <!-- Basic Usage -->
    <section>
      <h2>Basic Usage</h2>
      <WavesSphere />
    </section>

    <!-- Custom Size -->
    <section>
      <h2>Custom Size</h2>
      <WavesSphere 
        :width="600" 
        :height="400" 
      />
    </section>

    <!-- Auto-rotating Sphere -->
    <section>
      <h2>Auto-rotating</h2>
      <WavesSphere 
        :width="500" 
        :height="500"
        :auto-rotate="true"
        :auto-rotate-speed="2"
      />
    </section>

    <!-- Disabled Controls -->
    <section>
      <h2>Static (No Controls)</h2>
      <WavesSphere 
        :width="500" 
        :height="500"
        :enable-rotation="false"
        :enable-zoom="false"
      />
    </section>

    <!-- Multiple Spheres -->
    <section>
      <h2>Multiple Spheres</h2>
      <div class="spheres-grid">
        <WavesSphere 
          v-for="i in 4" 
          :key="i"
          :width="300" 
          :height="300"
          :radius="1.2"
        />
      </div>
    </section>

    <!-- Responsive Container -->
    <section>
      <h2>Responsive Container</h2>
      <div class="responsive-container">
        <WavesSphere 
          :width="containerWidth" 
          :height="containerHeight"
        />
      </div>
    </section>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue';
import WavesSphere from './WavesSphere.vue';

// For responsive example
const containerWidth = ref(800);
const containerHeight = ref(600);

function updateContainerSize() {
  const container = document.querySelector('.responsive-container');
  if (container) {
    containerWidth.value = container.clientWidth;
    containerHeight.value = 600; // Fixed height or calculate based on aspect ratio
  }
}

onMounted(() => {
  updateContainerSize();
  window.addEventListener('resize', updateContainerSize);
});

onUnmounted(() => {
  window.removeEventListener('resize', updateContainerSize);
});
</script>

<style>
#app {
  font-family: Arial, sans-serif;
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
  background: #f5f5f5;
}

h1 {
  color: #333;
  text-align: center;
  margin-bottom: 40px;
}

h2 {
  color: #555;
  margin-top: 30px;
  margin-bottom: 20px;
}

section {
  background: white;
  padding: 20px;
  margin-bottom: 30px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.spheres-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
  justify-items: center;
}

.responsive-container {
  width: 100%;
  min-height: 600px;
  display: flex;
  justify-content: center;
  align-items: center;
  background: #000;
  border-radius: 8px;
}
</style>