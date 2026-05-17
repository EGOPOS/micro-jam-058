// 2022 Kasper Arnklit Frandsen - Public Domain - No Rights Reserved
// Внесены изменения для устранения тайлинга (Anti-Tiling) через Noise Mask

shader_type spatial;

uniform float offset : hint_range(-1.0, 1.0) = 0.5;
uniform float fade : hint_range(0.0, 1.0) = 0.1;

// --- НАСТРОЙКИ МАСШТАБА ---
uniform vec3 uv_scale_fg = vec3(1.0);
uniform vec3 uv_scale_bg = vec3(1.0);
uniform float triplanar_sharpness = 4.0;

// --- НАСТРОЙКИ АНТИТАЙЛИНГА (NOISE MASK) ---
// Текстура шума, которая разобьет тайлинг
uniform sampler2D noise_texture : hint_default_white;
// Масштаб текстуры шума (лучше делать мелким, например 0.05, чтобы пятна были большими)
uniform vec3 uv_scale_noise = vec3(0.05);
// Во сколько раз изменится масштаб текстуры-дубликата (идеально: не целые числа, например 0.43 или 1.61)
uniform float secondary_scale = 0.43;

// --- ТЕКСТУРЫ ---
uniform sampler2D albedo_texture_fg : source_color;
uniform sampler2D orm_texture_fg : hint_default_white;
uniform sampler2D normal_texture_fg : hint_normal;

uniform sampler2D albedo_texture_bg : source_color;
uniform sampler2D orm_texture_bg : hint_default_white;
uniform sampler2D normal_texture_bg : hint_normal;

varying vec3 triplanar_pos_fg;
varying vec3 triplanar_pos_bg;
varying vec3 triplanar_pos_noise;
varying vec3 triplanar_power_normal;

// Базовая функция для чтения текстур со всех трех плоскостей
vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
    vec4 samp = vec4(0.0);
    samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
    samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
    // Для оси X инвертируем X координату, чтобы текстура не была отзеркалена
    samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
    return samp;
}

// Новая функция: смешивает текстуру саму с собой в разных масштабах по маске шума
vec4 get_anti_tiled_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_pos, float p_secondary_scale, float p_mask) {
    vec4 samp1 = triplanar_texture(p_sampler, p_weights, p_pos);
    vec4 samp2 = triplanar_texture(p_sampler, p_weights, p_pos * p_secondary_scale);
    return mix(samp1, samp2, p_mask);
}

void vertex() {
    // 1. Вычисляем специальные TANGENT и BINORMAL
    TANGENT = vec3(0.0, 0.0, -1.0) * abs(NORMAL.x);
    TANGENT += vec3(1.0, 0.0, 0.0) * abs(NORMAL.y);
    TANGENT += vec3(1.0, 0.0, 0.0) * abs(NORMAL.z);
    TANGENT = normalize(TANGENT);
    
    BINORMAL = vec3(0.0, -1.0, 0.0) * abs(NORMAL.x);
    BINORMAL += vec3(0.0, 0.0, 1.0) * abs(NORMAL.y);
    BINORMAL += vec3(0.0, -1.0, 0.0) * abs(NORMAL.z);
    BINORMAL = normalize(BINORMAL);
    
    // 2. Вычисляем веса для смешивания
    triplanar_power_normal = pow(abs(NORMAL), vec3(triplanar_sharpness));
    triplanar_power_normal /= dot(triplanar_power_normal, vec3(1.0));
    
    // 3. Задаем координаты для трипланара
    triplanar_pos_fg = VERTEX * uv_scale_fg;
    triplanar_pos_fg *= vec3(1.0, -1.0, 1.0);
    
    triplanar_pos_bg = VERTEX * uv_scale_bg;
    triplanar_pos_bg *= vec3(1.0, -1.0, 1.0);
    
    // Координаты для карты шума
    triplanar_pos_noise = VERTEX * uv_scale_noise;
    triplanar_pos_noise *= vec3(1.0, -1.0, 1.0);
}

void fragment() {
    // Получаем значение маски шума (чёрно-белые пятна)
    float anti_tile_mask = triplanar_texture(noise_texture, triplanar_power_normal, triplanar_pos_noise).r;

    // Читаем текстуры Foreground с применением антитайлинга
    vec3 albedo_tex_fg = get_anti_tiled_texture(albedo_texture_fg, triplanar_power_normal, triplanar_pos_fg, secondary_scale, anti_tile_mask).rgb;
    vec3 orm_tex_fg = get_anti_tiled_texture(orm_texture_fg, triplanar_power_normal, triplanar_pos_fg, secondary_scale, anti_tile_mask).rgb;
    vec3 normal_tex_fg = get_anti_tiled_texture(normal_texture_fg, triplanar_power_normal, triplanar_pos_fg, secondary_scale, anti_tile_mask).rgb;
    
    // Читаем текстуры Background с применением антитайлинга
    vec3 albedo_tex_bg = get_anti_tiled_texture(albedo_texture_bg, triplanar_power_normal, triplanar_pos_bg, secondary_scale, anti_tile_mask).rgb;
    vec3 orm_tex_bg = get_anti_tiled_texture(orm_texture_bg, triplanar_power_normal, triplanar_pos_bg, secondary_scale, anti_tile_mask).rgb;
    vec3 normal_tex_bg = get_anti_tiled_texture(normal_texture_bg, triplanar_power_normal, triplanar_pos_bg, secondary_scale, anti_tile_mask).rgb;
    
    vec3 bg_normal = normal_tex_bg * 2.0 - 1.0;
    // max(0.0, ...) предотвращает черные пиксели (ошибки NaN)
    bg_normal.z = sqrt(max(0.0, 1.0 - dot(bg_normal.xy, bg_normal.xy)));
    
    // Используем BINORMAL (в зависимости от версии Godot тут может потребоваться BITANGENT)
    vec3 normal_applied = bg_normal.x * TANGENT + bg_normal.y * BINORMAL + bg_normal.z * NORMAL;
    vec3 up_vector_viewspace = mat3(VIEW_MATRIX) * vec3(0.0, 1.0, 0.0);
    
    float dot_product = dot(up_vector_viewspace, normal_applied);
    float mask = smoothstep(offset - fade, offset + fade, dot_product);
    
    ALBEDO = mix(albedo_tex_bg, albedo_tex_fg, mask);
    vec3 mixed_orm = mix(orm_tex_bg, orm_tex_fg, mask);
    
    AO = mixed_orm.r;
    ROUGHNESS = mixed_orm.g;
    METALLIC = mixed_orm.b;
    
    NORMAL_MAP = mix(normal_tex_bg, normal_tex_fg, mask);
}