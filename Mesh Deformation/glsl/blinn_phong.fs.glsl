uniform vec3 ambientColor;
uniform vec3 diffuseColor;
uniform vec3 specularColor;

uniform float kAmbient;
uniform float kDiffuse;
uniform float kSpecular;

uniform float shininess;

uniform mat4 modelMatrix;
uniform vec3 spherePosition;

in vec3 interpolatedNormal;
in vec3 objectPosition;
in vec3 worldPosition;

vec3 objectSpace(vec3 v, float w) {
    return (inverse(modelMatrix) * vec4(v, w)).xyz;
}

void main() {
    float ambientIntensity = kAmbient;

    vec3 lightDirection = normalize(objectSpace(spherePosition, 1.0) - objectPosition);
    float diffuseIntensity = kDiffuse * dot(lightDirection, interpolatedNormal);
    
    vec4 camPos = inverse(modelMatrix) * inverse(viewMatrix) * vec4(0., 0., 0., 1.);
    vec3 pointToCameraDirection = normalize(camPos.xyz - objectPosition);
    vec3 h = normalize(lightDirection + pointToCameraDirection);
    float specularIntensity = kSpecular * pow(max(.0, dot(h, interpolatedNormal)), shininess);

    float intensity = max(ambientIntensity, ambientIntensity + diffuseIntensity + specularIntensity);
    vec3 color = ambientColor*ambientIntensity + diffuseColor*diffuseIntensity + specularColor*specularIntensity;

    gl_FragColor = intensity * vec4(color, 1.0);
}
