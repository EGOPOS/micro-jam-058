shader_type canvas_item;

// =============================
// original:https://www.shadertoy.com/view/lllSWr
//adaptation: GerardoLCDF
// ===============================

// Color principal/de fondo
uniform vec4 u_main_color : source_color = vec4(0.0, 0.2, 0.0, 1.0); 
// Color que se aplica al canal0
uniform vec4 u_channel_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// Control de velocidad (multiplica el tiempo)
uniform float u_speed = 1.0;
// Desplazamiento de la cámara/mundo (XYZ)
uniform vec3 u_position = vec3(0.0, 0.0, 0.0);

uniform sampler2D channel0 : hint_default_black; 

#define T (TIME * u_speed)

// Rotation function
void r(inout vec2 v, float t) { 
    float a = t * T;
    float c = cos(a);
    float s = sin(a);
    mat2 rot_mat = mat2(vec2(c, -s), vec2(s, c)); 
    v = rot_mat * v;
}

#define smin(a,b) (1.0 / (1.0 / (a) + 1.0 / (b)))

const mat3 m = mat3( 
    vec3( 0.00, -0.80, -0.60 ), 
    vec3( 0.80,  0.36, -0.48 ), 
    vec3( 0.60, -0.48,  0.64 )  
);

float hash( float n ) {
    return fract(sin(n)*43758.5453);
}

float noise( in vec3 x ) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 57.0 + 113.0 * p.z;
    float res = mix(mix(mix( hash(n +   0.0), hash(n +   1.0), f.x),
                        mix( hash(n +  57.0), hash(n +  58.0), f.x), f.y),
                    mix(mix( hash(n + 113.0), hash(n + 114.0), f.x),
                        mix( hash(n + 170.0), hash(n + 171.0), f.x), f.y), f.z);
    return res;
}

#define snoise(x) (2.0 * noise(x) - 1.0)

float sfbm( vec3 p ) {
    float f;
    f  = 0.5000 * snoise( p ); p = m * p * 2.02;
    f += 0.2500 * snoise( p ); p = m * p * 2.03;
    f += 0.1250 * snoise( p ); p = m * p * 2.01;
    f += 0.0625 * snoise( p );
    return f;
}

#define sfbm3(p) vec3(sfbm(p), sfbm(p - 327.67), sfbm(p + 327.67))


void fragment() {
    vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE; 


    vec4 p = vec4(FRAGCOORD.xy, 0.0, 1.0) / screen_size.y - 0.5; 
    
  
    p.x -= 0.4; // Desplazamiento original del shader
    p.xyz -= u_position;
   
    vec4 d, c; 
    
    d = p;         
    p.z += 10.0;   

    COLOR = vec4(u_main_color.rgb, 1.0); 
    
    float x1, x2, x = 1e9;
    
    const float MAX_STEPS = 100.0;
    for (float i = 1.0; i > 0.0; i -= (1.0 / MAX_STEPS))  {
        
        if (COLOR.x >= 0.99) break; 
        
        vec4 u = 0.03 * floor(p / vec4(8.0, 8.0, 1.0, 1.0) + 3.5);
        vec4 t = p;
        
        r(t.xy, u.x); r(t.xz, u.y); 

        t.xyz += sfbm3(t.xyz / 2.0 + vec3(0.5 * T, 0.0, 0.0)) * (0.6 + 8.0 * (0.5 - 0.5 * cos(T / 16.0)));
        
        vec4 texture_sample = texture(channel0, t.xy);
        c = 5.0 * texture_sample.rrrr * u_channel_color;
 
        x = abs(mod(length(t.xyz), 1.0) - 0.5); 
        x1 = length(t.xyz) - 7.0;              
        
        x = max(x, x1);                        
        
        if ((x1 > 0.1) && (p.z < 0.0)) break; 
        
        if (x < 0.01) { 
              COLOR.rgb += (1.0 - COLOR.rgb) * 0.2 * mix(u_main_color.rgb, c.rgb, i * i); 
              x = 0.1; 
        }  
        
        p += d * x; 
     }
}