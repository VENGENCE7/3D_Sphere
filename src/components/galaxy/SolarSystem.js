import * as THREE from 'three';
import { StarField } from './background/StarField.js';
import { SunBlob } from './sun/SunBlob.js';
import { OrbitManager } from './orbits/OrbitManager.js';
import { PlanetBlob } from './planets/PlanetBlob.js';
import { planetsConfig } from './planets/planetsConfig.js';

/**
 * SolarSystem Class
 * Main coordinator for all solar system components
 * Manages sun, planets, orbits, and background
 */
export class SolarSystem {
    constructor(scene, camera) {
        this.scene = scene;
        this.camera = camera;
        
        // Components
        this.starField = null;
        this.sun = null;
        this.orbitManager = null;
        this.planets = [];
        
        // Animation time
        this.time = 0;
        
        // Initialize the solar system
        this.init();
    }
    
    /**
     * Initialize all solar system components
     */
    init() {
        this.createStarField();
        this.createSun();
        this.createOrbits();
        this.createPlanets();
    }
    
    /**
     * Create the star field background
     */
    createStarField() {
        this.starField = new StarField(5000, 100);
        this.scene.add(this.starField.getMesh());
    }
    
    /**
     * Create the sun (using existing Blob/Eclipse sphere)
     */
    createSun() {
        this.sun = new SunBlob();
        this.scene.add(this.sun.getMesh());
    }
    
    /**
     * Create orbital paths
     */
    createOrbits() {
        this.orbitManager = new OrbitManager();
        
        // Add orbit groups to the scene (includes inclination transformations)
        this.orbitManager.getAllOrbits().forEach(orbit => {
            this.scene.add(orbit.getGroup());
        });
    }
    
    /**
     * Create all planets based on configuration
     */
    createPlanets() {
        planetsConfig.forEach(config => {
            // Create planet blob
            const planet = new PlanetBlob(config);
            
            // Store planet with its orbit info
            this.planets.push({
                planet: planet,
                orbitIndex: config.orbitIndex,
                angle: config.angle,
                config: config
            });
            
            // Add planet to scene
            this.scene.add(planet.getGroup());
        });
    }
    
    /**
     * Update all solar system components
     * @param {number} deltaTime - Time since last frame
     */
    update(deltaTime) {
        this.time += deltaTime;
        
        // Update star field (twinkling effect)
        if (this.starField) {
            this.starField.update(this.time);
        }
        
        // Update sun animation
        if (this.sun) {
            this.sun.update(this.time, this.camera);
        }
        
        // Update orbits
        if (this.orbitManager) {
            this.orbitManager.update();
        }
        
        // Update planets
        this.updatePlanets();
    }
    
    /**
     * Update planet positions and animations
     */
    updatePlanets() {
        this.planets.forEach(({ planet, orbitIndex, angle }) => {
            // Get the orbit
            const orbit = this.orbitManager.getOrbit(orbitIndex);
            if (!orbit) return;
            
            // Calculate planet position on its orbit
            const position = orbit.getPositionAtAngle(angle);
            
            // Update planet (position, animation, dynamic sizing)
            planet.update(this.time, position, this.camera);
        });
    }
    
    /**
     * Update Line2 resolution for orbit rendering
     * @param {number} width - Canvas width
     * @param {number} height - Canvas height
     */
    updateResolution(width, height) {
        if (this.orbitManager) {
            this.orbitManager.updateResolution(width, height);
        }
    }
    
    /**
     * Clean up resources
     */
    dispose() {
        // Dispose star field
        if (this.starField) {
            this.starField.dispose();
        }
        
        // Dispose sun
        if (this.sun) {
            this.sun.dispose();
        }
        
        // Dispose orbit manager
        if (this.orbitManager) {
            this.orbitManager.dispose();
        }
        
        // Dispose planets
        this.planets.forEach(({ planet }) => {
            planet.dispose();
        });
        
        this.planets = [];
    }
}