import './style.css';
import * as THREE from 'three';

// Perlin noise implementation for vertex displacement
const noise3D = `
  // Perlin 3D noise implementation
  vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
  }
  
  vec4 mod289(vec4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
  }
  
  vec4 permute(vec4 x) {
    return mod289(((x * 34.0) + 1.0) * x);
  }
  
  vec4 taylorInvSqrt(vec4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
  }
  
  float snoise(vec3 v) {
    const vec2 C = vec2(1.0/6.0, 1.0/3.0);
    const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
    
    vec3 i = floor(v + dot(v, C.yyy));
    vec3 x0 = v - i + dot(i, C.xxx);
    
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min(g.xyz, l.zxy);
    vec3 i2 = max(g.xyz, l.zxy);
    
    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy;
    vec3 x3 = x0 - D.yyy;
    
    i = mod289(i);
    vec4 p = permute(permute(permute(
        i.z + vec4(0.0, i1.z, i2.z, 1.0))
        + i.y + vec4(0.0, i1.y, i2.y, 1.0))
        + i.x + vec4(0.0, i1.x, i2.x, 1.0));
    
    float n_ = 0.142857142857;
    vec3 ns = n_ * D.wyz - D.xzx;
    
    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
    
    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_);
    
    vec4 x = x_ * ns.x + ns.yyyy;
    vec4 y = y_ * ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);
    
    vec4 b0 = vec4(x.xy, y.xy);
    vec4 b1 = vec4(x.zw, y.zw);
    
    vec4 s0 = floor(b0) * 2.0 + 1.0;
    vec4 s1 = floor(b1) * 2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));
    
    vec4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    vec4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
    
    vec3 p0 = vec3(a0.xy, h.x);
    vec3 p1 = vec3(a0.zw, h.y);
    vec3 p2 = vec3(a1.xy, h.z);
    vec3 p3 = vec3(a1.zw, h.w);
    
    vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2,p2), dot(p3,p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;
    
    vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    m = m * m;
    return 42.0 * dot(m*m, vec4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
  }
`;

