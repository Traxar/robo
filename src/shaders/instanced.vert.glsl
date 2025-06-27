#version 330

// Input vertex attributes
in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec3 vertexNormal;

in mat4 instanceTransform;
//? in vec4 instanceColor

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
    //fragPosition = vec3(instanceTransform * vec4(vertexPosition, 1.0));

    vec4 instanceColor = vec4(instanceTransform[0].w,instanceTransform[1].w,instanceTransform[2].w,instanceTransform[3].w);
    mat4x3 instanceTransform_;
    instanceTransform_[0] = vec3(instanceTransform[0].xyz);
    instanceTransform_[1] = vec3(instanceTransform[1].xyz);
    instanceTransform_[2] = vec3(instanceTransform[2].xyz);
    instanceTransform_[3] = vec3(instanceTransform[3].xyz);

    fragTexCoord = vertexTexCoord;
    fragColor = instanceColor;
    //fragNormal = vertexNormal;

    // Calculate final vertex position, note that we multiply mvp by instanceTransform
    gl_Position = mvp * vec4(instanceTransform_ * vec4(vertexPosition,1.0), 1.0);
}
