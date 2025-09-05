uniform sampler2D uTexture;
varying vec3 vColor;
varying float vAlpha;

void main() {
    vec4 texColor = texture2D(uTexture, gl_PointCoord);
    gl_FragColor = vec4(vColor, vAlpha) * texColor;
}