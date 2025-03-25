uniform vec3 spherePosition;
uniform int mode;

uniform float horizontalScale;
uniform float verticalScale;

uniform vec2 ballPosition;
uniform vec2 barPosition;

in float height;
in vec3 pos;
in vec3 mappedPos;

vec3 getColour(bool isShaded) {
	return isShaded ? vec3(1., 1., 1.) : vec3(0., 0., .7);
}

bool Circle(vec2 point) {
	vec2 diff = point.xy - mappedPos.xy;
	return length(diff) < .5;
}

bool Bar(vec2 point) {
	float xTolerance = 1.;
	float yTolerance = .25;

	vec2 diff = point.xy - mappedPos.xy;
	bool isWithinX = abs(diff.x) < xTolerance;
	bool isWithinY = abs(diff.y) < yTolerance;
	
	return isWithinX && isWithinY;
}

vec3 unionColours(bool[2] point) {
	bool shaded = false;
	for (int i = 0; i < 2; i++) {
		if (point[i]) {
			shaded = true;
			break;
		}
	}
	return getColour(shaded);
}
//Circle(vec2(5.75, 3.5))
void main() {
	bool[2] colourValues;
	colourValues[0] = Circle(ballPosition);
	colourValues[1] = Bar(barPosition);

	switch(mode) {
		case 0:
			gl_FragColor = vec4(1.0, 1.0 - .7*height, 0.0, 1.0);
			break;
		case 1:
			gl_FragColor = vec4(unionColours(colourValues), 1.0);
			break;
	}
}
