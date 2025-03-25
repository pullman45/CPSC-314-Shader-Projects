/*
 * UBC CPSC 314
 * Assignment 3 Template
 */
import { setup, createScene, createRayMarchingScene, loadAndPlaceGLB, loadAndPlaceOBJ } from './js/setup.js';
import * as THREE from './js/three.module.js';
import { SourceLoader } from './js/SourceLoader.js';
import { THREEx } from './js/KeyboardState.js';

// Setup the renderer
// You should look into js/setup.js to see what exactly is done here.
const { renderer, canvas } = setup();

/////////////////////////////////
//   YOUR WORK STARTS BELOW    //
/////////////////////////////////

const speed = 3;
const xbound = 5.75;
const ybound = 3.4;
const ballVelocity = new THREE.Vector2(1*speed, 2*speed);

// Uniforms - Pass these into the appropriate vertex and fragment shader files
const spherePosition = { type: 'v3', value: new THREE.Vector3(0.0, 0.0, 0.0) };
const sphereTrail = { type: 'v3', value: new THREE.Vector3(0.0, 0.0, 0.0) };
const sphereMode = { type: 'i', value: 0 };
const hScale = { type: 'f', value: 2 };
const vScale = { type: 'f', value: 4 };
const ballPos = { type: 'v2', value: new THREE.Vector2(0.0, 0.0) };
const barPos = { type: 'v2', value: new THREE.Vector2(0.0, -ybound + .3) };

const ambientColor = { type: 'c', value: new THREE.Color(0.0, 0.0, 1.0) };
const diffuseColor = { type: 'c', value: new THREE.Color(0.0, 1.0, 1.0) };
const specularColor = { type: 'c', value: new THREE.Color(1.0, 1.0, 1.0) };

const kAmbient = { type: "f", value: 0.5 };
const kDiffuse = { type: "f", value: 0.6 };
const kSpecular = { type: "f", value: 1.0 };
const shininess = { type: "f", value: 50.0 };
const ticks = { type: "f", value: 0.0 };
const resolution =  { type: 'v3', value: new THREE.Vector3() };

const sphereLight = new THREE.PointLight(0xffffff, 200);

// Shader materials
const sphereMaterial = new THREE.ShaderMaterial({
  uniforms: {
    spherePosition: spherePosition,
    sphereTrail: sphereTrail,
    horizontalScale: hScale,
    verticalScale: vScale,
    ballPosition: ballPos,
    barPosition: barPos,
    mode: sphereMode
  }
});

const blinnPhongMaterial = new THREE.ShaderMaterial({
  uniforms: {
    spherePosition: spherePosition,
    ambientColor: ambientColor,
    diffuseColor: diffuseColor,
    specularColor: specularColor,
    kAmbient: kAmbient,
    kDiffuse: kDiffuse,
    kSpecular: kSpecular,
    shininess: shininess
  }
});

const rayMarchingMaterial = new THREE.ShaderMaterial({
  uniforms: {
    time: ticks,
    resolution: resolution,
  }
});

const helmetAlbedoMap = new THREE.TextureLoader().load( 'gltf/Default_albedo.jpg' );
helmetAlbedoMap.colorSpace = THREE.SRGBColorSpace;
helmetAlbedoMap.flipY = false;
helmetAlbedoMap.wrapS = 1000;
helmetAlbedoMap.wrapT = 1000;

const helmetAOMap = new THREE.TextureLoader().load( 'gltf/Default_AO.jpg' );
helmetAOMap.flipY = false;
helmetAOMap.wrapS = 1000;
helmetAOMap.wrapT = 1000;

const helmetEmissiveMap = new THREE.TextureLoader().load( 'gltf/Default_emissive.jpg' );
helmetEmissiveMap.colorSpace = THREE.SRGBColorSpace;
helmetEmissiveMap.flipY = false;
helmetEmissiveMap.wrapS = 1000;
helmetEmissiveMap.wrapT = 1000;

