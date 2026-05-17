shader_type canvas_item;

// --- Uniforms --- //
uniform float cutout : hint_range(0.0, 1.0, 0.01) = 0.20;
uniform float inner_fill : hint_range(0.0, 1.0, 0.01) = 0.15;

// Передаем измененное время напрямую из скрипта
uniform float custom_time;

// --- Functions --- //
void fragment() {
    float dist = distance(UV, vec2(0.5));
    COLOR.a *= 1.0 - step(0.5, dist);
    COLOR.a += step(0.5 - cutout / 2.0, dist);
    
    // Используем custom_time вместо TIME * blink_speed
    COLOR.a -= step((0.5 - (cutout + inner_fill) / 2.0) * step(0.5, mod(custom_time, 1.0)), dist);
}