// Vertex shader with displacement and fiber patterns
const vertexShader = `
  ${noise3D}
  
  attribute vec3 initialPosition;
  attribute vec3 initialNormal;
  attribute float aRandom;
  attribute vec2 aUv;
  
  varying vec3 vColor;
  varying vec3 vNormal;
  varying vec3 vPosition;
  varying float vDisplacement;
  varying float vPattern;
  varying vec2 vUv;
  varying vec3 vViewPosition;
  varying float vFacingRatio;
  
  uniform float uTime;
  uniform float uDisplacementStrength;
  uniform float uNoiseScale;
  uniform float uWaveSpeed;
  uniform vec3 uCameraPosition;
  
  // PRECISE FRACTAL NOISE IMPLEMENTATION - 4 octaves with specified parameters
  float fractalNoise(vec3 p) {
    float value = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;  // Base frequency: 1.0
    float maxValue = 0.0;
    
    // Exactly 4 octaves of noise
    for(int i = 0; i < 4; i++) {
      value += amplitude * snoise(p * frequency);
      maxValue += amplitude;
      
      // Frequency multiplier: 2.0 per octave
      frequency *= 2.0;
      
      // Amplitude decay: 0.5 per octave
      amplitude *= 0.5;
    }
    
    return value / maxValue;
  }
  
  // COSMIC RIPPLE PATTERN GENERATOR - Creates flowing surface waves
  float cosmicRipples(vec3 p, float t) {
    // Multiple wave layers for cosmic energy feel
    float angle = atan(p.z, p.x);
    float dist = length(vec2(p.x, p.z));
    float height = p.y;
    
    // Primary cosmic waves - slow and large
    float wave1 = sin(angle * 3.0 + t * 0.8) * cos(height * 4.0 + t * 0.6);
    float wave2 = cos(angle * 2.0 - t * 0.5) * sin(dist * 3.0 + t * 0.7);
    
    // Secondary ripples - medium frequency
    float ripple1 = sin(angle * 6.0 + dist * 5.0 - t * 1.2);
    float ripple2 = cos(angle * 4.0 - height * 6.0 + t * 0.9);
    float ripple3 = sin(dist * 7.0 + angle * 5.0 - t * 1.1);
    
    // Fine surface texture - high frequency, low amplitude
    float texture1 = sin(angle * 12.0 + dist * 10.0 - t * 2.0) * 0.3;
    float texture2 = cos(height * 15.0 + angle * 8.0 + t * 1.8) * 0.2;
    
    // Flowing energy patterns
    float energy1 = sin(dist * 4.0 + angle * 3.0 - t * 0.4) * cos(height * 3.0);
    float energy2 = cos(dist * 6.0 - angle * 4.0 + t * 0.6) * sin(height * 5.0);
    
    // Combine all layers with different weights for cosmic effect
    float cosmicPattern = wave1 * 0.4 + wave2 * 0.3 + 
                         ripple1 * 0.15 + ripple2 * 0.12 + ripple3 * 0.10 +
                         texture1 * 0.08 + texture2 * 0.06 +
                         energy1 * 0.20 + energy2 * 0.15;
    
    return cosmicPattern;
  }
  
  // INTRICATE BLACK PATTERN GENERATOR - Creates complex void regions
  float blackPattern(vec3 p, float vortex, float t) {
    float angle = atan(p.z, p.x);
    float dist = length(vec2(p.x, p.z));
    
    // Large swirling black voids
    float void1 = sin(angle * 3.0 + vortex * 4.0 - t) * cos(dist * 6.0);
    float void2 = cos(angle * 5.0 - vortex * 3.0 + t * 0.7) * sin(p.y * 4.0);
    float void3 = sin(dist * 8.0 + angle * 2.0 - t * 0.5);
    
    // Combine voids for intricate patterns
    float blackIntensity = abs(void1 * void2) + abs(void3) * 0.3;
    
    // Add pulsing effect to black regions
    blackIntensity *= (1.0 + sin(t * 2.0) * 0.2);
    
    return blackIntensity;
  }
  
  // Organic flow with fractal noise (keeping for additional detail)
  float organicDistortion(vec3 p, float time) {
    vec3 noiseCoord = p + vec3(time * 0.1, time * 0.15, time * 0.08);
    float baseNoise = fractalNoise(noiseCoord);
    vec3 offsetCoord = p + vec3(time * 0.12, -time * 0.09, time * 0.11);
    float secondaryNoise = fractalNoise(offsetCoord * 1.3);
    return baseNoise * 0.7 + secondaryNoise * 0.3;
  }
  
  void main() {
    vec3 pos = initialPosition;
    vec3 norm = initialNormal;
    
    // Calculate time and positions
    float time = uTime * 0.5; // Slower for smoother animation
    vec3 noisePos = pos * uNoiseScale;
    
    // Create cosmic ripple pattern for flowing surface waves
    float cosmicWaves = cosmicRipples(pos, time);
    
    // Combine cosmic waves with organic noise for complex displacement
    float noiseValue = organicDistortion(noisePos, time);
    float combinedPattern = cosmicWaves * 0.8 + noiseValue * 0.2;
    
    // Create undulating displacement (max 0.15 units for subtlety)
    float displacement = combinedPattern * 0.15 * (1.0 + sin(time * 1.5) * 0.2);
    
    // Apply displacement along normals
    vec3 displacedPos = pos + norm * displacement;
    
    // Generate intricate black patterns using cosmic waves
    float blackInt = blackPattern(pos, cosmicWaves, time);
    
    // Recalculate normals for accurate lighting
    float epsilon = 0.01;
    vec3 tangent1 = normalize(cross(norm, vec3(1.0, 0.0, 0.0)));
    vec3 tangent2 = normalize(cross(norm, tangent1));
    
    vec3 neighbor1 = pos + tangent1 * epsilon;
    vec3 neighbor2 = pos + tangent2 * epsilon;
    
    float disp1 = (cosmicRipples(neighbor1, time) * 0.8 + organicDistortion(neighbor1 * uNoiseScale, time) * 0.2) * 0.15;
    float disp2 = (cosmicRipples(neighbor2, time) * 0.8 + organicDistortion(neighbor2 * uNoiseScale, time) * 0.2) * 0.15;
    
    neighbor1 = neighbor1 + norm * disp1;
    neighbor2 = neighbor2 + norm * disp2;
    
    vec3 newNormal = normalize(cross(neighbor2 - displacedPos, neighbor1 - displacedPos));
    
    vNormal = normalMatrix * newNormal;
    vPosition = displacedPos;
    vDisplacement = displacement;
    vPattern = cosmicWaves; // Store cosmic wave pattern for effects
    vUv = aUv;
    
    // Calculate view-dependent properties
    vec3 viewDir = normalize(uCameraPosition - displacedPos);
    vViewPosition = (modelViewMatrix * vec4(displacedPos, 1.0)).xyz;
    
    // Calculate how much the vertex faces the camera (1 = facing, -1 = away)
    vFacingRatio = dot(newNormal, viewDir);
    
    // Color gradient based on displacement and position
    float distanceFromCenter = length(displacedPos) / 15.0;
    float normalizedDisp = (displacement + uDisplacementStrength) / (2.0 * uDisplacementStrength);
    
    // ECLIPSE SURFACE COLOR GRADIENT - Based on local surface lighting and displacement
    vec3 pureBlack = vec3(0.0, 0.0, 0.0);                    // #000000 - Pure Black (shadows)
    vec3 deepViolet = vec3(0.149, 0.0, 0.349);               // #260059 - Deep Violet
    vec3 purple = vec3(0.502, 0.0, 1.0);                     // #8000FF - Bright Purple
    vec3 magenta = vec3(1.0, 0.102, 0.502);                  // #FF1A80 - Magenta/Pink
    vec3 orange = vec3(1.0, 0.333, 0.0);                     // #FF5500 - Orange
    vec3 brightYellow = vec3(1.0, 1.0, 0.2);                 // #FFFF33 - Bright Golden Yellow
    
    // Calculate eclipse lighting position (dynamic light source)
    vec3 eclipseLightPos = vec3(sin(time * 0.3) * 2.0, cos(time * 0.2) * 2.0, 3.0);
    vec3 lightDir = normalize(eclipseLightPos - displacedPos);
    
    // Surface normal based lighting with displacement influence
    float surfaceLighting = dot(newNormal, lightDir);
    
    // Create surface ripple intensity for gradient mapping
    float rippleIntensity = abs(displacement) + abs(cosmicWaves * 0.4);
    
    // Combine lighting with surface features for eclipse effect
    float surfaceGradient = surfaceLighting * 0.4 + rippleIntensity * 0.6;
    surfaceGradient = clamp(surfaceGradient + 0.2, 0.0, 1.0);
    
    // Add subtle surface curvature influence for eclipse feel
    vec3 viewToPos = normalize(displacedPos - uCameraPosition);
    float curvatureInfluence = 1.0 - abs(dot(newNormal, viewToPos));
    surfaceGradient += curvatureInfluence * 0.1;
    
    // Create eclipse shadow regions
    float eclipseAngle = atan(displacedPos.x, displacedPos.z) + time * 0.1;
    float eclipseShadow = sin(eclipseAngle * 2.0) * cos(displacedPos.y * 0.8) * 0.3;
    surfaceGradient += eclipseShadow;
    surfaceGradient = clamp(surfaceGradient, 0.0, 1.0);
    
    vec3 color;
    
    // SURFACE-BASED COLOR DISTRIBUTION (Eclipse Effect)
    if (surfaceGradient < 0.15) {
      // Deep shadows: Pure black → Deep violet
      float t = surfaceGradient / 0.15;
      color = mix(pureBlack, deepViolet, smoothstep(0.0, 1.0, t));
      
    } else if (surfaceGradient < 0.30) {
      // Shadow transition: Deep violet → Purple
      float t = (surfaceGradient - 0.15) / 0.15;
      color = mix(deepViolet, purple, smoothstep(0.0, 1.0, t));
      
    } else if (surfaceGradient < 0.50) {
      // Mid-tone: Purple → Magenta
      float t = (surfaceGradient - 0.30) / 0.20;
      color = mix(purple, magenta, smoothstep(0.0, 1.0, t));
      
    } else if (surfaceGradient < 0.75) {
      // Bright areas: Magenta → Orange
      float t = (surfaceGradient - 0.50) / 0.25;
      vec3 hotPink = vec3(1.0, 0.0, 0.4);
      vec3 red = vec3(1.0, 0.0, 0.0);
      if (t < 0.5) {
        color = mix(magenta, hotPink, t * 2.0);
      } else {
        color = mix(red, orange, (t - 0.5) * 2.0);
      }
      
    } else if (surfaceGradient < 0.92) {
      // High intensity: Orange gradients
      float t = (surfaceGradient - 0.75) / 0.17;
      vec3 brightOrange = vec3(1.0, 0.6, 0.0);
      color = mix(orange, brightOrange, t);
      
    } else {
      // Extreme highlights: Yellow (only 5-8% of surface)
      float t = (surfaceGradient - 0.92) / 0.08;
      vec3 yellowOrange = vec3(1.0, 0.8, 0.0);
      if (t < 0.6) {
        color = mix(orange, yellowOrange, t / 0.6);
      } else {
        color = mix(yellowOrange, brightYellow, (t - 0.6) / 0.4);
      }
      // Enhanced glow for yellow highlights
      color *= (1.0 + t * 0.4);
    }
    
    // Apply large intricate black patterns
    if (blackInt > 0.45) {
      float blackMix = smoothstep(0.45, 0.8, blackInt);
      color = mix(color, pureBlack, blackMix);
    }
    
    // Additional flowing black voids for depth using cosmic patterns
    float flowingVoid = sin(displacedPos.x * 10.0 + cosmicWaves * 5.0 - time * 2.0) * 
                       cos(displacedPos.y * 8.0 - time) * 
                       sin(displacedPos.z * 6.0 + time * 1.5);
    if (abs(flowingVoid) > 0.6) {
      float voidIntensity = smoothstep(0.6, 0.9, abs(flowingVoid));
      color = mix(color, pureBlack, voidIntensity * 0.8);
    }
    
    // Enhanced dynamic lighting for depth and eclipse effect
    vec3 eclipseLightMain = vec3(sin(time * 0.2) * 3.0, cos(time * 0.15) * 2.0, 4.0);
    vec3 rimLight1 = vec3(sin(time * 0.3), cos(time * 0.25), -2.0);
    vec3 rimLight2 = vec3(cos(time * 0.35), sin(time * 0.28), 2.0);
    
    // Main eclipse lighting with surface normal interaction
    float mainLight = max(0.0, dot(newNormal, normalize(eclipseLightMain - displacedPos)));
    
    // Rim lighting for edge definition
    float rim1 = max(0.0, dot(newNormal, normalize(rimLight1 - displacedPos)));
    float rim2 = max(0.0, dot(newNormal, normalize(rimLight2 - displacedPos)));
    
    // Shadow casting based on surface displacement
    float shadowDepth = smoothstep(-0.1, 0.1, displacement);
    float lightingIntensity = mainLight * 0.6 + rim1 * 0.2 + rim2 * 0.15;
    lightingIntensity *= shadowDepth;
    
    // Apply enhanced lighting with shadow depth
    color *= (0.4 + lightingIntensity * 0.7);
    
    // Enhanced ethereal glow based on surface features
    float surfaceEdgeGlow = pow(surfaceGradient, 1.5);
    if (length(color) > 0.1 && surfaceGradient > 0.6) {
      // Add glow to bright surface areas
      color += color * surfaceEdgeGlow * 0.3;
      
      // Add subtle white highlights to extreme surface features
      if (surfaceGradient > 0.85) {
        color += vec3(0.2, 0.15, 0.1) * pow(surfaceGradient, 3.0);
      }
    }
    
    // Cosmic pulsing effect
    float pulse = sin(time * 3.0 + cosmicWaves * 2.0) * 0.5 + 0.5;
    color *= (0.8 + pulse * 0.2);
    
    // Enhanced view-dependent eclipse shading
    float facingIntensity = smoothstep(-0.4, 0.6, vFacingRatio);
    float eclipseShading = smoothstep(-0.8, 0.2, vFacingRatio);
    
    // Create strong eclipse shadow effect on back-facing areas
    if (vFacingRatio < -0.2) {
      // Deep eclipse shadow - very dark with subtle violet tinge
      color *= 0.05 + eclipseShading * 0.15;
      color = mix(color, deepViolet * 0.3, 0.4); // Add violet tinge to shadows
    } else if (vFacingRatio < 0.0) {
      // Eclipse transition zone
      color *= 0.2 + facingIntensity * 0.3;
      color = mix(color, deepViolet * 0.6, 0.2);
    } else {
      // Illuminated front areas with enhanced brightness
      color *= 0.6 + facingIntensity * 0.5;
    }
    
    vColor = color;
    
    gl_Position = projectionMatrix * modelViewMatrix * vec4(displacedPos, 1.0);
    
    // Dynamic dot sizing for fluid cosmic wave effect - optimized for high density
    float baseSize = 1.3;
    
    // Vary size based on cosmic wave pattern and position
    float patternSize = 1.0 + abs(cosmicWaves) * 0.2;
    float depthSize = 1.0 + (1.0 - distanceFromCenter) * 0.2;
    float randomSize = 0.8 + aRandom * 0.4;
    
    // Smaller dots in black areas for contrast
    if (length(color) < 0.1) {
      patternSize *= 0.5;
    }
    
    gl_PointSize = baseSize * patternSize * depthSize * randomSize * (300.0 / length((modelViewMatrix * vec4(displacedPos, 1.0)).xyz));
    gl_PointSize = min(gl_PointSize, 6.0);
  }
`;

