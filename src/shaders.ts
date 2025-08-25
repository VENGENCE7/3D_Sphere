export const vertexShader = `
  attribute vec3 position;
  
  uniform mat4 projectionMatrix;
  uniform mat4 viewMatrix;
  uniform mat4 modelMatrix;
  uniform float time;
  
  varying vec3 vColor;
  varying float vVisibility;
  varying vec3 vNormal;
  varying vec3 vPosition;
  varying float vDisplacement;
  
  // 3D Simplex noise function
  vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
  vec4 mod289(vec4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
  vec4 permute(vec4 x) { return mod289(((x*34.0)+1.0)*x); }
  vec4 taylorInvSqrt(vec4 r) { return 1.79284291400159 - 0.85373472095314 * r; }
  
  float snoise(vec3 v) {
    const vec2 C = vec2(1.0/6.0, 1.0/3.0);
    const vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
    
    vec3 i  = floor(v + dot(v, C.yyy));
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
  
  void main() {
    vec3 pos = position;
    vNormal = normalize(pos);
    
    // Create animated pattern coordinates
    float animatedY = pos.y + time * 0.5;
    vec3 patternCoord = vec3(pos.x, animatedY, pos.z);
    
    // Multiple wave patterns
    float pattern1 = sin(patternCoord.x * 4.0) * cos(patternCoord.y * 3.0);
    float pattern2 = sin(patternCoord.x * 8.0 + time) * sin(patternCoord.y * 6.0);
    float pattern3 = cos(patternCoord.x * 2.0 - time * 0.5) * cos(patternCoord.y * 4.0);
    
    // Combine patterns
    float combinedPattern = (pattern1 + pattern2 * 0.5 + pattern3 * 0.3) / 1.8;
    
    // Add noise for organic feel
    float noiseValue = snoise(pos * 2.0 + vec3(0.0, time * 0.3, 0.0));
    
    // Calculate displacement
    float displacement = (combinedPattern + noiseValue * 0.3) * 0.35;
    vDisplacement = displacement;
    
    // Displace along normal
    vec3 displacedPos = pos + vNormal * displacement;
    
    // Transform position
    vec4 worldPos = modelMatrix * vec4(displacedPos, 1.0);
    vPosition = worldPos.xyz;
    vec4 viewPos = viewMatrix * worldPos;
    gl_Position = projectionMatrix * viewPos;
    
    // Calculate visibility (create void areas)
    float normalizedZ = (viewPos.z + 5.0) / 10.0; // Normalize z-depth
    vVisibility = 1.0 - smoothstep(0.65, 0.7, abs(normalizedZ - 0.5) * 2.0);
    
    // Color gradient with vertical and displacement influence
    float gradientFactor = (pos.y + 1.0) * 0.5; // 0 to 1 from bottom to top
    float displacementInfluence = displacement * 2.0 + 0.5;
    
    // Vibrant color palette
    vec3 yellow = vec3(1.0, 0.902, 0.098); // #FFE619
    vec3 orange = vec3(1.0, 0.502, 0.098); // #FF8019
    vec3 pink = vec3(1.0, 0.2, 0.502);     // #FF3380
    vec3 purple = vec3(0.4, 0.098, 1.0);   // #6619FF
    
    vec3 color;
    if (gradientFactor > 0.7) {
      color = mix(orange, yellow, (gradientFactor - 0.7) / 0.3);
    } else if (gradientFactor > 0.4) {
      color = mix(pink, orange, (gradientFactor - 0.4) / 0.3);
    } else {
      color = mix(purple, pink, gradientFactor / 0.4);
    }
    
    // Add noise-based color variation
    vec3 colorVariation = vec3(
      noiseValue * 0.1,
      noiseValue * 0.05,
      -noiseValue * 0.1
    );
    color += colorVariation;
    
    // Boost saturation for displaced areas
    float saturationBoost = 1.0 + displacementInfluence * 1.5;
    vec3 gray = vec3(dot(color, vec3(0.299, 0.587, 0.114)));
    color = mix(gray, color, saturationBoost);
    
    vColor = color;
    
    // Dynamic point size
    float baseSize = 6.0;
    float perspectiveScale = 50.0 / length(viewPos.xyz);
    float displacementScale = 1.0 + abs(displacement) * 0.5;
    gl_PointSize = baseSize * perspectiveScale * displacementScale;
  }
`;

export const fragmentShader = `
  precision highp float;
  
  varying vec3 vColor;
  varying float vVisibility;
  varying vec3 vNormal;
  varying vec3 vPosition;
  varying float vDisplacement;
  
  uniform vec3 lightDirection;
  uniform vec3 cameraPosition;
  
  void main() {
    // Discard invisible dots (void areas)
    if (vVisibility < 0.5) discard;
    
    // Create circular dots
    vec2 coord = gl_PointCoord - vec2(0.5);
    float dist = length(coord);
    
    // Sharp-edged circles with minimal soft falloff
    if (dist > 0.5) discard;
    float alpha = 1.0 - smoothstep(0.45, 0.5, dist);
    
    // Enhanced lighting
    vec3 normal = normalize(vNormal);
    vec3 viewDir = normalize(cameraPosition - vPosition);
    vec3 lightDir = normalize(lightDirection);
    
    // Ambient light
    float ambient = 0.5;
    
    // Diffuse lighting
    float diffuse = max(dot(normal, lightDir), 0.0);
    
    // Colored specular highlights
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 64.0);
    vec3 specularColor = vColor * spec * 0.6;
    
    // Fresnel effect with color
    float fresnel = pow(1.0 - dot(viewDir, normal), 2.0);
    vec3 fresnelColor = vColor * fresnel * 0.3;
    
    // Center highlight
    float centerHighlight = 1.0 - dist * 2.0;
    centerHighlight = pow(max(centerHighlight, 0.0), 2.0) * 0.3;
    
    // Combine lighting
    vec3 finalColor = vColor * (ambient + diffuse * 0.5);
    finalColor += specularColor;
    finalColor += fresnelColor;
    finalColor += vec3(1.0) * centerHighlight;
    
    // Rim lighting
    float rim = 1.0 - max(dot(viewDir, normal), 0.0);
    rim = pow(rim, 3.0) * 0.2;
    finalColor += vColor * rim;
    
    // Apply visibility fade
    alpha *= vVisibility;
    
    gl_FragColor = vec4(finalColor, alpha);
  }
`;