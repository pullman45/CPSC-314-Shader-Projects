// The uniform variable is set up in the javascript code and the same for all vertices
uniform vec3 orbPosition;
uniform float orbRadius;
uniform vec3 pointerHit;
uniform int levelAxis; // the axis for which to draw the level curve
uniform int mode;

// This is a "varying" variable and interpolated between vertices and across fragments.
// The shared variable is initialized in the vertex shader and passed to the fragment shader.
out float intensity;
out vec4 worldPosition;
out float isInLevel;

void deformVertexByOrb(inout vec4 worldPos, vec4 orbPos) {
  vec4 difference = worldPos - orbPos;
  if (length(difference) < orbRadius) {
    worldPos = orbPos + normalize(difference) * orbRadius;
  }
}

vec4 Default() {
    vec4 orbPos = vec4(orbPosition, 1.0);
    vec4 worldPos = modelMatrix * vec4(position, 1.0);
    deformVertexByOrb(worldPos, orbPos);

    vec4 lightDirectionObjectSpace = inverse(modelMatrix) * (orbPos - worldPos);
    vec4 lightDir = normalize(lightDirectionObjectSpace);
    vec4 normalv4 = vec4(normal, 1.0);
    intensity = dot(normalv4, lightDir);
    worldPosition = worldPos;

    gl_Position = projectionMatrix * viewMatrix * worldPos;
    return worldPos;
}

void NormalCursor() {
  Default();
}

// sets isInLevel to true if vertex is within 0.2 units of the cursor
void LevelCursor() {
  Default();
  vec4 worldPos = modelMatrix * vec4(position, 1.0);
  float distance = pointerHit[levelAxis] - worldPos[levelAxis];
  isInLevel = abs(distance) < 0.2 ? 1.0 : 0.0;
}

void main() {
  switch (mode) {
    case 0:
      Default();
      break;
    case 1:
      NormalCursor();
      break;
    case 3:
      LevelCursor();
      break;
  }
}
