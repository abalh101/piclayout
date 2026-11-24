#include <flutter/runtime_effect.glsl>

uniform vec2 uOrigin;
uniform vec2 uSize;
uniform vec2 uSampleStep;
uniform float uHighlights;
uniform float uShadows;
uniform float uSharpness;
uniform sampler2D uPhoto;

out vec4 fragColor;

void main() {
  vec2 uv = (FlutterFragCoord().xy - uOrigin) / uSize;
  vec4 source = texture(uPhoto, uv);
  if (source.a <= 0.0) {
    fragColor = vec4(0.0);
    return;
  }

  vec3 color = source.rgb / source.a;
  if (uSharpness > 0.0) {
    vec2 xStep = vec2(uSampleStep.x, 0.0);
    vec2 yStep = vec2(0.0, uSampleStep.y);
    vec4 neighbors = texture(uPhoto, clamp(uv - xStep, 0.0, 1.0))
        + texture(uPhoto, clamp(uv + xStep, 0.0, 1.0))
        + texture(uPhoto, clamp(uv - yStep, 0.0, 1.0))
        + texture(uPhoto, clamp(uv + yStep, 0.0, 1.0));
    vec3 average = neighbors.a > 0.0 ? neighbors.rgb / neighbors.a : color;
    color = clamp(color + (color - average) * uSharpness * 1.5, 0.0, 1.0);
  }

  float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
  float light = luminance * luminance * luminance;
  float shade = (1.0 - luminance) * (1.0 - luminance) * (1.0 - luminance);
  color = clamp(color + 0.38 * (uHighlights * light + uShadows * shade), 0.0, 1.0);
  fragColor = vec4(color * source.a, source.a);
}
