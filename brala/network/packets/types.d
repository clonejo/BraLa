module brala.network.packets.types;

private {
    import std.stream : Stream;
    import std.typetuple : TypeTuple, staticIndexOf, staticMap;
    import std.typecons : Tuple;
    import std.algorithm : canFind;
    import std.string : format;
    import std.array : join, appender, replace;
    import std.conv : to;
    import std.zlib : uncompress;
    import std.exception : enforceEx;
    import std.traits : isNumeric;
    import core.stdc.errno;
    import core.bitop : popcnt;

    import gl3n.linalg : vec3i;
    import nbt : NBTFile;
    
    import brala.dine.chunk : Chunk, Block;
    import brala.network.packets.util : staticJoin, coords_from_j;
    import brala.network.util : read, write;
    import brala.utils.memory : calloc, free;
    import brala.exception : ServerError;
}


abstract class IPacket {
    abstract ubyte get_id();
    void send(Stream s);
    static typeof(this) recv(Stream s);
}


alias Tuple!(short, "id", byte, "count", short, "damage") Tup5;
alias Tuple!(int, int, int) Tup6;

struct Metadata {
    private template Pair(T, int n) {
        alias T type;
        alias n name;
    }

    private template extract_type(alias T) { alias T.type extract_type; }
    private template extract_name(alias T) { alias T.name extract_name; }
    private template make_decl(alias T) { enum make_decl = T.type.stringof ~ " _" ~ to!string(T.name) ~ ";"; }

    alias TypeTuple!(Pair!(byte, 0), Pair!(short, 1), Pair!(int, 2), Pair!(float, 3),
                     Pair!(string, 4), Pair!(SlotType, 5), Pair!(Tup6, 6)) members;

    private static string make_union() {
        alias staticJoin!("\n", staticMap!(make_decl, members)) s;
        return "union {" ~ s ~ "}";
    }

    byte type;

    mixin(make_union());

    auto get(T)() {
        alias staticIndexOf!(T, staticMap!(extract_type, members)) type_index;
        static if(type_index < 0) {
            static assert(false);
        } else {
            return mixin("_" ~ to!string(members[type_index].name));
        }
    }
    
    string toString() {
        assert(type >= 0 && type <= 6);

        string s;
        final switch(type) {
            foreach(m; members) {
                case m.name: s = to!string(mixin("_" ~ to!string(m.name)));
            }
        }

        return s;
    }
}

struct EntityMetadataType {
    Metadata[byte] metadata;
    
    static EntityMetadataType recv(Stream s) {
        EntityMetadataType ret;
        
        ubyte x = read!ubyte(s);

        while(x != 127) {
            Metadata m;

            byte index = x & 0x1f;
            m.type = x >> 5;

            switch(m.type) {
                case 0: m._0 = read!byte(s); break;
                case 1: m._1 = read!short(s); break;
                case 2: m._2 = read!int(s); break;
                case 3: m._3 = read!float(s); break;
                case 4: m._4 = read!string(s); break;
                case 5: m._5 = read!(SlotType)(s); break;
                case 6: m._6 = read!(int, int, int)(s); break;
                default: throw new ServerError(`Invalid type in entity metadata "%s".`.format(m.type));
            }

            ret.metadata[index] = m;

            x = read!ubyte(s);
        }
        
        return ret;
    }
    
    string toString() {
        string[] s;
        foreach(byte key, Metadata value; metadata) {
            s ~= format("%d : %s", key, value.toString());
        }

        return format("EntityMetadataType(%s)", s.join(", "));
    }
}

struct SlotType {
    short item;
    byte item_count = 0;
    short metadata = 0;
    NBTFile nbt;

    private size_t _slot;
    private bool has_array_position;
    @property void array_position(size_t n) {
        if(!has_array_position) {
            _slot = n;
            has_array_position = true;
        }
    }
    @property size_t slot() { return _slot; }


    static SlotType recv(Stream s) {
        SlotType ret;

        ret.item = read!short(s);

        if(ret.item != -1) {
            ret.item_count = read!byte(s);
            ret.metadata = read!short(s);

            int len = read!short(s);

            if(len != -1) {
                debug assert(len >= 0);
                ubyte[] compressed_data = new ubyte[len];
                s.readExact(compressed_data.ptr, len);
                ret.nbt = new NBTFile(compressed_data, NBTFile.Compression.AUTO);
            }
        }

        if(ret.nbt is null) {
            ret.nbt = new NBTFile(); // having ret.nbt null makes things only harder
        }

        return ret;
    }

    string toString() {
        string s = "SlotType" ~ (has_array_position ? "_" ~ to!string(_slot) : "");

        string pnbt = "null";
        if(nbt !is null) {
            pnbt = nbt.toString().replace("}\n", "}").replace("{\n", "{").replace("\n", ";").replace("  ", "");
        }

        return format(`%s(short block : "%s", byte item_count : "%s", short metadata : "%s", NBTFile nbt : "%s"`,
                       s, item, item_count, metadata, pnbt);
    }
}

