
shader_type spatial;
render_mode unshaded, depth_draw_never;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, repeat_disable, filter_nearest;

uniform vec4 edge_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float threshold = 0.0;
uniform float blend = 0.01;
uniform bool enable_depth_pass = true;
uniform float threshold_depth = 0.0;
uniform float blend_depth = 0.01;
uniform float distance_fade_length = 50.0;
uniform float distance_fade_blend = 20.0;


float getGrayScale(sampler2D s, vec2 uv) {
        vec3 c = texture(s, uv).rgb;
        return (c.r + c.g + c.b) / 3.0;
}

float get_linear_depth(sampler2D s, vec2 uv, mat4 ipm) {
        float depth = texture(s, uv).r;

       	vec3 ndc = vec3(uv, depth) * 2.0 - 1.0;

        vec4 view = ipm * vec4(ndc, 1.0);
        view.xyz /= view.w;
        return -view.z;
}

void fragment() {
        vec2 delta = vec2(0.0, 0.003);
        vec2 uv = SCREEN_UV;
        vec3 screen_color = texture(SCREEN_TEXTURE, uv).rgb;

        float c1y = getGrayScale(SCREEN_TEXTURE, uv - delta / 2.0);
        float c2y = getGrayScale(SCREEN_TEXTURE, uv + delta / 2.0);
        float c1x = getGrayScale(SCREEN_TEXTURE, uv - delta.yx / 2.0);
        float c2x = getGrayScale(SCREEN_TEXTURE, uv + delta.yx / 2.0);
        vec2 dcdi = vec2(c2x - c1x, c2y - c1y) / (delta.y * 10.0);
        float edge = 1.0 - length(dcdi) / 10.0;
        float final_edge = smoothstep(threshold, threshold + blend, edge);

        if (enable_depth_pass) {
                c1y = get_linear_depth(DEPTH_TEXTURE, uv - delta / 2.0, INV_PROJECTION_MATRIX);
                c2y = get_linear_depth(DEPTH_TEXTURE, uv + delta / 2.0, INV_PROJECTION_MATRIX);
                c1x = get_linear_depth(DEPTH_TEXTURE, uv - delta.yx / 2.0, INV_PROJECTION_MATRIX);
                c2x = get_linear_depth(DEPTH_TEXTURE, uv + delta.yx / 2.0, INV_PROJECTION_MATRIX);
                dcdi = vec2(c2x - c1x, c2y - c1y) / (delta.y * 10.0);
                float depth_edge = 1.0 - length(dcdi) / 10.0;
                final_edge *= smoothstep(threshold_depth, threshold_depth + blend_depth, depth_edge);
        }

        float linear_depth = get_linear_depth(DEPTH_TEXTURE, uv, INV_PROJECTION_MATRIX);
        float df = 1.0 - smoothstep(distance_fade_length, distance_fade_length + distance_fade_blend, linear_depth);
        final_edge = 1.0 - (1.0 - final_edge) * df;

        ALBEDO = mix(edge_color.rgb, screen_color, final_edge);
}