const helmetNormalMap = new THREE.TextureLoader().load( 'gltf/Default_normal.jpg' );
helmetNormalMap.flipY = false;
helmetNormalMap.wrapS = 1000;
helmetNormalMap.wrapT = 1000;

const helmetMetalRoughnessMap = new THREE.TextureLoader().load( 'gltf/Default_metalRoughness.jpg' );
helmetMetalRoughnessMap.colorSpace = THREE.SRGBColorSpace;
helmetMetalRoughnessMap.flipY = false;
helmetMetalRoughnessMap.wrapS = 1000;
helmetMetalRoughnessMap.wrapT = 1000;

const helmetPBRMaterial = new THREE.MeshStandardMaterial({
  map: helmetAlbedoMap,
  aoMap: helmetAOMap,
  emissive: new THREE.Color(0xffffff),
  emissiveMap: helmetEmissiveMap,
  normalMap: helmetNormalMap,
  metalnessMap: helmetMetalRoughnessMap,
  metalness: 1.0,
  roughness: .05
});

// Load shaders
const shaderFiles = [
  'glsl/sphere.vs.glsl',
  'glsl/sphere.fs.glsl',
  'glsl/blinn_phong.vs.glsl',
  'glsl/blinn_phong.fs.glsl',
  'glsl/raymarching.vs.glsl',
  'glsl/raymarching.fs.glsl',
];

new SourceLoader().load(shaderFiles, function (shaders) {
  sphereMaterial.vertexShader = shaders['glsl/sphere.vs.glsl'];
  sphereMaterial.fragmentShader = shaders['glsl/sphere.fs.glsl'];

  blinnPhongMaterial.vertexShader = shaders['glsl/blinn_phong.vs.glsl'];
  blinnPhongMaterial.fragmentShader = shaders['glsl/blinn_phong.fs.glsl'];

  rayMarchingMaterial.vertexShader = shaders['glsl/raymarching.vs.glsl'];
  rayMarchingMaterial.fragmentShader = shaders['glsl/raymarching.fs.glsl'];
});

// Define the shader modes
const shaders = {
  BLINNPHONG: { key: 0, material: blinnPhongMaterial },
  RAYMARCHING: { key: 1, material: rayMarchingMaterial },
  PBR: { key: 2, material: helmetPBRMaterial },
};

let mode = shaders.BLINNPHONG.key; // Default

// Set up scenes
let scenes = [];
for (let shader of Object.values(shaders)) {
  // Create the scene
  let scene, camera, worldFrame;
  if (shader.material == rayMarchingMaterial) {
    ({ scene, camera } = createRayMarchingScene(canvas, renderer));
    const plane = new THREE.PlaneGeometry(2, 2);
    scene.add(new THREE.Mesh(plane, shaders.RAYMARCHING.material));
  } else {
    ({ scene, camera, worldFrame } = createScene(canvas, renderer));
    
    // Create the main sphere geometry (light source)
    // https://threejs.org/docs/#api/en/geometries/SphereGeometry
    const sphereGeometry = new THREE.SphereGeometry(1.0, 32.0, 32.0);
    const sphere = new THREE.Mesh(sphereGeometry, sphereMaterial);
    sphere.position.set(0.0, 1.5, 0.0);
    sphere.parent = worldFrame;
    scene.add(sphere);
  }

  // Load the helmet, for scene key 3.
  if(shader.material == helmetPBRMaterial){
    
    loadAndPlaceGLB('gltf/DamagedHelmet.glb', shaders.PBR.material, function(helmet) {
      helmet.position.set(0, 0, -10.0);
      helmet.scale.set(7, 7, 7);
      helmet.parent = worldFrame;
      scene.add(helmet);
    });

    const ambientLight = new THREE.AmbientLight(0xffffff, 3.0);
    scene.add(ambientLight);

    sphereLight.parent = worldFrame;
    scene.add(sphereLight);
  } else {
    // If there's no helmet, then only place the snowman. i.e. key 1, 2
    loadAndPlaceOBJ('obj/snowman.obj', shader.material, function (snowman) {
      snowman.position.set(0.0, 0.0, -10.0);
      snowman.rotation.y = 0.0;
      snowman.scale.set(1.0e-3, 1.0e-3, 1.0e-3);
      snowman.parent = worldFrame;
      scene.add(snowman);
    });
  }

  scenes.push({ scene, camera });
}

