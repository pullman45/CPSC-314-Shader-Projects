uniform vec3 ambientColor;
uniform vec3 diffuseColor;
uniform vec3 specularColor;

uniform float kAmbient;
uniform float kDiffuse;
uniform float kSpecular;

uniform float shininess;

uniform vec3 spherePosition;

out vec3 objectPosition;
out vec3 worldPosition;
out vec3 interpolatedNormal;

void main() {
    gl_Position = projectionMatrix * viewMatrix * modelMatrix * vec4(position, 1.0);
    
    worldPosition = (modelMatrix * vec4(position, 1.0)).xyz;
    objectPosition = position;
    interpolatedNormal = normal;
}