// Fragment shader with volumetric dot rendering
const fragmentShader = `
  precision highp float;
  
  varying vec3 vColor;
  varying vec3 vNormal;
  varying vec3 vPosition;
  varying float vDisplacement;
  varying float vPattern;
  varying vec2 vUv;
  varying vec3 vViewPosition;
  varying float vFacingRatio;
  
  uniform float uTime;
  uniform vec3 uLightPosition;
  uniform float uRoughness;
  uniform float uMetalness;
  uniform vec3 uCameraPosition;
  
  // PBR lighting calculations
  vec3 calculatePBR(vec3 color, vec3 normal, vec3 viewDir, vec3 lightDir) {
    vec3 halfVector = normalize(viewDir + lightDir);
    float NdotL = max(dot(normal, lightDir), 0.0);
    float NdotV = max(dot(normal, viewDir), 0.0);
    float NdotH = max(dot(normal, halfVector), 0.0);
    float VdotH = max(dot(viewDir, halfVector), 0.0);
    
    // Fresnel
    vec3 F0 = mix(vec3(0.04), color, uMetalness);
    vec3 F = F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);
    
    // Distribution (GGX)
    float alpha = uRoughness * uRoughness;
    float alpha2 = alpha * alpha;
    float denom = NdotH * NdotH * (alpha2 - 1.0) + 1.0;
    float D = alpha2 / (3.14159 * denom * denom);
    
    // Geometry
    float k = (uRoughness + 1.0) * (uRoughness + 1.0) / 8.0;
    float G1L = NdotL / (NdotL * (1.0 - k) + k);
    float G1V = NdotV / (NdotV * (1.0 - k) + k);
    float G = G1L * G1V;
    
    // BRDF
    vec3 numerator = D * G * F;
    float denominator = 4.0 * NdotV * NdotL + 0.001;
    vec3 specular = numerator / denominator;
    
    vec3 kS = F;
    vec3 kD = vec3(1.0) - kS;
    kD *= 1.0 - uMetalness;
    
    return (kD * color / 3.14159 + specular) * NdotL;
  }
  
  void main() {
    // Create circular dots with glow
    vec2 center = gl_PointCoord - vec2(0.5);
    float dist = length(center);
    
    if (dist > 0.5) discard;
    
    // Smooth antialiased edge with enhanced glow
    float alpha = smoothstep(0.5, 0.3, dist);
    
    // Get dot color
    vec3 dotColor = vColor;
    
    // Enhanced front-facing glow and back-facing darkening
    float viewDepth = length(vViewPosition);
    float depthFade = 1.0 / (1.0 + viewDepth * 0.01);
    
    // Radiant glow for non-black dots
    if (length(vColor) > 0.1 && vFacingRatio > -0.2) {
      // Only apply glow to front-facing dots
      float frontBoost = smoothstep(-0.2, 0.8, vFacingRatio);
      
      // Center glow - more intense for front-facing
      float centerGlow = 1.0 - dist * 1.2;
      centerGlow = pow(max(centerGlow, 0.0), 1.5);
      dotColor += vColor * centerGlow * 0.5 * frontBoost;
      
      // Outer soft glow
      float outerGlow = smoothstep(0.5, 0.0, dist);
      float edgeDistance = length(vPosition) / 15.0;
      dotColor += vColor * outerGlow * pow(edgeDistance, 2.0) * 0.2 * frontBoost;
      
      // Add subtle white highlight in center for brightness
      float highlight = pow(max(1.0 - dist * 2.0, 0.0), 3.0);
      dotColor += vec3(1.0, 1.0, 1.0) * highlight * 0.15 * frontBoost;
      
      // Create 3D sphere-like appearance
      float depth = sqrt(max(1.0 - dist * dist, 0.0));
      vec3 dotNormal = normalize(vec3(center * 2.0, depth));
      
      // Front-facing directional lighting
      vec3 viewDir = normalize(-vViewPosition);
      vec3 lightDir = normalize(vec3(viewDir.x * 0.5, 0.7, viewDir.z * 0.5 + 1.0));
      float diffuse = max(dot(dotNormal, lightDir), 0.0);
      dotColor *= (0.6 + diffuse * 0.4 * frontBoost);
      
      // Boost colors for front-facing dots
      dotColor *= (1.0 + frontBoost * 0.5);
    }
    
    // Darken back-facing dots significantly
    if (vFacingRatio < 0.0) {
      float backDarkening = smoothstep(0.0, -0.5, vFacingRatio);
      dotColor *= (0.05 + (1.0 - backDarkening) * 0.15);
    }
    
    // Enhance contrast for black dots
    if (length(vColor) < 0.1) {
      alpha *= 0.8; // Slightly transparent black dots for depth
    }
    
    // Pattern-based intensity variation
    float patternIntensity = 0.9 + abs(sin(vPattern * 6.0 + uTime)) * 0.1;
    dotColor *= patternIntensity;
    
    gl_FragColor = vec4(dotColor, alpha);
  }
`;

