shader_type spatial;
// Добавляем depth_draw_opaque и cull_disabled для листвы,
// и сохраняем blend_mix
render_mode blend_mix, depth_draw_opaque, cull_disabled;

// --- ТЕКСТУРА И СРЕЗКА АЛЬФЫ ---
uniform sampler2D foliage_texture : source_color, hint_default_black;
uniform float alpha_cutoff : hint_range(0, 1) = 0.5; // порог срезки прозрачности

// --- ПАРАМЕТРЫ ПОКАЧИВАНИЯ ---
uniform float sway_speed = 2.0;
uniform float sway_strength = 0.05; // немного уменьшил, чтобы не слишком дико
uniform float sway_phase = 1.0; 

// --- ФАБРИКА СЛУЧАЙНОСТИ (ДЛЯ АСИНХРОННОГО КАЧАНИЯ) ---
// Простая хэш-функция для генерации рандома из вектора
float hash(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y) * p.z);
}

void vertex() {
    // Получаем мировую позицию опорной точки объекта (чтобы качать все дерево целиком)
    vec3 world_origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
    
    // Генерируем уникальный офсет времени для каждого объекта
    float instance_seed = hash(world_origin);
    
    // Получаем мировую позицию этой конкретной вершины
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    
    // Считаем время и волну, добавляя рандомную фазу и мировую позицию
    // Это заставляет разные ветки и разные деревья качаться по-своему
    float time = (TIME * sway_speed) + (instance_seed * 100.0) + (world_pos.x * sway_phase) + (world_pos.z * sway_phase * 0.7);
    
    // Комбинированное качание для естественности
    float sway_x = sin(time) * cos(time * 0.63) + sin(time * 1.5) * 0.3;
    float sway_z = cos(time * 0.91) * sin(time * 0.42) + cos(time * 1.8) * 0.2;
    
    // Маска: не гнем ствол. Предполагаем, что UV.y = 0 — это низ ствола, UV.y = 1 — верхушка.
    // Если у тебя другая UV развертка, маска может работать неверно (будет гнуть все дерево).
    float mask = smoothstep(0.0, 0.8, UV.y); // Плавно увеличиваем гибкость от 0 до 0.8 по UV.y
    
    // Учитываем масштаб объекта при качании
    float scale = length(MODEL_MATRIX[1].xyz); // Масштаб по оси Y (вертикальный)
    
    // Применяем смещение к VERTEX в local space
    VERTEX.x += sway_x * sway_strength * mask * scale;
    VERTEX.z += sway_z * sway_strength * mask * scale;
    // Добавим немного вертикального "сжатия" при покачивании
    VERTEX.y += sin(time * 0.9) * sway_strength * mask * 0.2 * scale;
}

void fragment() {
    // Считываем цвет листвы
    vec4 tex = texture(foliage_texture, UV);
    
    // ВАЖНО: Срезка альфы (срезка невидимых квадратов)
    // Альфа-порог в Vulkan/Forward+ работает именно так
    if (tex.a < alpha_cutoff) {
        discard;
    }
    
    // Задаем цвет и прозрачность
    ALBEDO = tex.rgb;
    ALPHA = tex.a;
    
    // Можно добавить немного "свечения" через эмиссию, если листва слишком темная в тени
    // EMISSION = tex.rgb * 0.1;
}