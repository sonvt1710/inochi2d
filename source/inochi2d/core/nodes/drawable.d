module inochi2d.core.nodes.drawable;
import inochi2d.math;
import inochi2d.core.nodes;
import bindbc.opengl;
import std.exception;

private GLuint drawableVAO;

package(inochi2d) {
    void inInitDrawable() {
        glGenVertexArrays(1, &drawableVAO);
    }
}

/**
    Nodes that are meant to render something in to the Inochi2D scene
    Other nodes don't have to render anything and serve mostly other 
    purposes.

    The main types of Drawables are Parts and Masks
*/
abstract class Drawable : Node {
private:
    void updateIndices() {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, data.indices.length*ushort.sizeof, data.indices.ptr, GL_STATIC_DRAW);
    }

    void updateVertices() {

        // Important check since the user can change this every frame
        enforce(
            vertices.length == data.vertices.length, 
            "Data length mismatch, if you want to change the mesh you need to change its data with Part.rebuffer."
        );
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, vertices.length*vec2.sizeof, vertices.ptr, GL_DYNAMIC_DRAW);
    }

protected:
    /**
        OpenGL Index Buffer Object
    */
    GLuint ibo;

    /**
        OpenGL Vertex Buffer Object
    */
    GLuint vbo;

    /**
        The mesh data of this part

        NOTE: DO NOT MODIFY!
        The data in here is only to be used for reference.
    */
    MeshData data;

    /**
        Binds the internal vertex array for rendering
    */
    final void bindVertexArray() {

        // Bind our vertex array
        glBindVertexArray(drawableVAO);
    }

    /**
        Binds Index Buffer for rendering
    */
    final void bindIndex() {
        // Bind element array and draw our mesh
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
        glDrawElements(GL_TRIANGLES, cast(int)data.indices.length, GL_UNSIGNED_SHORT, null);
    }

    abstract void renderMask();

public:

    /**
        Constructs a new drawable surface
    */
    this(MeshData data, Node parent = null) {
        this(data, inCreateUUID(), parent);
    }

    /**
        Constructs a new drawable surface
    */
    this(MeshData data, uint uuid, Node parent = null) {
        super(uuid, parent);
        this.data = data;

        // Set the deformable points to their initial position
        this.vertices = data.vertices.dup;

        // Generate the buffers
        glGenBuffers(1, &vbo);
        glGenBuffers(1, &ibo);

        // Update indices and vertices
        this.updateIndices();
        this.updateVertices();
    }

    /**
        The mesh's vertices
    */
    vec2[] vertices;

    /**
        Updates the drawable
    */
    override
    void update() {
        this.updateVertices();
    }

    /**
        Returns the mesh data for this Part.
    */
    final MeshData getMesh() {
        return this.data;
    }

    /**
        Changes this mesh's data
    */
    void rebuffer(MeshData data) {
        this.data = data;
        this.updateIndices();
        this.updateVertices();
    }
    
    /**
        Resets the vertices of this drawable
    */
    final void reset() {
        vertices[] = data.vertices;
    }

}

/**
    Begins a mask

    This causes the next draw calls until inBeginMaskContent/inBeginDodgeContent or inEndMask 
    to be written to the current mask.

    This also clears whatever old mask there was.
*/
void inBeginMask() {

    // Enable and clear the stencil buffer so we can write our mask to it
    glEnable(GL_STENCIL_TEST);
    glClear(GL_STENCIL_BUFFER_BIT);
}

/**
    End masking

    Once masking is ended content will no longer be masked by the defined mask.
*/
void inEndMask() {

    // We're done stencil testing, disable it again so that we don't accidentally mask more stuff out
    glStencilMask(0xFF);
    glStencilFunc(GL_ALWAYS, 1, 0xFF);   
    glDisable(GL_STENCIL_TEST);
}

/**
    Stars masking content

    NOTE: This have to be run within a inBeginMask and inEndMask block!
*/
void inBeginMaskContent() {
    glStencilFunc(GL_EQUAL, 1, 0xFF);
    glStencilMask(0x00);
}

/**
    Stars dodging content

    NOTE: This have to be run within a inBeginMask and inEndMask block!
*/
void inBeginDodgeContent() {

    // This tells OpenGL that as long as the stencil buffer is 0
    // in other words that the dodge texture was not drawn there
    // that it's okay to draw there.
    //
    // This effectively makes so that the dodge reference cuts out
    // a part of this part's texture where they overlap.
    glStencilFunc(GL_NOTEQUAL, 1, 0xFF);
    glStencilMask(0x00);
}