struct ObjectDataType {
    int data;
    short speed_x;
    short speed_y;
    short speed_z;

    static ObjectDataType recv(Stream s) {
        ObjectDataType ret;

        ret.data = read!int(s);

        if(ret.data) {
            ret.speed_x = read!short(s);
            ret.speed_y = read!short(s);
            ret.speed_z = read!short(s);
        }

        return ret;
    }

    void send(Stream s) {
        write(s, data);

        if(data) {
            write(s, speed_x, speed_y, speed_z);
        }
    }
}

struct TeamType {
    enum Mode : byte {
        CREATE,
        REMOVE,
        UPDATE,
        ADD_PLAYER,
        REMOVE_PLAYER
    }

    Mode mode;
    string display_name;
    string prefix;
    string suffix;
    bool friendly_fire;
    string[] players;

    static TeamType recv(Stream s) {
        TeamType teams;

        teams.mode = cast(Mode)read!byte(s);

        if(teams.mode == Mode.CREATE || teams.mode == Mode.UPDATE) {
            teams.display_name = read!string(s);
            teams.prefix = read!string(s);
            teams.suffix = read!string(s);
            teams.friendly_fire = read!bool(s);
        }

        if(teams.mode == Mode.CREATE ||
           teams.mode == Mode.ADD_PLAYER || teams.mode == Mode.REMOVE_PLAYER) {
            teams.players = read!(string[])(s);
        }

        return teams;
    }

    void send(Stream s) {
        write(s, cast(byte)mode);

        if(mode == Mode.CREATE || mode == Mode.UPDATE) {
            write(s, display_name, prefix, suffix, friendly_fire);
        }

        if(mode == Mode.CREATE || mode == Mode.ADD_PLAYER || mode == Mode.REMOVE_PLAYER) {
            write(s, players);
        }
    }
}
        

struct Array(T, S) {
    alias T LenType;
    S[] arr;
    alias arr this;

    string toString() {
        return "%s(%s, %s)".format(typeof(this).stringof, cast(LenType)arr.length, arr);
    }
}

struct StaticArray(T, size_t length) {
    T[length] arr;
    alias arr this;
}

struct AAList {
    long msb;
    long lsb;
    double double_;
    byte byte_;

    static AAList recv(Stream s) {
        AAList ret;
        ret.msb = read!long(s);
        ret.lsb = read!long(s);
        ret.double_ = read!double(s);
        ret.byte_ = read!byte(s);
        return ret;
    }

    string toString() {
        return `%s(long msb : %s, long lsb : %s, double double_ : %s, byte byte_ : %s)`.format(msb, lsb, double_, byte_);
    }
}

struct AA(V, K, T = int) {
    alias T CountType;

    struct Value {
        V value;
        alias value this;
        Array!(short, AAList) list;

        static Value recv(Stream s) {
            Value ret;
            ret.value = read!V(s);
            ret.list = read!(Array!(short, AAList))(s);
            return ret;
        }

        string toString() {
            static if(isNumeric!V) {
                return `(%s, %s)`.format(value, list);
            } else {
                return `("%s", %s)`.format(value, list);
            }
        }
    }

    Value[K] aa;
    alias aa this;

    string toString() {
        string[] kv;
        foreach(K key, Value value; aa) {
            static if(isNumeric!V) {
                kv ~= `"%s" : %s`.format(key, value);
            } else {
                kv ~= `"%s" : "%s"`.format(key, value);
            }
        }
        return "[%s]".format(kv.join(", "));
    }
}


// Chunk stuff
struct MapChunkType { // TODO: implement send
    int x;
    int z;
    bool contiguous;
    ushort primary_bitmask;
    ushort add_bitmask;
    Chunk chunk;
    alias chunk this;
    
    static MapChunkType recv(Stream s) {
        MapChunkType ret;
        ret.chunk = new Chunk();

        ret.x = read!int(s);
        ret.z = read!int(s);
        ret.contiguous = read!bool(s);

        ret.chunk.primary_bitmask = read!ushort(s);
        ret.chunk.add_bitmask = read!ushort(s);

        int len = read!int(s);
        ubyte[] compressed_data = (cast(ubyte*)calloc(len, ubyte.sizeof))[0..len];
        scope(exit) compressed_data.ptr.free();
        s.readExact(compressed_data.ptr, len);
        ubyte[] unc_data = cast(ubyte[])uncompress(compressed_data, len*5);

        ret.chunk.fill_chunk_with_nothing();

        int pc = popcnt(ret.chunk.primary_bitmask);
        // 4096 offset for each 16x16x16 blocks
        // 2048 offset for metadata and block_light
        // 256 is biome_data
        bool has_skylight = pc*4096+pc*2048*2 > 256;

        // if ret.contiguous, there is biome data
        parse_raw_chunk(ret.chunk, unc_data, ret.contiguous, has_skylight);

        return ret;
    }