class AnimatedDisplacedSphere {
  private scene: THREE.Scene;
  private camera: THREE.PerspectiveCamera;
  private renderer: THREE.WebGLRenderer;
  private sphere: THREE.Points;
  private material: THREE.ShaderMaterial;
  private clock: THREE.Clock;
  private controls: any; // OrbitControls type
  private mouse: THREE.Vector2;
  private targetRotation: THREE.Vector2;
  
  // Animation parameters
  private animationParams = {
    displacementStrength: 2.5,
    noiseScale: 0.8,
    waveSpeed: 0.4,
    roughness: 0.6,
    metalness: 0.1
  };

  constructor() {
    this.clock = new THREE.Clock();
    this.mouse = new THREE.Vector2(0, 0);
    this.targetRotation = new THREE.Vector2(0, 0);
    this.initThree();
    this.createDisplacedSphere();
    this.setupLighting();
    this.setupControls();
    this.setupEventListeners();
    this.animate();
  }

  private initThree(): void {
    // Scene setup
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0x000000);
    this.scene.fog = new THREE.Fog(0x000000, 50, 200);
    
    // Camera setup
    this.camera = new THREE.PerspectiveCamera(
      75,
      window.innerWidth / window.innerHeight,
      0.1,
      1000
    );
    this.camera.position.set(0, 0, 45);
    
