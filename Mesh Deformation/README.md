Georgy Zhuravlev
81959512
georgy03

# First feature
This is just three lines of code in the raymarching shader that makes the hat go up and down.

# Second feature
This is a sphere-trail feature. Specifically, when the sphere moves, the vertex shader deforms the sphere
so that all the vertices on the backside of the sphere get shifted to make the illusion of a trail
following the sphere.

# Third feature
This feature maps each point on the sphere to a point on a plane. First I translate each
vertex of the sphere outward to make a cylinder, then I do a conversion from
cartesian coordinates to cylindrical coordinates to get the angle theta of each vertex
from the meridian. In this case the meridian is defined as the set of points in object
space that satisfy <0, y, 1>, where y is any real number.
Using this angle of theta, we set x = h*theta, where h is the horizontal scale of the map.
So, after projecting onto the local xy-plane, the resulting position of the vertex in local 
space is < h*theta, ky, 0 >, where k is the vertical scale of the map.