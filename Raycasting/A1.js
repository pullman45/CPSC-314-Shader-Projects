/*
 * UBC CPSC 314, Vjan2024
 * Assignment 1 Template
 */

// Setup and return the scene and related objects.
// You should look into js/setup.js to see what exactly is done here.
const {
  renderer,
  scene,
  camera,
  worldFrame,
} = setup();

/////////////////////////////////
//   YOUR WORK STARTS BELOW    //
/////////////////////////////////

// Initialize uniform
const orbPosition = { type: 'v3', value: new THREE.Vector3(0.0, 1.0, 0.0) };
const orbRadius = { type: 'float', value: 3.0 };
const pointerHit = { type: 'v3', value: new THREE.Vector3()};

/** Axes are labelled as such:
 *  - 0: x axis
 *  - 1: y axis
 *  - 2: z axis
 */
const levelAxis = { type: 'int', value: 0};

/** List of modes:
 *  - 0: Default
 *  - 1: Normal cursor
 *  - 3: Level curve
 */
const mode = { type: 'int', value: 0};

// Materials: specifying uniforms and shaders
const armadilloMaterial = new THREE.ShaderMaterial({
  uniforms: {
    orbPosition: orbPosition,
    orbRadius: orbRadius,
    mode: mode,
    pointerHit: pointerHit,
    levelAxis: levelAxis
  }
});
const sphereMaterial = new THREE.ShaderMaterial({
  uniforms: {
    orbPosition: orbPosition
  }
});

// Load shaders.
const shaderFiles = [
  'glsl/armadillo.vs.glsl',
  'glsl/armadillo.fs.glsl',
  'glsl/sphere.vs.glsl',
  'glsl/sphere.fs.glsl'
];

new THREE.SourceLoader().load(shaderFiles, function (shaders) {
  armadilloMaterial.vertexShader = shaders['glsl/blinn_phong.vs.glsl'];
  armadilloMaterial.fragmentShader = shaders['glsl/blinn_phong.fs.glsl'];

  sphereMaterial.vertexShader = shaders['glsl/sphere.vs.glsl'];
  sphereMaterial.fragmentShader = shaders['glsl/sphere.fs.glsl'];
})

// Load and place the Armadillo geometry
// Look at the definition of loadOBJ to familiarize yourself with how each parameter
// affects the loaded object.
loadAndPlaceOBJ('obj/armadillo.obj', armadilloMaterial, function (armadillo) {
  armadillo.position.set(0.0, 5.3, -8.0);
  armadillo.rotation.y = Math.PI;
  armadillo.scale.set(0.1, 0.1, 0.1);
  armadillo.parent = worldFrame;
  scene.add(armadillo);
});

loadAndPlaceOBJ('obj/bucket_hat.obj', armadilloMaterial, function (hat) {
  hat.position.set(0.1, 13.5, -6.5);
  hat.rotation.x = Math.PI / 7;
  hat.scale.set(5.0, 5.0, 5.0);
  hat.parent = worldFrame;
  scene.add(hat);
});


// Create the sphere geometry
// https://threejs.org/docs/#api/en/geometries/SphereGeometry
// TODO: Make the radius of the orb a variable
const sphereGeometry = new THREE.SphereGeometry(1.0, 32.0, 32.0);
const sphere = new THREE.Mesh(sphereGeometry, sphereMaterial);
sphere.position.set(0.0, 1.0, 0.0);
sphere.parent = worldFrame;
scene.add(sphere);

const sphereLight = new THREE.PointLight(0xffffff, 1, 100);
scene.add(sphereLight);

// init pointer arrow
const arrow = new THREE.ArrowHelper(new THREE.Vector3(), new THREE.Vector3(0, 1, 0), 2, 0x00ffff, .8, .3);
arrow.name = 'Arrow';
arrow.parent = worldFrame;
scene.add(arrow);

// init pointer sphere
const pointerMaterial = new THREE.Material();
const pointerSphereGeometry = new THREE.SphereGeometry(.1, 32.0, 32.0);
const pointerSphere = new THREE.Mesh(pointerSphereGeometry, sphereMaterial);
pointerSphere.position.set(0.0, 10.0, 0.0);
pointerSphere.name = 'Pointer'
pointerSphere.parent = worldFrame;
scene.add(pointerSphere);

// init raycasting variables
const pointer = new THREE.Vector2();
const raycaster = new THREE.Raycaster();

const onMouseMove = (event) => {
  pointer.x = 2 * (event.clientX / window.innerWidth) - 1;
	pointer.y = -2 * (event.clientY / window.innerHeight) + 1;
};

window.addEventListener('pointermove', onMouseMove);

// Listen to keyboard events.
const keyboard = new THREEx.KeyboardState();
function checkKeyboard() {
  if (keyboard.pressed("W"))
    orbPosition.value.z -= 0.3;
  else if (keyboard.pressed("S"))
    orbPosition.value.z += 0.3;

  if (keyboard.pressed("A"))
    orbPosition.value.x -= 0.3;
  else if (keyboard.pressed("D"))
    orbPosition.value.x += 0.3;

  if (keyboard.pressed("Q"))
    orbPosition.value.y -= 0.3;
  else if (keyboard.pressed("E"))
    orbPosition.value.y += 0.3;

  // mode switching
  if (keyboard.pressed("R"))
    mode.value = 0;
  else if (keyboard.pressed("N"))
    mode.value = 1;
  else if (keyboard.pressed("O"))
    mode.value = 2;
  
  if (keyboard.pressed("X")) {
    mode.value = 3;
    levelAxis.value = 0;
  } else if (keyboard.pressed("Y")) {
    mode.value = 3;
    levelAxis.value = 1;
  } else if (keyboard.pressed("Z")) {
    mode.value = 3;
    levelAxis.value = 2;
  }

  // The following tells three.js that some uniforms might have changed
  armadilloMaterial.needsUpdate = true;
  sphereMaterial.needsUpdate = true;

  // Move the sphere light in the scene. This allows the floor to reflect the light as it moves.
  sphereLight.position.set(orbPosition.value.x, orbPosition.value.y, orbPosition.value.z);
  sphere.position.set(orbPosition.value.x, orbPosition.value.y, orbPosition.value.z);
}

function levelCursorMode() {
	raycaster.setFromCamera(pointer, camera);

	const intersects = raycaster.intersectObjects(scene.children, true);
  for (var i = 0; i < intersects.length; i++) {
    var intersection = intersects[0];
    if (intersection.face) {
      pointerHit.value = intersection.point;
      break;
    }
  }
}

function normalCursorMode() {
	raycaster.setFromCamera(pointer, camera);

	const intersects = raycaster.intersectObjects(scene.children, true);
  for (var i = 0; i < intersects.length; i++) {
    var intersection = intersects[0];
    if (intersection.object.name != "Pointer" && intersection.face) {
      pointerHit.value = intersection.point;
      var point = intersection.point;
      var normal = intersection.face.normal.transformDirection(intersection.object.matrixWorld);
      pointerSphere.position.set(point.x, point.y, point.z);
      arrow.position.set(point.x, point.y, point.z);
      arrow.setDirection(normal);
      break;
    }
  }
}

// Setup update callback
function update() {
  checkKeyboard();
  switch (mode.value) {
    case 1: // Normal Cursor mode
      normalCursorMode();
      break;
    case 2:
      break;
    case 3:
      levelCursorMode();
       break;
  }

  // Requests the next update call, this creates a loop
  requestAnimationFrame(update);
  renderer.render(scene, camera);
}

// Start the animation loop.
update();
