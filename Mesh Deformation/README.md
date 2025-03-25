# First feature: Sphere Trail
Implemented a dynamic sphere-trail effect by first rotating the sphere 90 degrees across its local X-axis. I then applied the camera's rotation to ensure the bottom of the sphere always faces the camera. To create the trail, I projected the sphere's velocity onto the local xz-plane to avoid artifacts caused by movement along the camera's local z-axis. For each pixel with a positive y-coordinate in object space, I calculated its displacement based on the projected velocity. This is akin to taking horizontal slices of the sphere and translating them along a shared axis. The further a slice is from the center (i.e., the larger its local y-coordinate), the more it is displaced horizontally. The top layer of the sphere is displaced by an amount equal to the sphereTrail uniform, resulting in a smooth, continuous trail effect as the sphere moves.

To activate the sphere trail, press the T key, then move the sphere using the WASD keys. This will trigger the trail effect and allow you to control the sphere while observing the trail in action.

# Second Feature: Sphere-to-Plane Mapping
Mapped each vertex of a sphere to a point on a plane by focusing on the horizontal angle (theta) relative to the meridian. The horizontal angle θ (theta) from the meridian was used to compute the x-coordinate of each vertex, scaled by a horizontal factor (h). The final mapped position on the plane was calculated as <hθ, ky, 0>, where k is the vertical scale of the map.

To activate the sphere-to-plane mapping mode, press the M key. Once the mode is enabled, use the arrow keys to move the paddle on the newly created canvas, allowing you to interact with the mapped sphere.
