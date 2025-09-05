import { SceneManager } from './SceneManager.js';
import { SolarSystem } from './SolarSystem.js';

/**
 * GalaxyLauncher Class
 * Entry point for the Galaxy solar system visualization
 */
export class GalaxyLauncher {
    constructor(container) {
        this.container = container;
        this.sceneManager = null;
        this.solarSystem = null;
        this.animationId = null;
        
        this.init();
    }
    
    init() {
        // Initialize scene manager with zoom-only controls
        this.sceneManager = new SceneManager(this.container);
        
        // Create complete solar system
        this.solarSystem = new SolarSystem(
            this.sceneManager.scene,
            this.sceneManager.getCamera()
        );
        
        // Start animation loop
        this.animate();
    }
    
    animate() {
        this.animationId = requestAnimationFrame(() => this.animate());
        
        // Get delta time for animation
        const deltaTime = this.sceneManager.clock.getDelta();
        
        // Update scene (handles zoom)
        this.sceneManager.update();
        
        // Update solar system with all components
        this.solarSystem.update(deltaTime);
        
        // Render the scene
        this.sceneManager.render();
    }
    
    dispose() {
        // Stop animation
        if (this.animationId) {
            cancelAnimationFrame(this.animationId);
        }
        
        // Clean up solar system
        if (this.solarSystem) {
            this.solarSystem.dispose();
        }
        
        // Clean up scene manager
        if (this.sceneManager) {
            this.sceneManager.dispose();
        }
    }
}