/**
 * WavesSphere React Component
 * Example integration for React applications
 */

import React, { useEffect, useRef, useState } from 'react';

// Import WavesSphere (adjust path as needed)
// Option 1: If using as ES6 module
// import WavesSphere from '../src/components/WavesSphere';

// Option 2: If using the bundle (make sure it's loaded globally)
// const WavesSphere = window.WavesSphere;

const WavesSphereComponent = ({
    className = '',
    style = {},
    config = {},
    onInit = null,
    onDestroy = null,
    autoStart = true,
    ...props
}) => {
    const containerRef = useRef(null);
    const sphereRef = useRef(null);
    const [isLoaded, setIsLoaded] = useState(false);
    const [isRunning, setIsRunning] = useState(false);
    const [error, setError] = useState(null);
    
    // Initialize sphere
    useEffect(() => {
        if (!containerRef.current) return;
        
        try {
            // Create sphere instance
            const sphere = new WavesSphere(containerRef.current, {
                width: containerRef.current.clientWidth,
                height: containerRef.current.clientHeight,
                ...config
            });
            
            sphereRef.current = sphere;
            setIsLoaded(true);
            setError(null);
            
            // Start automatically if configured
            if (autoStart) {
                sphere.start();
                setIsRunning(true);
            }
            
            // Callback
            if (onInit) {
                onInit(sphere);
            }
            
        } catch (err) {
            console.error('WavesSphere initialization failed:', err);
            setError(err.message);
        }
        
        // Cleanup function
        return () => {
            if (sphereRef.current) {
                sphereRef.current.destroy();
                if (onDestroy) {
                    onDestroy();
                }
                sphereRef.current = null;
                setIsLoaded(false);
                setIsRunning(false);
            }
        };
    }, [config, autoStart, onInit, onDestroy]);
    
    // Handle container resize
    useEffect(() => {
        const handleResize = () => {
            if (sphereRef.current) {
                sphereRef.current.onWindowResize();
            }
        };
        
        window.addEventListener('resize', handleResize);
        return () => window.removeEventListener('resize', handleResize);
    }, []);
    
    // Control methods
    const start = () => {
        if (sphereRef.current) {
            sphereRef.current.start();
            setIsRunning(true);
        }
    };
    
    const stop = () => {
        if (sphereRef.current) {
            sphereRef.current.stop();
            setIsRunning(false);
        }
    };
    
    const zoomIn = (factor, smooth = true) => {
        if (sphereRef.current) {
            sphereRef.current.zoomIn(factor, smooth);
        }
    };
    
    const zoomOut = (factor, smooth = true) => {
        if (sphereRef.current) {
            sphereRef.current.zoomOut(factor, smooth);
        }
    };
    
    const resetZoom = (smooth = true) => {
        if (sphereRef.current) {
            sphereRef.current.resetZoom(smooth);
        }
    };
    
    const updateConfig = (newConfig) => {
        if (sphereRef.current) {
            sphereRef.current.updateConfig(newConfig);
        }
    };
    
    // Expose methods through ref
    React.useImperativeHandle(props.ref, () => ({
        start,
        stop,
        zoomIn,
        zoomOut,
        resetZoom,
        updateConfig,
        getInstance: () => sphereRef.current,
        isLoaded,
        isRunning
    }));
    
    const containerStyle = {
        width: '100%',
        height: '100%',
        ...style
    };
    
    return (
        <div className={className} style={containerStyle}>
            <div 
                ref={containerRef} 
                style={{ width: '100%', height: '100%' }}
                {...props}
            />
            {error && (
                <div style={{
                    position: 'absolute',
                    top: '50%',
                    left: '50%',
                    transform: 'translate(-50%, -50%)',
                    background: 'rgba(255, 0, 0, 0.8)',
                    color: 'white',
                    padding: '20px',
                    borderRadius: '10px',
                    textAlign: 'center'
                }}>
                    Error: {error}
                </div>
            )}
        </div>
    );
};

// Example usage component
const WavesSphereExample = () => {
    const sphereRef = useRef(null);
    const [config, setConfig] = useState({
        autoRotate: true,
        autoRotateSpeed: 0.001,
        cameraDistance: 4.0
    });
    
    const handleConfigChange = (key, value) => {
        const newConfig = { ...config, [key]: value };
        setConfig(newConfig);
        
        // Update sphere config if loaded
        if (sphereRef.current) {
            sphereRef.current.updateConfig({ [key]: value });
        }
    };
    
    const handleInit = (sphere) => {
        console.log('Sphere initialized:', sphere);
    };
    
    const handleDestroy = () => {
        console.log('Sphere destroyed');
    };
    
    return (
        <div style={{ width: '100vw', height: '100vh', position: 'relative' }}>
            <WavesSphereComponent
                ref={sphereRef}
                config={config}
                onInit={handleInit}
                onDestroy={handleDestroy}
                autoStart={true}
                style={{ background: '#000' }}
            />
            
            {/* Controls */}
            <div style={{
                position: 'absolute',
                top: '20px',
                left: '20px',
                background: 'rgba(0, 0, 0, 0.8)',
                padding: '20px',
                borderRadius: '10px',
                color: 'white'
            }}>
                <h3 style={{ margin: '0 0 15px 0', color: '#FFE566' }}>Controls</h3>
                
                <div style={{ marginBottom: '10px' }}>
                    <button 
                        onClick={() => sphereRef.current?.start()}
                        style={{ marginRight: '10px', padding: '5px 10px' }}
                    >
                        Start
                    </button>
                    <button 
                        onClick={() => sphereRef.current?.stop()}
                        style={{ marginRight: '10px', padding: '5px 10px' }}
                    >
                        Stop
                    </button>
                </div>
                
                <div style={{ marginBottom: '10px' }}>
                    <button 
                        onClick={() => sphereRef.current?.zoomIn()}
                        style={{ marginRight: '10px', padding: '5px 10px' }}
                    >
                        Zoom In
                    </button>
                    <button 
                        onClick={() => sphereRef.current?.zoomOut()}
                        style={{ marginRight: '10px', padding: '5px 10px' }}
                    >
                        Zoom Out
                    </button>
                    <button 
                        onClick={() => sphereRef.current?.resetZoom()}
                        style={{ padding: '5px 10px' }}
                    >
                        Reset
                    </button>
                </div>
                
                <div style={{ marginBottom: '10px' }}>
                    <label style={{ display: 'block', marginBottom: '5px' }}>
                        Auto Rotate: 
                        <input
                            type="checkbox"
                            checked={config.autoRotate}
                            onChange={(e) => handleConfigChange('autoRotate', e.target.checked)}
                            style={{ marginLeft: '10px' }}
                        />
                    </label>
                </div>
                
                <div style={{ marginBottom: '10px' }}>
                    <label style={{ display: 'block', marginBottom: '5px' }}>
                        Rotate Speed: {config.autoRotateSpeed}
                        <input
                            type="range"
                            min="0.0001"
                            max="0.005"
                            step="0.0001"
                            value={config.autoRotateSpeed}
                            onChange={(e) => handleConfigChange('autoRotateSpeed', parseFloat(e.target.value))}
                            style={{ display: 'block', width: '150px', marginTop: '5px' }}
                        />
                    </label>
                </div>
            </div>
        </div>
    );
};

export default WavesSphereComponent;
export { WavesSphereExample };