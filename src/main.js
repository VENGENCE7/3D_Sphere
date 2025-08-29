import { SceneManager } from './scene/SceneManager.js';
import { EclipseSphere } from './geometry/EclipseSphere.js';

class EclipseSphereLauncher {
    constructor() {
        this.sceneManager = null;
        this.eclipseSphere = null;
        this.animationId = null;
        
        this.init();
    }
    
    init() {
        // Initialize scene
        this.sceneManager = new SceneManager();
        
        // Create eclipse sphere with full interactivity
        this.eclipseSphere = new EclipseSphere(1.5);
        this.sceneManager.add(this.eclipseSphere.getMesh());
        
        // Start animation loop
        this.animate();
    }
    
    animate() {
        this.animationId = requestAnimationFrame(() => this.animate());
        
        // Get elapsed time
        const elapsedTime = this.sceneManager.getElapsedTime();
        
        // Get camera for distance calculation
        const camera = this.sceneManager.getCamera();
        
        // Update scene controls (important for zoom functionality)
        this.sceneManager.update();
        
        // Update eclipse sphere with time and camera
        this.eclipseSphere.update(elapsedTime, camera);
        
        // Render the scene
        this.sceneManager.render();
    }
    
    dispose() {
        if (this.animationId) {
            cancelAnimationFrame(this.animationId);
        }
        
        if (this.eclipseSphere) {
            this.eclipseSphere.dispose();
        }
        
        if (this.sceneManager) {
            this.sceneManager.dispose();
        }
    }
}

// Initialize the application
const app = new EclipseSphereLauncher();

// Export for potential external use
export default app;