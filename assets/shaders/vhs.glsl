extern number time;
extern number intensity; // 0.0 → 1.0

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
    vec4 pixel;

    //--------------------------------------------------
    // 1. JITTER HORIZONTAL (VHS wobble)
    //--------------------------------------------------
    float jitter = (rand(vec2(time * 3.0, screen.y)) - 0.5) * 0.002 * intensity;
    uv.x += jitter;

    //--------------------------------------------------
    // 2. RGB SPLIT (très léger)
    //--------------------------------------------------
    float rgbOffset = 0.0015 * intensity;
    float r = Texel(tex, uv + vec2(rgbOffset, 0.0)).r;
    float g = Texel(tex, uv).g;
    float b = Texel(tex, uv - vec2(rgbOffset, 0.0)).b;
    pixel = vec4(r, g, b, 1.0);

    //--------------------------------------------------
    // 3. GRAIN LARGE (par blocs)
    //--------------------------------------------------
    float noise = rand(floor(screen / 3.0) + time * 20.0);
    noise = (noise - 0.5) * 0.15 * intensity;
    pixel.rgb += noise;

    //--------------------------------------------------
    // 4. SCANLINES
    //--------------------------------------------------
    float scan = sin(screen.y * 3.1415);
    pixel.rgb *= 1.0 - scan * 0.04 * intensity;

    return pixel;
}