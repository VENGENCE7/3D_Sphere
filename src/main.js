import { SceneManager } from './scene/SceneManager.js';
import { EclipseSphere } from './geometry/EclipseSphere.js';
import { InteractionControls } from './controls/InteractionControls.js';

class EclipseSphereLauncher {
    constructor() {
        this.sceneManager = null;
        this.eclipseSphere = null;
        this.controls = null;
        this.animationId = null;
        
        this.init();
    }
    
    init() {
        // Initialize scene
        this.sceneManager = new SceneManager();
        
        // Create eclipse sphere
        this.eclipseSphere = new EclipseSphere(1.5);
        this.sceneManager.add(this.eclipseSphere.getMesh());
        
        // Initialize controls
        this.controls = new InteractionControls(
            this.sceneManager.getCamera(),
            this.eclipseSphere.getMesh()
        );
        
        // Start animation loop
        this.animate();
    }
    
    animate() {
        this.animationId = requestAnimationFrame(() => this.animate());
        
        // Get elapsed time
        const elapsedTime = this.sceneManager.getElapsedTime();
        
        // Update eclipse sphere with time
        this.eclipseSphere.update(elapsedTime);
        
        // Update controls
        this.controls.update();
        
        // Render the scene
        this.sceneManager.render();
    }
    
    dispose() {
        if (this.animationId) {
            cancelAnimationFrame(this.animationId);
        }
        
        if (this.controls) {
            this.controls.dispose();
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