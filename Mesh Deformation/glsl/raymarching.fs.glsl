
uniform vec3 resolution;   
uniform float time;   


// NOTE: You may temporarily adjust these values to improve render performance.
#define MAX_STEPS 500 // max number of steps to take along ray
#define MAX_DIST 50. // max distance to travel along ray
#define HIT_DIST .01 // distance to consider as "hit" to surface

/*
 * Helper: determines the material ID based on the closest distance.
 */
float getMaterial(vec2 d1, vec2 d2) {
    return (d1.x < d2.x) ? d1.y : d2.y;
}

/*
 * Hard union of two SDFs.
 */
float unionSDF( float d1, float d2 )
{
    return min(d1, d2);
}

/*
 * Smooth union of two SDFs.
 * Resource: `https://iquilezles.org/articles/smin/`
 */
float smoothUnionSDF( float d1, float d2, float k )
{
    // Code sourced from resource above.
    k *= log(2.0);
    float x = d2 - d1;
    return d1 + x/(1.0-exp2(x/k));
}

/*
 * Helper: Computes the signed distance function (SDF) of a plane.
 */
vec2 Plane(vec3 p)
{
    vec3 n = vec3(0, 1, 0); // Normal
    float h = 0.0; // Height
    return vec2(dot(p, n) + h, 1.0);
}

/*
 * Sphere SDF.
 *
 * Parameters:
 *  - p: The point in 3D space to evaluate.
 *  - c: The center of the sphere.
 *  - r: The radius of the sphere.
 *
 * Returns:
 *  - A vec2 containing:
 *    - Signed distance to the surface of the sphere.
 *    - An identifier for material type.
 */
vec2 Sphere(vec3 p, vec3 c, float r)
{
    float dist = MAX_DIST;
    float sphere_id = 2.0;

    dist = distance(p, c) - r;

    return vec2(dist, sphere_id);
}

/*
 * Cylinder SDF.
 *
 * Parameters:
 *  - p: The point in 3D space to evaluate.
 *  - c: The center of the cylinder.
 *  - r: The radius of the cylinder.
 *  - h: The height of the cylinder.
 *  - rotate: A flag to apply rotation.
 *
 * Returns:
 *  - A vec2 containing:
 *    - Signed distance to the surface of the cylinder.
 *    - An identifier for material type.
 */
vec2 Cylinder(vec3 p, vec3 c, float r, float h, bool rotate)
{
    float dist = MAX_DIST;
    float hat_id = 3.0; 
    float button_id = 5.0;
    float id = hat_id;

    if (!rotate) {
        float verticalDistance = abs(p.y - c.y);
        float horizontalDistance = length(p.xz - c.xz);
        dist = max(verticalDistance - h, horizontalDistance - r);
    } else {
        float verticalDistance = abs(p.z - c.z);
        float horizontalDistance = length(p.xy - c.xy);
        dist = max(verticalDistance - h, horizontalDistance - r);
        id = button_id;
    }

    return vec2(dist, id);
}

/*
 * Cone SDF. 
 *
 * Parameters:
 *  - p: The point in 3D space to evaluate.
 *  - c: The center of the cone base.
 *  - t: The angle of the cone.
 *  - h: The height of the cone.
 *
 * Returns:
 *  - A vec2 containing:
 *    - Signed distance to the surface of the cone.
 *    - An identifier for material type.
 */
vec2 Cone(vec3 p, vec3 c, float t, float h) 
{
    float dist = MAX_DIST;
    float cone_id = 4.0; 

    // Shift the input point `p` so that `c` is the origin
    p -= c;

    // Rotate the cone around the y-axis
    p = vec3(p.x, -p.z, p.y); 

    vec2 cxy = vec2(sin(t), cos(t)); 
    vec2 q = h * vec2(cxy.x / cxy.y, -1.0);
    vec2 w = vec2( length(p.xz), p.y );
    vec2 a = w - q * clamp(dot(w, q) / dot(q, q), 0.0, 1.0);
    vec2 b = w - q * vec2(clamp(w.x / q.x, 0.0, 1.0), 1.0);
    float k = sign(q.y);
    float d = min(dot(a, a), dot(b, b));
    float s = max(k * (w.x * q.y - w.y * q.x), k * (w.y - q.y));
    dist = sqrt(d) * sign(s);

    return vec2(dist, cone_id);
}

/*
 * Snowman SDF.
 *
 * Parameters:
 *  - p: The point in 3D space to evaluate.
 *
 * Returns:
 *  - A vec2 containing:
 *    - Signed distance to the surface of the snowman.
 *    - An identifier for material type.
 */