    // Renderer setup with shadows
    this.renderer = new THREE.WebGLRenderer({ 
      canvas: document.getElementById('bg') as HTMLCanvasElement,
      antialias: true,
      alpha: true
    });
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;
  }

  private createDisplacedSphere(): void {
    // Create high subdivision icosahedron with maximum density
    const geometry = new THREE.IcosahedronGeometry(15, 12); // Maximum dot density with very high subdivision
    const vertices = geometry.attributes.position.array as Float32Array;
    const normals = geometry.attributes.normal.array as Float32Array;
    const uvs = geometry.attributes.uv.array as Float32Array;
    
    // Store initial positions and normals
    const initialPositions = new Float32Array(vertices.length);
    const initialNormals = new Float32Array(normals.length);
    const randoms = new Float32Array(vertices.length / 3);
    const aUvs = new Float32Array(uvs.length);
    
    for (let i = 0; i < vertices.length; i++) {
      initialPositions[i] = vertices[i];
      initialNormals[i] = normals[i];
    }
    
    for (let i = 0; i < uvs.length; i++) {
      aUvs[i] = uvs[i];
    }
    
    for (let i = 0; i < randoms.length; i++) {
      randoms[i] = Math.random();
    }
    
    // Add custom attributes
    geometry.setAttribute('initialPosition', new THREE.BufferAttribute(initialPositions, 3));
    geometry.setAttribute('initialNormal', new THREE.BufferAttribute(initialNormals, 3));
    geometry.setAttribute('aRandom', new THREE.BufferAttribute(randoms, 1));
    geometry.setAttribute('aUv', new THREE.BufferAttribute(aUvs, 2));
    
    // Create shader material
    this.material = new THREE.ShaderMaterial({
      vertexShader,
      fragmentShader,
      uniforms: {
        uTime: { value: 0 },
        uDisplacementStrength: { value: this.animationParams.displacementStrength },
        uNoiseScale: { value: this.animationParams.noiseScale },
        uWaveSpeed: { value: this.animationParams.waveSpeed },
        uLightPosition: { value: new THREE.Vector3(20, 20, 20) },
        uRoughness: { value: this.animationParams.roughness },
        uMetalness: { value: this.animationParams.metalness },
        uCameraPosition: { value: new THREE.Vector3() }
      },
      transparent: true,
      depthTest: true,
      depthWrite: false,
      blending: THREE.AdditiveBlending,
      side: THREE.DoubleSide
    });
    
    // Create points mesh
    this.sphere = new THREE.Points(geometry, this.material);
    this.sphere.castShadow = true;
    this.sphere.receiveShadow = true;
    this.scene.add(this.sphere);
    
    console.log(`Created displaced sphere with ${vertices.length / 3} vertices`);
  }

  private setupLighting(): void {
    // Very subtle ambient light to prevent complete darkness
    const ambientLight = new THREE.AmbientLight(0x0a0a0a, 0.1);
    this.scene.add(ambientLight);
    
    // Main front-facing light that follows camera (handled in shader)
    // We keep a directional light for potential shadows but reduce intensity
    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.3);
    directionalLight.position.set(0, 0, 30);
    directionalLight.castShadow = false; // Disable shadows for performance
    this.scene.add(directionalLight);
    
    // Very subtle rim lights for edge definition
    const rimLight1 = new THREE.PointLight(0x7F00FF, 0.2, 50);
    rimLight1.position.set(-25, 0, 0);
    this.scene.add(rimLight1);
    
    const rimLight2 = new THREE.PointLight(0xFF5722, 0.2, 50);
    rimLight2.position.set(25, 0, 0);
    this.scene.add(rimLight2);
  }

  private async setupControls(): Promise<void> {
    try {
      // Dynamically import OrbitControls
      const { OrbitControls } = await import('three/examples/jsm/controls/OrbitControls');
      
      this.controls = new OrbitControls(this.camera, this.renderer.domElement);
      this.controls.enableDamping = true;
      this.controls.dampingFactor = 0.05;
      this.controls.minDistance = 25;
      this.controls.maxDistance = 80;
      this.controls.autoRotate = true;
      this.controls.autoRotateSpeed = 0.5;
    } catch (error) {
      console.warn('OrbitControls not available, using basic mouse controls');
      this.setupBasicControls();
    }
  }

  private setupBasicControls(): void {
    let isMouseDown = false;
    let previousMouseX = 0;
    let previousMouseY = 0;

    const onMouseMove = (event: MouseEvent) => {
      if (isMouseDown) {
        const deltaX = event.clientX - previousMouseX;
        const deltaY = event.clientY - previousMouseY;
        
        this.sphere.rotation.y += deltaX * 0.01;
        this.sphere.rotation.x += deltaY * 0.01;
      }
      
      previousMouseX = event.clientX;
      previousMouseY = event.clientY;
    };

    document.addEventListener('mousedown', () => isMouseDown = true);
    document.addEventListener('mouseup', () => isMouseDown = false);
    document.addEventListener('mousemove', onMouseMove);
  }

  private setupEventListeners(): void {
    window.addEventListener('resize', () => this.handleResize());
    
    // Mouse tracking for sphere movement
    window.addEventListener('mousemove', (event) => this.handleMouseMove(event));
    window.addEventListener('touchmove', (event) => this.handleTouchMove(event));
    
    // Optional: Add GUI controls for real-time parameter adjustment
    this.setupGUI();
  }

  private handleMouseMove(event: MouseEvent): void {
    // Normalize mouse position to [-1, 1]
    this.mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
    this.mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;
    
    // Calculate target rotation based on mouse position
    this.targetRotation.x = this.mouse.y * 0.3; // Vertical rotation
    this.targetRotation.y = this.mouse.x * 0.5; // Horizontal rotation
  }

  private handleTouchMove(event: TouchEvent): void {
    if (event.touches.length > 0) {
      const touch = event.touches[0];
      // Normalize touch position to [-1, 1]
      this.mouse.x = (touch.clientX / window.innerWidth) * 2 - 1;
      this.mouse.y = -(touch.clientY / window.innerHeight) * 2 + 1;
      
      // Calculate target rotation based on touch position
      this.targetRotation.x = this.mouse.y * 0.3;
      this.targetRotation.y = this.mouse.x * 0.5;
    }
  }

  private setupGUI(): void {
    // Basic parameter controls via keyboard
    document.addEventListener('keydown', (event) => {
      switch(event.key) {
        case '1':
          this.animationParams.displacementStrength += 0.1;
          this.material.uniforms.uDisplacementStrength.value = this.animationParams.displacementStrength;
          break;
        case '2':
          this.animationParams.displacementStrength -= 0.1;
          this.material.uniforms.uDisplacementStrength.value = Math.max(0, this.animationParams.displacementStrength);
          break;
        case '3':
          this.animationParams.waveSpeed += 0.1;
          this.material.uniforms.uWaveSpeed.value = this.animationParams.waveSpeed;
          break;
        case '4':
          this.animationParams.waveSpeed -= 0.1;
          this.material.uniforms.uWaveSpeed.value = Math.max(0, this.animationParams.waveSpeed);
          break;
      }
    });
  }

  private handleResize(): void {
    this.camera.aspect = window.innerWidth / window.innerHeight;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(window.innerWidth, window.innerHeight);
  }

  private animate(): void {
    requestAnimationFrame(() => this.animate());
    
    const elapsedTime = this.clock.getElapsedTime();
    
    // Update shader uniforms
    this.material.uniforms.uTime.value = elapsedTime;
    
    // Update camera position uniform for view-dependent rendering
    this.material.uniforms.uCameraPosition.value.copy(this.camera.position);
    
    // Update light position to follow camera for front lighting
    const lightOffset = new THREE.Vector3(0, 10, 20);
    lightOffset.applyQuaternion(this.camera.quaternion);
    this.material.uniforms.uLightPosition.value.copy(this.camera.position).add(lightOffset);
    
    // Apply smooth mouse-following rotation
    const dampingFactor = 0.05; // Smooth interpolation
    this.sphere.rotation.x += (this.targetRotation.x - this.sphere.rotation.x) * dampingFactor;
    this.sphere.rotation.y += (this.targetRotation.y - this.sphere.rotation.y) * dampingFactor;
    
    // Add subtle continuous rotation for cosmic effect
    this.sphere.rotation.y += 0.002;
    
    // Update controls if available (reduced influence to allow mouse control)
    if (this.controls) {
      this.controls.autoRotateSpeed = 0.1; // Slower auto-rotation
      this.controls.update();
    }
    
    // Render the scene
    this.renderer.render(this.scene, this.camera);
  }
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => new AnimatedDisplacedSphere());
} else {
  new AnimatedDisplacedSphere();
}