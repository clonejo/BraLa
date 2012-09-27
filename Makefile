export PROJECT_NAME     = BraLa
export AUTHOR           = David Herberth
export DESCRIPTION      = A Minecraft SMP Client written in D
export VERSION          =
export LICENSE          = GPLv3

DCFLAGS_IMPORT      = -Ibrala/ -Isrc/d/derelict3/import -Isrc/d/glamour -Isrc/d/gl3n/ -Isrc/d/ -Isrc/d/openssl/ -Isrc/d/glfw/
DCFLAGS_LINK        = $(LDCFLAGS) $(LINKERFLAG)-lssl $(LINKERFLAG)-lcrypto \
		      $(LINKERFLAG)-Lbuild/glfw/src \
		      `env PKG_CONFIG_PATH=./build/glfw/src pkg-config --static --libs glfw3 | sed -e "s/-L/-L-L/g;s/-l/-L-l/g"`

ifeq ($(DC),ldc2)
	ADDITIONAL_FLAGS = -d-version=Derelict3 -d-version=gl3n -d-version=stb -d-debug -unittest -g -gc
else ifeq ($(DC),gdc)
	ADDITIONAL_FLAGS = -fversion=Derelict3 -fversion=gl3n -fversion=stb -fdebug -g -fdebug-c
else
	ADDITIONAL_FLAGS = -version=Derelict3 -version=gl3n -version=stb -debug -g -gc
endif


include command.make

DERELICT_DIR = src$(PATH_SEP)d$(PATH_SEP)derelict3$(PATH_SEP)import$(PATH_SEP)derelict

OBJDIRS		     = $(DBUILD_PATH)$(PATH_SEP)brala \
			$(DBUILD_PATH)$(PATH_SEP)src$(PATH_SEP)d$(PATH_SEP){arsd,derelict3,gl3n,glamour,openssl,std} \
			$(CBUILD_PATH)$(PATH_SEP)src$(PATH_SEP)c$(PATH_SEP)nbt

DSOURCES             = $(call getSource,brala,d)
DOBJECTS             = $(patsubst %.d,$(DBUILD_PATH)$(PATH_SEP)%.o,   $(DSOURCES))

DSOURCES_GL3N	     = $(call getSource,src$(PATH_SEP)d$(PATH_SEP)gl3n$(PATH_SEP)gl3n,d)
DOBJECTS_GL3N	     = $(patsubst %.d,$(DBUILD_PATH_GL3N)$(PATH_SEP)%.o,   $(DSOURCES_GL3N))

DSOURCES_DERELICT    =  \
		       $(call getSource,$(DERELICT_DIR)$(PATH_SEP)opengl3,d) \
		       $(call getSource,$(DERELICT_DIR)$(PATH_SEP)util,d)
DOBJECTS_DERELICT    = $(patsubst %.d,$(DBUILD_PATH_GLAMOUR)$(PATH_SEP)%.o,   $(DSOURCES_DERELICT))

DSOURCES_GLAMOUR     = $(call getSource,src$(PATH_SEP)d$(PATH_SEP)glamour$(PATH_SEP)glamour,d)
DOBJECTS_GLAMOUR     = $(patsubst %.d,$(DBUILD_PATH_GLAMOUR)$(PATH_SEP)%.o,   $(DSOURCES_GLAMOUR))

DSOURCES_OTHER	     = $(call getSource,src$(PATH_SEP)d$(PATH_SEP)arsd,d) $(call getSource,src$(PATH_SEP)d$(PATH_SEP)std,d)
DOBJECTS_OTHER       = $(patsubst %.d,$(DBUILD_PATH_OTHER)$(PATH_SEP)%.o,   $(DSOURCES_OTHER))

CSOURCES             = $(call getSource,src$(PATH_SEP)c$(PATH_SEP)nbt,c) src$(PATH_SEP)c$(PATH_SEP)stb_image.c
COBJECTS             = $(patsubst %.c,$(CBUILD_PATH)$(PATH_SEP)%.o,   $(CSOURCES))


all: glfw brala
#all: brala

.PHONY: clean

brala: buildDir $(COBJECTS) $(DOBJECTS) $(DOBJECTS_GL3N) $(DOBJECTS_DERELICT) $(DOBJECTS_GLAMOUR) $(DOBJECTS_OTHER)
	$(DC) $(COBJECTS) $(DOBJECTS) $(DOBJECTS_GL3N) $(DOBJECTS_GLAMOUR) $(DOBJECTS_DERELICT) $(DOBJECTS_OTHER) $(DCFLAGS) $(DCFLAGS_LINK) $(OUTPUT)bralad

glfw:
	$(MKDIR) $(CBUILD_PATH)$(PATH_SEP)glfw
	cd $(CBUILD_PATH)$(PATH_SEP)glfw && \
	cmake -DBUILD_SHARED_LIBS=OFF -DGLFW_BUILD_EXAMPLES=OFF -DGLFW_BUILD_TESTS=OFF ..$(PATH_SEP)..$(PATH_SEP)src$(PATH_SEP)c$(PATH_SEP)glfw
	cd $(CBUILD_PATH)$(PATH_SEP)glfw && $(MAKE) $(MFLAGS)
	
# create object files
$(DBUILD_PATH)$(PATH_SEP)%.o : %.d
	$(DC) $(DCFLAGS) $(DCFLAGS_IMPORT) $(ADDITIONAL_FLAGS) -c $< $(OUTPUT)$@

$(DBUILD_PATH_GL3N)$(PATH_SEP)%.o : %.d
	$(DC) $(DCFLAGS) $(DCFLAGS_IMPORT) $(ADDITIONAL_FLAGS) -c $< $(OUTPUT)$@

$(DBUILD_PATH_DERELICT)$(PATH_SEP)%.o: %.d
	$(DC) $(DCFLAGS) $(DCFLAGS_IMPORT) $(ADDITIONAL_FLAGS) -c $< $(OUTPUT)$@

$(DBUILD_PATH_GLAMOUR)$(PATH_SEP)%.o : %.d
	$(DC) $(DCFLAGS) $(DCFLAGS_IMPORT) $(ADDITIONAL_FLAGS) -c $< $(OUTPUT)$@

$(DBUILD_PATH_OTHER)$(PATH_SEP)%.o : %.d
	$(DC) $(DCFLAGS) $(DCFLAGS_IMPORT) $(ADDITIONAL_FLAGS) -c $< $(OUTPUT)$@

$(CBUILD_PATH)$(PATH_SEP)%.o : %.c
	$(CC) -c -std=c99 -lz $< -o $@

buildDir: $(OBJDIRS)

$(OBJDIRS) :
	$(MKDIR) $@

clean:
	$(RM) build$(PATH_SEP)brala
	
clean-all:
	$(RM) build