let dt = 0;

// Listen to keyboard events.
const keyboard = new THREEx.KeyboardState();
function checkKeyboard() {

  if (keyboard.pressed("left")) {
    barPos.value.x -= .1;
  } else if (keyboard.pressed("right")) {
    barPos.value.x += .1;
  }

  if (keyboard.pressed("T")) {
    sphereMode.value = 0;
  } else if (keyboard.pressed("M")) {
    sphereMode.value = 1;
  }

  if (keyboard.pressed("1"))
    mode = shaders.BLINNPHONG.key;
  else if (keyboard.pressed("2"))
    mode = shaders.RAYMARCHING.key;
  else if (keyboard.pressed("3"))
    mode = shaders.PBR.key;

  let oldPos = spherePosition.value.clone();
  if (mode != shaders.RAYMARCHING.key) {
    if (keyboard.pressed("W"))
      spherePosition.value.z -= 0.3;
    else if (keyboard.pressed("S"))
      spherePosition.value.z += 0.3;

    if (keyboard.pressed("A"))
      spherePosition.value.x -= 0.3;
    else if (keyboard.pressed("D"))
      spherePosition.value.x += 0.3;

    if (keyboard.pressed("Q"))
      spherePosition.value.y -= 0.3;
    else if (keyboard.pressed("E"))
      spherePosition.value.y += 0.3;

    // normalize change in sphere position
    spherePosition.value.copy(oldPos.add(spherePosition.value.clone().sub(oldPos).normalize().multiplyScalar(.3)));
    
    let spherePos = spherePosition.value.clone();
    let trail = sphereTrail.value.clone();  
    let displacement = spherePos.clone().sub(trail);

    // move the position of the trail towards sphere position at speed of 5*displacement.length() units/second
    trail.add(displacement.clone().normalize().multiplyScalar(displacement.length() * 5 * dt));
    sphereTrail.value.copy(trail);
    sphereLight.position.set(spherePosition.value.x, spherePosition.value.y, spherePosition.value.z);
  } else {
    const canvas = renderer.domElement;
    resolution.value.set(canvas.width, canvas.height, 1);
  }

  // The following tells three.js that some uniforms might have changed
  sphereMaterial.needsUpdate = true;
  blinnPhongMaterial.needsUpdate = true;
  helmetPBRMaterial.needsUpdate = true;
  rayMarchingMaterial.needsUpdate = true;
}

let clock = new THREE.Clock;

function isBallHittingBat(ball, bat) {
  let diff = bat.sub(ball);
  let isWithinX = Math.abs(diff.x) < 1;
	let isWithinY = Math.abs(diff.y) < .7;
  return isWithinX && isWithinY;
}

function updateBall(dt) {
  if (sphereMode.value == 0) return;

  let pos = ballPos.value.clone();
  ballPos.value.x += ballVelocity.x * dt;
  ballPos.value.y += ballVelocity.y * dt;;
  
  if (pos.x > xbound) {
    ballVelocity.x = -1 * speed;
  } else if (pos.y > ybound) {
    ballVelocity.y = -1 * speed;
  } else if (pos.x < -xbound) {
    ballVelocity.x = 1 * speed;
  } else if (pos.y < -ybound) {
    ballVelocity.y = 0;
  }

  if (isBallHittingBat(pos, barPos.value.clone())) {
    ballVelocity.y = 1 * speed;
  }
}

// Setup update callback
function update() {
  checkKeyboard();
  updateBall(dt);
  dt = clock.getDelta();
  ticks.value += dt;

  // Requests the next update call, this creates a loop
  requestAnimationFrame(update);
  const { scene, camera } = scenes[mode];
  renderer.render(scene, camera);
}

// Start the animation loop.
update();
