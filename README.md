# Multitouch diagram
Draws a round diagram around three touchpoints.

Try the wasm build at https://dabulla.github.io/multitouch-diagram/

A native windows/linux/android build will have even better performance.

This project consists of a minimal cpp boilerplate to load qml.
In qml two shaders are used to perform some drawing on the graphicscard.
Moreover qml will draw all elements using OpenGL/WebGL.

The first thee points of the Multitouch Area are used. Next the center point is calculated.
Using the first touchpoint, an angle ist calculated to start drawing the diagram (There also is code to choose the touchpoint furthes away from the others).
The diagram is drawn as a normal barchart and then bend using a shader.
The shader uses a smaler texture size for better performance.
The bars of the bar chart are qml items using a repeater. This way items can easily be animated.
Each bar can have a unique color. Color in the example is picked using a gradient as a texture for the bars shader.
