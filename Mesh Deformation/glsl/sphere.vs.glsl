uniform vec3 spherePosition;
uniform vec3 sphereTrail; // acts as an axis for deformation

uniform float horizontalScale;
uniform float verticalScale;

uniform int mode;

out float height;
out vec3 pos;
out vec3 mappedPos;

mat4 sphereTranslation() {
    mat4 translate; // translates sphere by spherePosition
    translate[0] = vec4(1., 0., 0., 0.);
    translate[1] = vec4(0., 1., 0., 0.);
    translate[2] = vec4(0., 0., 1., 0.);
    translate[3] = vec4(spherePosition, 1.0);
    return translate;
}

mat4 getCameraRotation() {
    mat4 cameraFrame = inverse(viewMatrix);
    mat4 cameraRotation = cameraFrame;
    cameraRotation[3] = vec4(0., 0., 0., 1.);
    return cameraRotation;
}

void trailMode() {
    mat4 tilt; // tilts the sphere by 90 degrees along the x-axis
    tilt[0] = vec4(1., 0., 0., 0.);
    tilt[1] = vec4(0., 0., -1., 0.);
    tilt[2] = vec4(0., 1., 0., 0.);
    tilt[3] = vec4(0., 0., 0., 1.);

    mat4 cameraRotation = getCameraRotation();
    mat4 translate = sphereTranslation();

    vec4 pos = vec4(position, 1.0);
    if (pos.y > 0.) {
        vec4 sphereVelocity = vec4(sphereTrail - spherePosition, 0.0); // from sphere to trail
        vec4 localSphereVelocity = inverse(tilt)*inverse(cameraRotation)*inverse(translate)*inverse(modelMatrix) * sphereVelocity;
        localSphereVelocity.y = 0.; // project velocity onto xz-plane in object (sphere) space

        pos = pos + localSphereVelocity * pos.y;
    }

    gl_Position = projectionMatrix * viewMatrix * modelMatrix * translate * cameraRotation *tilt * pos;
}

// Takes a point on a cylinder and maps it onto a plane.
/* Params:
    - point: Point on cylinder.
    - hScale: Horizontal scale factor.
    - vScale: Vertical scale factor.
    Returns: Mapped point on plane.
*/
vec3 cylinderToPlane(vec3 point, float hScale, float vScale) {
    return vec3(
        hScale * atan(point.x, point.z),
        vScale * point.y,
        0
    );
}

// Takes a point on the sphere and transforms/projects it into a cylinder with radius 1.
// Returns projected point.
vec3 sphereToCylinder(vec3 point) {
    float x = point.x;
    float z = point.z;
    float oneOverDistance = inversesqrt(x*x + z*z);
    return vec3(
        x * oneOverDistance,
        point.y,
        z * oneOverDistance
    );
}

void mapMode() {
    mat4 translate = sphereTranslation();
    mat4 cameraRotation = getCameraRotation();

    mappedPos = cylinderToPlane((position), horizontalScale, verticalScale);
    vec4 pos = vec4(mappedPos, 1.0);
    gl_Position = projectionMatrix * viewMatrix * modelMatrix *translate*cameraRotation * pos;
}

void main() {
    pos = position;
    height = position.y;
    mappedPos = vec3(0., 0., 0.);

    switch(mode) {
        case 0:
            trailMode();
            break;
        case 1:
            mapMode();
            break;
    }
}
