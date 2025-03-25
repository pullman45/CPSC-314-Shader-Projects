uniform vec3 orbPosition;
uniform float orbRadius;

// The value of the "varying" variable is interpolated between values computed in the vertex shader
// The varying variable we passed from the vertex shader is identified by the 'in' classifier
in float intensity;
in vec4 worldPosition;
in float isInLevel;

void main() {
	float redComponent = 1.0;
	vec4 orbPos = vec4(orbPosition, 1.0);

	if (distance(worldPosition, orbPos) < orbRadius) {
		redComponent = 0.0;
	}
	
	// check if vertices are in level (avg must be equal to 1 else smaller)
	// since this is a float we check the difference within an epsilon
	if (isInLevel == 1.0) {
		gl_FragColor = vec4(vec3(1.0,0.0,1.0), 1.0);
	} else {
		gl_FragColor = vec4(intensity*vec3(redComponent,1.0,1.0), 1.0); 
	}
}
