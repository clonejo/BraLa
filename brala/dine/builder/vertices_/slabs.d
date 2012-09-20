module brala.dine.builder.vertices_.slabs;

private {
    import std.math : abs;

    import brala.dine.builder.tessellator : Vertex;
    import brala.dine.builder.vertices : CubeSideData;
    import brala.dine.builder.vertices_.util;
}


struct SlabTextureSlice {
    enum byte FB = 16;
    enum byte HB = 8;
    
    ubyte x;
    ubyte y;

    alias texcoords this;

    this(ubyte lower_left_x, ubyte lower_left_y)
        in { assert(abs(lower_left_x*FB) <= ubyte.max && abs(lower_left_y*FB) <= ubyte.max); }
        body {
            x = cast(byte)(lower_left_x*FB+HB);
            y = cast(byte)(lower_left_y*FB-HB);
        }

    pure:
    @property ubyte[2][4] texcoords() {
        return [[cast(ubyte)(x-HB), cast(ubyte)(y+HB-1)],
                [cast(ubyte)(x+HB-1), cast(ubyte)(y+HB-1)],
                [cast(ubyte)(x+HB-1), cast(ubyte)(y)],
                [cast(ubyte)(x-HB), cast(ubyte)(y)]];
    }
}


immutable CubeSideData[6] SLAB_VERTICES = [
    { [[-0.5f, -0.5f, 0.5f], [0.5f, -0.5f, 0.5f], [0.5f, 0.0f, 0.5f], [-0.5f, 0.0f, 0.5f]], // near
       [0.0f, 0.0f, 1.0f] },

    { [[-0.5f, -0.5f, -0.5f], [-0.5f, -0.5f, 0.5f], [-0.5f, 0.0f, 0.5f], [-0.5f, 0.0f, -0.5f]], // left
       [-1.0f, 0.0f, 0.0f] },

    { [[0.5f, -0.5f, -0.5f], [-0.5f, -0.5f, -0.5f], [-0.5f, 0.0f, -0.5f], [0.5f, 0.0f, -0.5f]], // far
       [0.0f, 0.0f, -1.0f] },

    { [[0.5f, -0.5f, 0.5f], [0.5f, -0.5f, -0.5f], [0.5f, 0.0f, -0.5f], [0.5f, 0.0f, 0.5f]], // right
       [1.0f, 0.0f, 0.0f] },

    { [[-0.5f, 0.0f, 0.5f], [0.5f, 0.0f, 0.5f], [0.5f, 0.0f, -0.5f], [-0.5f, 0.0f, -0.5f]], // top
       [0.0f, 1.0f, 0.0f]  },

    { [[-0.5f, -0.5f, -0.5f], [0.5f, -0.5f, -0.5f], [0.5f, -0.5f, 0.5f], [-0.5f, -0.5f, 0.5f]], // bottom
       [0.0f, -1.0f, 0.0f] }
];

immutable CubeSideData[6] SLAB_VERTICES_UPSIDEDOWN = upside_down_slabs();

private CubeSideData[6] upside_down_slabs() {
    CubeSideData[6] ret = SLAB_VERTICES.dup;

    foreach(ref side; ret) {
        foreach(ref vertex; side.positions) {
            vertex[1] += 0.5f;
        }
    }

    return ret;
}

Vertex[] simple_slab(Side side, bool upside_down, ubyte[2][4] texture_slice) pure {
    return simple_slab(side, upside_down, texture_slice, nslice);
}

Vertex[] simple_slab(Side side, bool upside_down, ubyte[2][4] texture_slice, ubyte[2][4] mask_slice) pure {
    CubeSideData cbsd;
    if(upside_down) {
        cbsd = SLAB_VERTICES_UPSIDEDOWN[side];
        
        if(side != Side.TOP && side != Side.BOTTOM) {
            texture_slice[0][1] -= 1;
            texture_slice[1][1] -= 1;
            texture_slice[2][1] -= 1;
            texture_slice[3][1] -= 1;
        }
    } else {
        cbsd = SLAB_VERTICES[side];
    }

    mixin(mk_vertices);
    return data.dup;
}