vec2 Snowman(vec3 p) 
{
    float dist = MAX_DIST;
    float id = 2.0;

    vec2 base = Sphere(p, vec3(0, 1, 5), 1.);
    vec2 middle = Sphere(p, vec3(0, 2.2, 5), .6);
    vec2 top = Sphere(p, vec3(0, 3., 5), .4);
    
    vec2 btn1 = Cylinder(p, vec3(0, 2.5, 4.47), .03, .03, true);
    vec2 btn2 = Cylinder(p, vec3(0, 2.3, 4.4), .03, .03, true);
    vec2 btn3 = Cylinder(p, vec3(0, 2.1, 4.4), .03, .03, true);
    
    vec2 eye1 = Sphere(p, vec3(-.1, 3.05, 4.63), .05);
    vec2 eye2 = Sphere(p, vec3(.1, 3.05, 4.63), .05);

    vec2 nose = Cone(p, vec3(0, 3, 4.2), radians(5.), 1.);

    vec3 hatPos = vec3(0, 3.5 + cos(time*3.)/3., 5);
    vec2 h1 = Cylinder(p, hatPos + vec3(0, .23, 0), .3, .2, false);
    vec2 h2 = Cylinder(p, hatPos, .5, .02, false);

    float k = .04;
    dist = unionSDF(nose.x, 
        unionSDF(eye2.x, 
        unionSDF(eye1.x, 
        unionSDF(btn3.x, 
        unionSDF(btn2.x, 
        unionSDF(btn1.x, 
        unionSDF(top.x, 
        unionSDF(base.x, 
        unionSDF(middle.x, 
        smoothUnionSDF(h2.x, h1.x, k))))))))));
    
    bool isEyeOrButton = dist == btn1.x || dist == btn2.x || dist == btn3.x || dist == eye1.x || dist == eye2.x;
    if (isEyeOrButton) id = 5.;
    if (dist == nose.x) id = nose.y;
    if (abs(dist - h1.x) < k || abs(dist - h2.x) < k) id = h1.y;

    return vec2(dist, id);
}

/*
 * Helper: gets the distance and material ID to the closest surface in the scene.
 */
vec2 getSceneDist(vec3 p) {
    
    vec2 snowman = Snowman(p);
    vec2 plane = Plane(p);
    
    float dist = smoothUnionSDF(snowman.x, plane.x, .02);
    float id = getMaterial(snowman, plane);

    return vec2(dist, id);
}

/*
 * Performs ray marching to determine the closest surface intersection.
 *
 * Parameters:
 *  - ro: Ray origin.
 *  - rd: Ray direction.
 *
 * Returns:
 *  - A vec2 containing:
 *    - Distance to the closest surface intersection.
 *    - material ID of the closest intersected surface.
 */
vec2 rayMarch(vec3 ro, vec3 rd) {
	float d = 0.;
	float id = 0.;
 
    vec2 result;
    float nextDistance = 0.;
    vec3 point = ro;
    for (int i = 0; ; i++) {
        point += rd * nextDistance;
        result = getSceneDist(point);
        nextDistance = result.x;
        id = result.y;
        
        float dist = distance(ro, point);
        if (nextDistance < HIT_DIST) {
            d = dist;
            break;
        } else if (dist > MAX_DIST || i == MAX_STEPS) {
            d = MAX_DIST;
            id = 0.;
            break;
        }
    }

    return vec2(d, id);
}

/* 
 * Helper: computes surface normal
 */
vec3 getNormal(vec3 p) {
	float d = getSceneDist(p).x;
    vec2 e = vec2(.01, 0);
    
    vec3 n = d - vec3(
        getSceneDist(p-e.xyy).x,
        getSceneDist(p-e.yxy).x,
        getSceneDist(p-e.yyx).x);
    
    return normalize(n);
}

/*
 * Helper: gets surface color.
 */
vec3 getColor(vec3 p, float id) {
    
    vec3 lightPos = vec3(3, 5, 2);
    vec3 l = normalize(lightPos - p);
    vec3 n = getNormal(p);
    
    float diffuse = clamp(dot(n, l), 0.2, 1.);

    // Perform shadow check using ray marching 
    { 
        // NOTE: Comment out to improve render performance
        float d = rayMarch(p + n * HIT_DIST * 2., l).x;
        if (d < length(lightPos - p)) diffuse *= 0.1; 
    }

    vec3 diffuseColor;

    switch (int(id)) {
        case 0: // background sky color (ray missed all surfaces) 
            diffuseColor = vec3(.3, .6, 1.);
            diffuse = .97;
            break;
        case 1: // plane (snow)
            diffuseColor = vec3(1, .98, .98);
            break;
        case 2: // snowman (slightly darker snow)
            diffuseColor = vec3(1, .9, .9);
            break;
        case 3: // hat
            diffuseColor = vec3(.8, .05, 0);
            break;
        case 4: // nose
            diffuseColor = vec3(.8, .2, .0);
            break;
        case 5: // eye/buttons
            diffuseColor = vec3(.1, .1, .1);
            break;
    }

    vec3 ambientColor = vec3(.9, .9, .9);
    float ambient = .1;

    return ambient * ambientColor + diffuse * diffuseColor;
}

/*
 * Helper: camera matrix.
 */
mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main() {

    // Get the fragment coordinate in screen space
    vec2 fragCoord = gl_FragCoord.xy;
    
    // normalize to UV coordinates
    vec2 uv = (fragCoord - 0.5 * resolution.xy) / resolution.y;

    // Look-at target (the point the camera is focusing on)
    vec3 ta = vec3(0, 1, 5); 

    // Camera position 
    // NOTE: modify camera for development
    //vec3 ro = vec3(0, 3, -1); // static 
     vec3 ro = ta + vec3(8.0 * cos(0.7 * time), 3.0, 8.0 * sin(0.7 * time)); // dynamic camera

    // Compute the camera's coordinate frame
    mat3 ca = setCamera(ro, ta, 0.0); 

    // Compute the ray direction for this pixel with respect ot camera frame
    vec3 rd = ca * normalize(vec3(uv.x, uv.y, 1));

    // Perform ray marching to find intersection distance and surface material ID
    vec2 dist = rayMarch(ro, rd); 
    float d = dist.x; 
    float id = dist.y; 

    // Surface intersection point
    vec3 p = ro + rd * d;

    // Compute surface color
    vec3 color = getColor(p, id); 

    // Apply gamma correction to adjust brightness
    color = pow(color, vec3(0.4545)); 

    // Output the final color to the fragment shader
    gl_FragColor = vec4(color, 1.0); 
}
