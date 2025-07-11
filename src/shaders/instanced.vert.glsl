#version 330

// Input vertex attributes
in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec3 vertexNormal;

in mat4x3 instanceTransform;
in vec4 instanceColor;

// Input uniform values
uniform mat4 mvp;

// Output vertex attributes (to fragment shader)
//out vec3 fragPosition;
out vec2 fragTexCoord;
out vec4 fragColor;
//out vec3 fragNormal;

void main()
{
    // Send vertex attributes to fragment shader
    // fragPosition = vec3(instanceTransform * vec4(vertexPosition, 1.0));
    fragTexCoord = vertexTexCoord;
    fragColor = instanceColor;
    // fragNormal = vertexNormal;

    // Calculate final vertex position, note that we multiply mvp by instanceTransform
    gl_Position = mvp * vec4(instanceTransform * vec4(vertexPosition, 1.0), 1);
}
