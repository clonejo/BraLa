BraLa
=====

[![Flattr this](http://api.flattr.com/button/flattr-badge-large.png)](http://flattr.com/thing/854394/Dav1ddeBraLa-on-GitHub)

BraLa is an opensource minecraft (S)MP Client:

![Brala Screenshot](https://raw.github.com/wiki/Dav1dde/BraLa/screenshots/brala_03.png)

This screenshot was taken with an awesome 128x128 texture pack, called [R3D-Craft](http://www.minecraftforum.net/topic/1182714-13112),
made by [UniblueMedia](http://www.youtube.com/user/UniblueMedia).

Currently BraLa tries to load the texture pack from your currently installed minecraft, however you can use the
`--texture-pack=path/to/tetxture/pack.zip` commandline switch to specify your custom texturepack.


## Features ##

BraLa is at this state just a minecraft (S)MP viewer, it is able to connect to 1.6.2 servers
and display the world.
BraLa also doesn't have any kind of physics (to use BraLa you must set the client into
creative mod or allow to fly).

What BraLa *can* do:
* Connect to 1.6.2 servers
* Supports the whole 1.6.2 protocol
* Authenticate with the official login servers
* Read the lastlogin file / launcher_profiles.json
* Send "snoop" requests
* Display biome colors, based on rainfall/temperature
* Display nearly all blocks

Not a whole lot, but a start.


## Getting Started/Linux ##

### Dependencies ###

BraLa brings most of the dependencies as gitsubmodules, but there are still a few things you need:
* A D compiler (any of the major 3 should work, DMD, GDC or LDC)
* A C compiler (dmc on windows and any C compiler on Linux/Mac, gcc recommended)
* OpenGL 3.0+ support
* [OpenSSL](http://www.openssl.org/)
* [CMake](http://www.cmake.org/) on Linux/Mac

#### Ubuntu/Debian based systems ####

To install the latest dmd compiler, best choice is the [d-apt](http://d-apt.sourceforge.net/)
repository:

```
sudo wget http://master.dl.sourceforge.net/project/d-apt/files/d-apt.list -O /etc/apt/sources.list.d/d-apt.list
sudo apt-get update && sudo apt-get -y --allow-unauthenticated install --reinstall d-apt-keyring && sudo apt-get update
sudo apt-get install dmd
```

And to install the rest of the dependencies:

```
sudo apt-get install git pkg-config cmake libssl-dev libxss-dev
```

Furthermore you need the `libxrandr` headers:

```
sudo apt-get install libxrandr-dev
```

Now you're ready to proceed with Cloning!

### Cloning ###

Since BraLa makes use of git submodules, you need the `--recursive` flag, when cloning:

```
git clone --recursive git://github.com/Dav1dde/BraLa.git
cd BraLa
```

Or you setup the submodules on your own:

```
git clone git://github.com/Dav1dde/BraLa.git
cd BraLa
git submodule init
git submodule update
```

### D compiler ###

Since BraLa is written mostly in D, you need a D2 compiler. BraLa compiles with all major D compilers,
[DMD](http://dlang.org/download.html), [LDC](https://github.com/ldc-developers/ldc) and 
[GDC](https://github.com/D-Programming-GDC/GDC). To use LDC or GDC you have probably install these
compilers from `git`, so the fronted version matches DMDs frontend version.

#### DMD ####

Building BraLa with DMD is easy:

```
make
./bin/bralad -c -h"localhost" # starts brala
```

#### LDC ####

Building with LDC is nearly the same:

```
make DC=ldc2
```

#### GDC ####

To build with GDC you have to specify `gdc` as D compiler:

```
make DC=gdc
```

## Getting Started/Windows ##

These steps assume, that you have [git](http://windows.github.com/) already installed.

Download [DMD2](http://dlang.org/download.html) (if you don't have dmd installed)
with the D-Installer, make sure you checked the dmc option when installing.

To clone and compile BraLa open your terminal and run the following commands:

```
git clone --recursive git://github.com/Dav1dde/BraLa.git
cd BraLa
rdmd build_brala.d
```
The current working directory is important (you have to be in the repos root directory)!

To run BraLa:
```
bin\bralad.exe -c -h"localhost"
```

## Running ##

BraLa supports a few commandline options:

```
    --brala-conf            the path to brala.conf, relativ to "res" or absolute
    --username  -u          specifies the username, which will be used to auth with the login servers,
                            if this is not possible and the server is in offline mode, it will be used
                            as playername
    --password  -p          the password which is used to authenticate with the login servers, set this
                            to a random value if you don't want to authenticate with the servers
    --credentials   -c      uses minecrafts lastlogin file for authentication and logging in,
                            --username and --password are used as fallback
    --session               uses the supplied session to login to minecraft, this requires --username
    --auto-session  -a      tries to use launcher_profiles.json to extract session key
    --offline               start in offline mode
    --width                 specifies the width of the window
    --height                specifies the height of the window
    --not-resizable         window should not be resizable
    --renderer              Specify default renderer for BraLa, either deferred or forward
    --host  -h              the IP/adress of the minecraft server
    --port                  the port of the minecraft server, defaults to 25565
    --res                   path to the resources folder, named "res"
    --no-snoop              disables "snooping" (= sending completly anonym information to mojang)
    --texture-pack          Path to texture pack, if none specified defaults to config or tries to find minecraft.jar
    --help
```

## Support ##

Found a bug? Submit it to the [issue-tracker](https://github.com/Dav1dde/BraLa/issues?state=open).

You need support on getting BraLa to run on your computer or just want to talk me?
Drop me an [E-Mail](https://github.com/Dav1dde) or contact me over IRC, I am a lot on [#mcdevs](http://mcdevs.org/).

Or do you want me help out with the development? Simply fork BraLa and submit a Pull-Request. If you don't know [D](http://dlang.org),
but you still want to improve BraLa, feel free to improve the [Wiki](https://github.com/Dav1dde/BraLa/wiki/_pages).


## License ##

See [COPYING](https://github.com/Dav1dde/BraLa/blob/master/COPYING) for the GNU GENERAL PUBLIC LICENSE v3
