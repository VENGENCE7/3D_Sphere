export class InteractionControls {
    constructor(camera, sphereGroup) {
        this.camera = camera;
        this.sphere = sphereGroup; // This is now the group containing both spheres
        
        // Rotation state
        this.targetRotationX = 0.15;
        this.targetRotationY = -0.3;
        this.currentRotationX = 0.15;
        this.currentRotationY = -0.3;
        
        // Mouse/touch state
        this.isMouseDown = false;
        this.previousMouseX = 0;
        this.previousMouseY = 0;
        
        this.bindEvents();
    }
    
    bindEvents() {
        // Mouse events
        document.addEventListener('mousemove', this.onMouseMove.bind(this));
        document.addEventListener('mousedown', this.onMouseDown.bind(this));
        document.addEventListener('mouseup', this.onMouseUp.bind(this));
        
        // Touch events
        document.addEventListener('touchmove', this.onTouchMove.bind(this), { passive: false });
        document.addEventListener('touchstart', this.onTouchStart.bind(this));
        document.addEventListener('touchend', this.onTouchEnd.bind(this));
        
        // Zoom events
        document.addEventListener('wheel', this.onWheel.bind(this));
        
        // Window resize
        window.addEventListener('resize', this.onWindowResize.bind(this));
    }
    
    onMouseMove(event) {
        // Handle rotation when dragging
        if (this.isMouseDown) {
            const deltaX = event.clientX - this.previousMouseX;
            const deltaY = event.clientY - this.previousMouseY;
            
            this.targetRotationY += deltaX * 0.005;
            this.targetRotationX += deltaY * 0.005;
            
            this.targetRotationX = Math.max(-Math.PI / 2, Math.min(Math.PI / 2, this.targetRotationX));
        }
        
        this.previousMouseX = event.clientX;
        this.previousMouseY = event.clientY;
    }
    
    onMouseDown(event) {
        this.isMouseDown = true;
        this.previousMouseX = event.clientX;
        this.previousMouseY = event.clientY;
    }
    
    onMouseUp() {
        this.isMouseDown = false;
    }
    
    onTouchMove(event) {
        if (event.touches.length === 1) {
            event.preventDefault();
            const touch = event.touches[0];
            const deltaX = touch.clientX - this.previousMouseX;
            const deltaY = touch.clientY - this.previousMouseY;
            
            if (this.previousMouseX !== 0 && this.previousMouseY !== 0) {
                this.targetRotationY += deltaX * 0.005;
                this.targetRotationX += deltaY * 0.005;
                this.targetRotationX = Math.max(-Math.PI / 2, Math.min(Math.PI / 2, this.targetRotationX));
            }
            
            this.previousMouseX = touch.clientX;
            this.previousMouseY = touch.clientY;
        }
    }
    
    onTouchStart(event) {
        if (event.touches.length === 1) {
            const touch = event.touches[0];
            this.previousMouseX = touch.clientX;
            this.previousMouseY = touch.clientY;
        }
    }
    
    onTouchEnd() {
        this.previousMouseX = 0;
        this.previousMouseY = 0;
    }
    
    onWheel(event) {
        this.camera.position.z += event.deltaY * 0.002;
        // Allow zooming out much further (was max 5, now 15)
        // Min 2 for close-up, Max 15 for far view
        this.camera.position.z = Math.max(2, Math.min(15, this.camera.position.z));
    }
    
    onWindowResize() {
        this.camera.aspect = window.innerWidth / window.innerHeight;
        this.camera.updateProjectionMatrix();
    }
    
    update() {
        // Smooth rotation interpolation
        this.currentRotationX += (this.targetRotationX - this.currentRotationX) * 0.1;
        this.currentRotationY += (this.targetRotationY - this.currentRotationY) * 0.1;
        
        // Auto-rotation when not interacting (optional - can be disabled)
        if (!this.isMouseDown) {
            this.targetRotationY += 0.0008;
        }
        
        // Apply rotation to sphere
        if (this.sphere) {
            this.sphere.rotation.x = this.currentRotationX;
            this.sphere.rotation.y = this.currentRotationY;
        }
    }
    
    dispose() {
        // Remove event listeners
        document.removeEventListener('mousemove', this.onMouseMove.bind(this));
        document.removeEventListener('mousedown', this.onMouseDown.bind(this));
        document.removeEventListener('mouseup', this.onMouseUp.bind(this));
        document.removeEventListener('touchmove', this.onTouchMove.bind(this));
        document.removeEventListener('touchstart', this.onTouchStart.bind(this));
        document.removeEventListener('touchend', this.onTouchEnd.bind(this));
        document.removeEventListener('wheel', this.onWheel.bind(this));
        window.removeEventListener('resize', this.onWindowResize.bind(this));
    }
}