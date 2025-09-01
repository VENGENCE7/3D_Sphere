<template>
  <div ref="containerRef" :style="containerStyle"></div>
</template>

<script>
import { ref, onMounted, onUnmounted, watch } from 'vue'
import * as THREE from 'three'
import SceneManager from './SceneManager.js'
import vertexShader from './vertexShader.glsl?raw'
import fragmentShader from './fragmentShader.glsl?raw'
import { defaultConfig } from './config.js'

export default {
  name: 'WavesSphere',
  props: {
    // Zoom level from 0 to 1 (0 = far away, 1 = close up)
    zoomLevel: {
      type: Number,
      default: 0.5,
      validator: (value) => value >= 0 && value <= 1
    },
    // Container dimensions
    width: {
      type: [Number, String],
      default: '100%'
    },
    height: {
      type: [Number, String],
      default: '100%'
    },
    // Optional: override default config
    config: {
      type: Object,
      default: () => ({})
    },
    // Animation control
    autoStart: {
      type: Boolean,
      default: true
    },
    // Auto-rotation control
    autoRotate: {
      type: Boolean,
      default: true
    },
    autoRotateSpeed: {
      type: Number,
      default: 0.0008
    }
  },
  
  setup(props) {
    const containerRef = ref(null)
    let sceneManager = null
    let sphere = null
    let animationId = null
    let isInitialized = false
    
    // Computed container style
    const containerStyle = {
      width: typeof props.width === 'number' ? `${props.width}px` : props.width,
      height: typeof props.height === 'number' ? `${props.height}px` : props.height,
      position: 'relative',
      overflow: 'hidden'
    }
    
    // Merge configurations
    const finalConfig = { ...defaultConfig, ...props.config }
    
    // Calculate camera distance from zoom level (0-1 mapped to max-min distance)
    const calculateCameraDistance = (zoomLevel) => {
      const { minZoom, maxZoom } = finalConfig
      // Invert the zoom level so 0 = far, 1 = close
      return maxZoom - (zoomLevel * (maxZoom - minZoom))
    }
    
    // Calculate point size based on camera distance
    const calculatePointSize = (cameraDistance) => {
      const baseSize = finalConfig.pointBaseSize
      const zoomFactor = Math.sqrt(cameraDistance / finalConfig.defaultCameraDistance)
      return baseSize * (6.0 * zoomFactor)
    }
    
    // Create sphere geometry
    const createSphereGeometry = (radius) => {
      const points = []
      const latLines = 240
      const hexRowHeight = Math.PI / latLines
      
      for (let lat = 0; lat <= latLines; lat++) {
        const theta = lat * hexRowHeight
        const sinTheta = Math.sin(theta)
        const cosTheta = Math.cos(theta)
        
        const circumference = 2 * Math.PI * radius * sinTheta
        const targetSpacing = (2 * Math.PI * radius) / 360
        let lonLines = Math.max(3, Math.round(circumference / targetSpacing))
        
        const isOffsetRow = (lat % 2) === 1
        const phiOffset = isOffsetRow ? (Math.PI / lonLines) : 0
        
        for (let lon = 0; lon < lonLines; lon++) {
          const phi = (lon / lonLines) * 2 * Math.PI + phiOffset
          const sinPhi = Math.sin(phi)
          const cosPhi = Math.cos(phi)
          
          const x = radius * sinTheta * cosPhi
          const y = radius * cosTheta
          const z = radius * sinTheta * sinPhi
          
          points.push(x, y, z)
        }
      }
      
      return new Float32Array(points)
    }
    
    // Initialize the sphere
    const initSphere = () => {
      if (!containerRef.value || isInitialized) return
      
      // Initialize scene manager
      sceneManager = new SceneManager(containerRef.value)
      
      // Create sphere geometry
      const positions = createSphereGeometry(finalConfig.radius)
      const geometry = new THREE.BufferGeometry()
      geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3))
      geometry.setAttribute('initialPosition', new THREE.BufferAttribute(new Float32Array(positions), 3))
      
      // Add random values
      const randoms = new Float32Array(positions.length / 3)
      for (let i = 0; i < randoms.length; i++) {
        randoms[i] = Math.random()
      }
      geometry.setAttribute('aRandom', new THREE.BufferAttribute(randoms, 1))
      
      // Create material
      const material = new THREE.ShaderMaterial({
        vertexShader,
        fragmentShader,
        uniforms: {
          uTime: { value: 0.0 },
          uCameraDistance: { value: calculateCameraDistance(props.zoomLevel) }
        },
        transparent: true,
        depthTest: true,
        depthWrite: false,
        blending: THREE.NormalBlending
      })
      
      // Create points sphere
      const pointsSphere = new THREE.Points(geometry, material)
      pointsSphere.renderOrder = 1
      
      // Create background sphere
      const bgGeometry = new THREE.SphereGeometry(
        finalConfig.radius * 0.95,
        64, 32
      )
      const bgMaterial = new THREE.MeshBasicMaterial({
        color: 0x141916,
        side: THREE.FrontSide,
        transparent: false,
        depthWrite: true,
        depthTest: true
      })
      const bgSphere = new THREE.Mesh(bgGeometry, bgMaterial)
      bgSphere.renderOrder = -1
      
      // Create group
      const group = new THREE.Group()
      group.add(bgSphere)
      group.add(pointsSphere)
      
      // Store references
      sphere = {
        group,
        pointsSphere,
        bgSphere,
        material,
        geometry,
        bgGeometry,
        bgMaterial
      }
      
      // Add to scene
      sceneManager.add(group)
      
      // Set initial camera position
      const initialDistance = calculateCameraDistance(props.zoomLevel)
      sceneManager.setCameraDistance(initialDistance)
      
      // Configure auto-rotation
      sceneManager.setAutoRotate(props.autoRotate, props.autoRotateSpeed)
      
      isInitialized = true
      
      // Start animation if autoStart is true
      if (props.autoStart) {
        startAnimation()
      }
    }
    
    // Animation loop
    const animate = () => {
      if (!isInitialized) return
      
      animationId = requestAnimationFrame(animate)
      
      const elapsedTime = sceneManager.getElapsedTime()
      
      // Update shader uniforms
      if (sphere?.material) {
        sphere.material.uniforms.uTime.value = elapsedTime
        sphere.material.uniforms.uCameraDistance.value = sceneManager.getCameraDistance()
      }
      
      // Update scene
      sceneManager.update()
      sceneManager.render()
    }
    
    // Start animation
    const startAnimation = () => {
      if (animationId) return
      animate()
    }
    
    // Stop animation
    const stopAnimation = () => {
      if (animationId) {
        cancelAnimationFrame(animationId)
        animationId = null
      }
    }
    
    // Handle zoom changes with smooth transition
    watch(() => props.zoomLevel, (newZoom) => {
      if (!sceneManager) return
      
      const targetDistance = calculateCameraDistance(newZoom)
      sceneManager.smoothZoomTo(targetDistance, 500) // 500ms transition
    })
    
    // Handle auto-rotation changes
    watch(() => props.autoRotate, (newValue) => {
      if (sceneManager) {
        sceneManager.setAutoRotate(newValue, props.autoRotateSpeed)
      }
    })
    
    watch(() => props.autoRotateSpeed, (newSpeed) => {
      if (sceneManager) {
        sceneManager.setAutoRotate(props.autoRotate, newSpeed)
      }
    })
    
    // Cleanup
    const cleanup = () => {
      stopAnimation()
      
      if (sphere) {
        sphere.geometry?.dispose()
        sphere.material?.dispose()
        sphere.bgGeometry?.dispose()
        sphere.bgMaterial?.dispose()
      }
      
      if (sceneManager) {
        sceneManager.dispose()
      }
      
      isInitialized = false
    }
    
    // Lifecycle
    onMounted(() => {
      initSphere()
    })
    
    onUnmounted(() => {
      cleanup()
    })
    
    // Public methods
    return {
      containerRef,
      containerStyle,
      startAnimation,
      stopAnimation,
      zoomTo: (level) => {
        if (sceneManager) {
          const distance = calculateCameraDistance(level)
          sceneManager.smoothZoomTo(distance)
        }
      }
    }
  }
}
</script>

<style scoped>
div {
  background: #000000;
}
</style>