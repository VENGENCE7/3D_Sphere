import * as THREE from 'three'

export default class SceneManager {
  constructor(container) {
    this.container = container
    this.scene = null
    this.camera = null
    this.renderer = null
    this.clock = null
    
    // Mouse/touch controls
    this.isMouseDown = false
    this.mouseX = 0
    this.mouseY = 0
    this.targetRotationX = 0.15
    this.targetRotationY = -0.3
    this.currentRotationX = 0.15
    this.currentRotationY = -0.3
    
    // Auto-rotation
    this.autoRotate = false
    this.autoRotateSpeed = 0.0008
    
    // Objects in scene
    this.objects = []
    
    this.init()
    this.setupEventListeners()
  }
  
  init() {
    // Create scene
    this.scene = new THREE.Scene()
    this.scene.background = new THREE.Color(0x000000)
    
    // Create camera
    const aspect = this.container.clientWidth / this.container.clientHeight
    this.camera = new THREE.PerspectiveCamera(75, aspect, 0.1, 1000)
    this.camera.position.set(0, 0, 3.5)
    
    // Create renderer
    this.renderer = new THREE.WebGLRenderer({
      antialias: true,
      alpha: true
    })
    this.renderer.setSize(this.container.clientWidth, this.container.clientHeight)
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
    this.container.appendChild(this.renderer.domElement)
    
    // Create clock for time tracking
    this.clock = new THREE.Clock()
  }
  
  setupEventListeners() {
    // Mouse events
    this.renderer.domElement.addEventListener('mousedown', this.onMouseDown.bind(this))
    this.renderer.domElement.addEventListener('mousemove', this.onMouseMove.bind(this))
    this.renderer.domElement.addEventListener('mouseup', this.onMouseUp.bind(this))
    this.renderer.domElement.addEventListener('wheel', this.onWheel.bind(this), { passive: false })
    
    // Touch events
    this.renderer.domElement.addEventListener('touchstart', this.onTouchStart.bind(this), { passive: false })
    this.renderer.domElement.addEventListener('touchmove', this.onTouchMove.bind(this), { passive: false })
    this.renderer.domElement.addEventListener('touchend', this.onTouchEnd.bind(this))
    
    // Window resize
    window.addEventListener('resize', this.onWindowResize.bind(this))
    
    // Set cursor style
    this.renderer.domElement.style.cursor = 'grab'
  }
  
  onMouseDown(event) {
    this.isMouseDown = true
    this.mouseX = event.clientX
    this.mouseY = event.clientY
    this.renderer.domElement.style.cursor = 'grabbing'
  }
  
  onMouseMove(event) {
    if (!this.isMouseDown) return
    
    const deltaX = event.clientX - this.mouseX
    const deltaY = event.clientY - this.mouseY
    
    this.targetRotationY += deltaX * 0.01
    this.targetRotationX += deltaY * 0.01
    this.targetRotationX = Math.max(-Math.PI / 2, Math.min(Math.PI / 2, this.targetRotationX))
    
    this.mouseX = event.clientX
    this.mouseY = event.clientY
  }
  
  onMouseUp() {
    this.isMouseDown = false
    this.renderer.domElement.style.cursor = 'grab'
  }
  
  onWheel(event) {
    event.preventDefault()
    // Wheel is disabled as zoom is controlled via props
  }
  
  onTouchStart(event) {
    event.preventDefault()
    if (event.touches.length === 1) {
      this.isMouseDown = true
      this.mouseX = event.touches[0].clientX
      this.mouseY = event.touches[0].clientY
    }
  }
  
  onTouchMove(event) {
    event.preventDefault()
    if (!this.isMouseDown || event.touches.length !== 1) return
    
    const deltaX = event.touches[0].clientX - this.mouseX
    const deltaY = event.touches[0].clientY - this.mouseY
    
    this.targetRotationY += deltaX * 0.01
    this.targetRotationX += deltaY * 0.01
    this.targetRotationX = Math.max(-Math.PI / 2, Math.min(Math.PI / 2, this.targetRotationX))
    
    this.mouseX = event.touches[0].clientX
    this.mouseY = event.touches[0].clientY
  }
  
  onTouchEnd() {
    this.isMouseDown = false
  }
  
  onWindowResize() {
    if (!this.container) return
    
    this.camera.aspect = this.container.clientWidth / this.container.clientHeight
    this.camera.updateProjectionMatrix()
    this.renderer.setSize(this.container.clientWidth, this.container.clientHeight)
  }
  
  add(object) {
    this.scene.add(object)
    this.objects.push(object)
  }
  
  remove(object) {
    this.scene.remove(object)
    const index = this.objects.indexOf(object)
    if (index > -1) {
      this.objects.splice(index, 1)
    }
  }
  
  update() {
    // Smooth rotation interpolation
    this.currentRotationX += (this.targetRotationX - this.currentRotationX) * 0.1
    this.currentRotationY += (this.targetRotationY - this.currentRotationY) * 0.1
    
    // Auto-rotation when not interacting
    if (this.autoRotate && !this.isMouseDown) {
      this.targetRotationY += this.autoRotateSpeed
    }
    
    // Apply rotation to all objects
    this.objects.forEach(object => {
      if (object.rotation) {
        object.rotation.x = this.currentRotationX
        object.rotation.y = this.currentRotationY
      }
    })
  }
  
  render() {
    this.renderer.render(this.scene, this.camera)
  }
  
  getElapsedTime() {
    return this.clock.getElapsedTime()
  }
  
  getCameraDistance() {
    return this.camera.position.z
  }
  
  setCameraDistance(distance) {
    this.camera.position.z = distance
  }
  
  smoothZoomTo(targetDistance, duration = 500) {
    const startDistance = this.camera.position.z
    const startTime = performance.now()
    
    const animateZoom = (currentTime) => {
      const elapsed = currentTime - startTime
      const progress = Math.min(elapsed / duration, 1)
      
      // Ease-out cubic
      const easeProgress = 1 - Math.pow(1 - progress, 3)
      
      this.camera.position.z = startDistance + (targetDistance - startDistance) * easeProgress
      
      if (progress < 1) {
        requestAnimationFrame(animateZoom)
      }
    }
    
    requestAnimationFrame(animateZoom)
  }
  
  setAutoRotate(enabled, speed = 0.0008) {
    this.autoRotate = enabled
    this.autoRotateSpeed = speed
  }
  
  dispose() {
    // Remove event listeners
    this.renderer.domElement.removeEventListener('mousedown', this.onMouseDown.bind(this))
    this.renderer.domElement.removeEventListener('mousemove', this.onMouseMove.bind(this))
    this.renderer.domElement.removeEventListener('mouseup', this.onMouseUp.bind(this))
    this.renderer.domElement.removeEventListener('wheel', this.onWheel.bind(this))
    this.renderer.domElement.removeEventListener('touchstart', this.onTouchStart.bind(this))
    this.renderer.domElement.removeEventListener('touchmove', this.onTouchMove.bind(this))
    this.renderer.domElement.removeEventListener('touchend', this.onTouchEnd.bind(this))
    window.removeEventListener('resize', this.onWindowResize.bind(this))
    
    // Dispose renderer
    if (this.renderer) {
      this.renderer.dispose()
      this.renderer.forceContextLoss()
      if (this.container.contains(this.renderer.domElement)) {
        this.container.removeChild(this.renderer.domElement)
      }
    }
    
    // Clear scene
    if (this.scene) {
      this.scene.clear()
    }
    
    // Clear references
    this.scene = null
    this.camera = null
    this.renderer = null
    this.clock = null
    this.objects = []
  }
}