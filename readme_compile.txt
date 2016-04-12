You can compile the source simply by opening *.lpr in Lazarus IDE and pushing F9 to complie&run.

This version requires latest GIT Castle Game Engine version to compile (as of 12 April 2016). Download and installation instructions may be found here http://castle-engine.sourceforge.net/engine.php
I'm afraid latest 5.2.0 release of Castle Game Engine has TCastleWindow.DoRender marked as private and therefore compillation will fail. Therefore either use latest GIT version of the engine or move DoRender to public section and recompile the engine units.


Linux version requires 32bit GTK+2 (Thanks Akien for the information).
(Debian/Ubuntu package reference):
libopenal1
libopenal-dev
libpng
libpng-dev
zlib1g
zlib1g-dev
libvorbis
libvorbis-dev
libfreetype6
libfreetype6-dev
libgtkglext1
libgtkglext1-dev
You will also need dev version of OpenGL drivers for your videocard. In general case it is libgl1-mesa-dev.

Or Castle Game Engine DLLs (32 bit / 64 bit) in case of Windows. These may be downloaded here: http://castle-engine.sourceforge.net/engine.php
The DLLs must be placed in the exe folder.

However, if you prefer command-line compilation, you may try lazbuild. See instructions at http://wiki.lazarus.freepascal.org/lazbuild (Thanks to Akien for the information)