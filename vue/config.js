// WavesSphere Configuration
export const defaultConfig = {
  // Sphere settings
  radius: 1.5,                    // Sphere radius
  pointBaseSize: 6.0,             // Base size of points
  
  // Camera/Zoom settings
  defaultCameraDistance: 3.5,     // Default camera distance
  minZoom: 2.0,                   // Minimum zoom (closest)
  maxZoom: 15.0,                  // Maximum zoom (farthest)
  
  // Wave parameters (embedded in shaders)
  waveFrequency: 6.0,             // Ripple frequency within waves
  waveSpeed: 0.25,                // Wave expansion speed
  waveThickness: 0.5,             // Ring thickness
  waveAmplitude: 0.8,             // Base wave height
  waveMaxAmplitude: 2.2,          // Maximum height at clash point
  waveCycle: 4.0,                 // Wave repeat cycle in seconds
  
  // Visual settings
  backgroundColor: 0x000000,      // Scene background color
  sphereBackgroundColor: 0x141916 // Dark sphere background color
}

// Zoom presets for common use cases
export const zoomPresets = {
  far: 0,           // Fully zoomed out
  normal: 0.5,      // Default view
  close: 0.8,       // Close up
  veryClose: 1      // Maximum zoom in
}

// Animation keyframes for smooth zoom transitions
export const zoomAnimationPresets = {
  // Website intro animation
  intro: [
    { zoom: 0, duration: 0 },        // Start far
    { zoom: 0.3, duration: 2000 },   // Zoom in slowly
    { zoom: 0.6, duration: 1500 },   // Continue zooming
    { zoom: 0.5, duration: 1000 }    // Settle at normal
  ],
  
  // Pulse effect
  pulse: [
    { zoom: 0.5, duration: 0 },
    { zoom: 0.7, duration: 1000 },
    { zoom: 0.5, duration: 1000 }
  ],
  
  // Dramatic reveal
  reveal: [
    { zoom: 1, duration: 0 },        // Start very close
    { zoom: 0.3, duration: 2500 }    // Pull back dramatically
  ]
}

// Helper function to interpolate zoom values
export function interpolateZoom(from, to, progress) {
  // Use ease-in-out cubic for smooth transitions
  const eased = progress < 0.5
    ? 4 * progress * progress * progress
    : 1 - Math.pow(-2 * progress + 2, 3) / 2
  
  return from + (to - from) * eased
}

// Helper to create custom animation sequences
export function createZoomSequence(keyframes) {
  let totalDuration = 0
  const timeline = keyframes.map(frame => {
    const startTime = totalDuration
    totalDuration += frame.duration
    return {
      ...frame,
      startTime,
      endTime: totalDuration
    }
  })
  
  return {
    timeline,
    totalDuration,
    getZoomAtTime(time) {
      if (time <= 0) return timeline[0].zoom
      if (time >= totalDuration) return timeline[timeline.length - 1].zoom
      
      for (let i = 0; i < timeline.length - 1; i++) {
        const current = timeline[i]
        const next = timeline[i + 1]
        
        if (time >= current.startTime && time <= next.startTime) {
          const progress = (time - current.startTime) / (next.startTime - current.startTime)
          return interpolateZoom(current.zoom, next.zoom, progress)
        }
      }
      
      return timeline[timeline.length - 1].zoom
    }
  }
}