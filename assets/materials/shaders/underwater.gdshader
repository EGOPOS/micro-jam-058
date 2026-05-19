shader_type spatial;
// Добавляем blend_mix и depth_draw_never, чтобы объект рендерился в прозрачном проходе
// и SCREEN_TEXTURE успевала захватить все, что находится за ним
render_mode unshaded, blend_mix, depth_draw_never;

uniform vec4 tint : source_color = vec4(1.0); // добавим дефолтное значение, чтобы не было черным
uniform float wave_speed = 3.0; 
uniform float wave_freq = 10.0; 
uniform float wave_width = 1.0; 
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap; // линеаризация сгладит пиксели

void fragment(){
    // Считаем смещение на основе UV самого меша
    vec2 wave_uv_offset;
    wave_uv_offset.x = cos((TIME * wave_speed) + UV.x + UV.y * wave_freq * 2.0) * wave_width * 0.01;
    wave_uv_offset.y = 0.0; // если нужно качание только по горизонтали
    
    // Применяем смещение прямо к SCREEN_UV
    vec3 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV + wave_uv_offset).rgb;
    
    ALBEDO = screen_color * tint.rgb;
}