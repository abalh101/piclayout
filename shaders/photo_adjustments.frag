#include <flutter/runtime_effect.glsl>
precision highp float;
uniform vec2 targetSize;
uniform vec4 crop;
uniform vec4 rowR;
uniform vec4 rowG;
uniform vec4 rowB;
uniform vec3 offsetRGB;
uniform float tint;
uniform float highlights;
uniform float shadows;
uniform float fade;
uniform float blackPoint;
uniform float vignette;
uniform sampler2D sourceImage;
out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / targetSize + vec2(0.5);
  vec4 sampleColor = texture(sourceImage, crop.xy + uv * crop.zw);
  float alpha = sampleColor.a;
  vec4 straight = vec4(alpha > 0.0 ? sampleColor.rgb / alpha : vec3(0.0), alpha);
  vec3 rgb = clamp(vec3(dot(rowR, straight), dot(rowG, straight),
      dot(rowB, straight)) + offsetRGB, 0.0, 1.0);
  rgb += tint * vec3(0.06, -0.06, 0.06);
  float luminance = dot(clamp(rgb, 0.0, 1.0), vec3(0.2126, 0.7152, 0.0722));
  float hi = smoothstep(0.45, 1.0, luminance);
  float lo = 1.0 - smoothstep(0.0, 0.55, luminance);
  rgb += highlights * hi * 0.35 + shadows * lo * 0.35;
  rgb = max(vec3(0.0), (rgb - blackPoint * 0.25) / (1.0 - blackPoint * 0.25));
  rgb = mix(rgb, vec3(0.5), fade * 0.4);
  float edge = smoothstep(0.25, 0.71, length(uv - vec2(0.5)));
  rgb *= 1.0 - vignette * edge * 0.75;
  fragColor = vec4(clamp(rgb, 0.0, 1.0) * alpha, alpha);
}