    static size_t parse_raw_chunk(Chunk chunk, const ubyte[] unc_data, bool biome_data, bool has_skylight) {
        size_t offset = 0;
        foreach(i; 0..16) {
            if(chunk.primary_bitmask & (1 << i)) {
                const(ubyte)[] temp = unc_data[offset..offset+4096];

                foreach(j, block_id; temp) {
                    vec3i coords = coords_from_j(cast(uint)j, i);

                    chunk.blocks[chunk.to_flat(coords)].id = block_id;
                }

                offset += 4096;
            }
        }

        foreach(f; TypeTuple!("metadata", "block_light", "sky_light")) {
            static if(f == "sky_light") {
                if(!has_skylight) {
                    // GOTO!!!
                    goto LBiome;
                }
            }

            foreach(i; 0..16) {
                if(chunk.primary_bitmask & 1 << i) {
                    const(ubyte)[] temp = unc_data[offset..offset+2048];

                    uint j = 0;
                    foreach(dj; temp) {
                        vec3i coords_m1 = coords_from_j(j++, i);
                        vec3i coords_m2 = coords_from_j(j++, i);

                        mixin("chunk.blocks[chunk.to_flat(coords_m1)]." ~ f ~ " = dj & 0x0F;");
                        mixin("chunk.blocks[chunk.to_flat(coords_m2)]." ~ f ~ " = dj >> 4;");
                    }

                    offset += 2048;
                }
            }
        }

        LBiome:
        if(biome_data) {
            chunk.biome_data = unc_data[offset..(offset+256)];
            offset += 256;
        }

        return offset;
    }

    string toString() {
        return format(`ChunkType(int x : "%d", int z : "%d", bool contiguous : "%s", ushort primary_bitmask : "%016b", `
                                `ushort add_bitmask : "%016b", Chunk chunk : "%s")`,
                                 x, z, contiguous, primary_bitmask, add_bitmask, chunk);
    } 
}

struct MapChunkBulkType {
    alias Tuple!(vec3i, "coords", Chunk, "chunk") CoordChunkTuple;
    
    short chunk_count;
    CoordChunkTuple[] chunks;

    struct MetaInformation {
        int x;
        int z;
        short primary_bitmask;
        short add_bitmask;

        this(int x, int z, short primary_bitmask, short add_bitmask) {
            this.x = x;
            this.z = z;
            this.primary_bitmask = primary_bitmask;
            this.add_bitmask = add_bitmask;
        }

        static MetaInformation recv(Stream s) {
            return MetaInformation(read!(int, int, short, short)(s).field);
        }

        void send(Stream s) {
            write!(int, int, short, short)(s, x, z, primary_bitmask, add_bitmask);
        }
    }

    static MapChunkBulkType recv(Stream s) {
        MapChunkBulkType ret;

        ret.chunk_count = read!short(s);

        uint len = read!uint(s);
        bool has_skylight = read!bool(s);
        ubyte[] compressed_data = new ubyte[len];
        s.readExact(compressed_data.ptr, len);
        ubyte[] unc_data = cast(ubyte[])uncompress(compressed_data);

        auto app = appender!(CoordChunkTuple[])();
        app.reserve(ret.chunk_count);
        foreach(i; 0..ret.chunk_count) {
            auto m = MetaInformation.recv(s);

            vec3i coords = vec3i(m.x, 0, m.z);
            Chunk chunk = new Chunk();
            chunk.primary_bitmask = m.primary_bitmask;
            chunk.add_bitmask = m.add_bitmask;

            app.put(CoordChunkTuple(coords, chunk));
        }
        ret.chunks = app.data;

        size_t offset = 0;
        foreach(cc; ret.chunks) {
            cc.chunk.fill_chunk_with_nothing();

            offset += MapChunkType.parse_raw_chunk(cc.chunk, unc_data[offset..$], true, has_skylight);
        }

        return ret;
    }

    string toString() {
        auto app = appender!string();
        foreach(i, cc; chunks) {
            app.put("\n\t");
            app.put(`%d: CoordChunkTuple : [vec3i coords : %s, Chunk chunk : "%s"]`.format(i+1, cc.coords, cc.chunk));
        }
        app.put("\n");

        return `MapChunkBulkType(short chunk_count : "%s", CoordChunkTuple[] chunks : [%s]`.format(chunk_count, app.data);
    }
}

struct MultiBlockChangeDataType {
    uint[] data;
    alias data this;

    static MultiBlockChangeDataType recv(Stream s) {
        MultiBlockChangeDataType ret;

        int length = read!int(s);

        auto app = appender!(uint[])();
        app.reserve(length/4);

        foreach(_; 0..length/4) {
            app.put(read!uint(s));
        }

        ret.data = app.data;

        return ret;
    }

    void load_into_chunk(Chunk chunk) {
        foreach(block_data; data) {
            Block block;

            block.metadata = block_data & 0x0000000f;
            block.id = (block_data & 0x0000fff0) >> 4;

            int y = (block_data & 0x00ff0000) >> 16;
            int z = (block_data & 0x0f000000) >> 24;
            int x = (block_data & 0xf0000000) >> 28;

            chunk.blocks[chunk.to_flat(x, y, z)] = block;
        }
    }
}