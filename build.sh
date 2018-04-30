#!/bin/bash

set -x

#CC=/opt/lsb/bin/lsbcc
CC=gcc
PREFIX=`pwd`

if ! test -f libtool-2.4.tar; then
    wget https://mirrors.ocf.berkeley.edu/gnu/libtool/libtool-2.4.tar.xz ;
    unxz libtool-2.4.tar.xz
    tar xf libtool-2.4.tar
fi

if ! test -f gc-7.6.4.tar; then
    wget http://www.hboehm.info/gc/gc_source/gc-7.6.4.tar.gz ;
    gunzip gc-7.6.4.tar.gz
    tar xf gc-7.6.4.tar
fi

if ! test -f libatomic_ops-7.6.2.tar; then
    wget http://www.hboehm.info/gc/gc_source/libatomic_ops-7.6.2.tar.gz ;
    gunzip libatomic_ops-7.6.2.tar
    tar xf libatomic_ops-7.6.2.tar
    if ! test -L gc-7.6.4/libatomic_ops ; then
	ln -s $PREFIX/libatomic_ops-7.6.2 $PREFIX/gc-7.6.4/libatomic_ops
    fi
fi

if ! test -f libunistring-0.9.9.tar; then
    wget https://mirrors.ocf.berkeley.edu/gnu/libunistring/libunistring-0.9.9.tar.xz
    unxz libunistring-0.9.9.tar.xz
    tar xf libunistring-0.9.9.tar
fi

if ! test -f gmp-6.1.2.tar; then
    wget https://gmplib.org/download/gmp/gmp-6.1.2.tar.lz
    lzip -d gmp-6.1.2.tar.lz
    tar xf gmp-6.1.2.tar
fi

if ! test -f libffi-3.2.1.tar; then
    wget ftp://sourceware.org/pub/libffi/libffi-3.2.1.tar.gz
    gunzip libffi-3.2.1.tar.gz
    tar xf libffi-3.2.1.tar
fi

if ! test -f readline-7.0.tar; then
    wget https://mirrors.ocf.berkeley.edu/gnu/readline/readline-7.0.tar.gz
    gunzip readline-7.0.tar.gz
    tar xf readline-7.0.tar
fi

if [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
    if ! test -f guile.tar; then
	wget http://git.savannah.gnu.org/cgit/guile.git/snapshot/guile-6d6bc013e1f9db98334e1212295b8be0e39fbf0a.tar.gz
	gunzip guile-6d6bc013e1f9db98334e1212295b8be0e39fbf0a.tar.gz
	mv guile-6d6bc013e1f9db98334e1212295b8be0e39fbf0a.tar guile.tar
	tar xf guile.tar
    fi
else
    if ! test -f guile.tar; then
	wget https://mirrors.ocf.berkeley.edu/gnu/guile/guile-2.2.3.tar.lz
	lzip -d guile-2.2.3.tar.lz
	mv guile-2.2.3.tar guile.tar
	tar xf guile.tar
    fi
fi

if ! test -f libogg-1.3.3.tar; then
    wget https://ftp.osuosl.org/pub/xiph/releases/ogg/libogg-1.3.3.tar.xz
    unxz libogg-1.3.3.tar.xz
    tar xf libogg-1.3.3.tar
fi

if ! test -f libvorbis-1.3.6.tar; then
    wget https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-1.3.6.tar.xz
    unxz libvorbis-1.3.6.tar.xz
    tar xf libvorbis-1.3.6.tar
fi

if ! test -f burro-master.zip; then
    wget https://github.com/spk121/burro/archive/master.zip
    mv master.zip burro-master.zip
    unzip -o burro-master.zip
fi


if ! test -f _libtool_complete; then
    cd libtool-2.4
    ./configure CC=$CC CFLAGS="-g -O1" --disable-shared --enable-static --prefix=$PREFIX
    make
    make install
    cd $PREFIX
    echo > _libtool_complete
fi

LD_LIBRARY_PATH=$PREFIX/lib
if ! test -f _gc_complete; then
    # patch -i gc_Makefile_direct.patch gc-7.6.4/Makefile.direct
    cd gc-7.6.4
    make -f Makefile.direct
    cp gc.a $PREFIX/lib
    cp -pR include/* $PREFIX/include
    cd $PREFIX
    echo > _gc_complete
fi

if ! test -f _libunistring_complete; then
    cd libunistring-0.9.9
    ./configure CC=$CC CFLAGS="-g -O1" --disable-shared --enable-static --prefix=$PREFIX
    make
    make install
    cd $PREFIX
    echo > _libunistring_complete
fi

if ! test -f _gmp_complete; then
    cd gmp-6.1.2
    ./configure CC=$CC CFLAGS="-g -O1" --disable-shared --enable-static --prefix=$PREFIX --disable-assembly
    make
    make install
    cd $PREFIX
    echo > _gmp_complete
fi

if ! test -f _libffi_complete; then
    cd libffi-3.2.1
    ./configure CC=$CC CFLAGS="-g -O1" --disable-shared --enable-static --prefix=$PREFIX \
		--includedir=$PREFIX/include
    make
    make install
    cd $PREFIX
    cp $PREFIX/lib/libffi-3.2.1/include/ffi.h $PREFIX/include/ffi.h
    cp $PREFIX/lib/libffi-3.2.1/include/ffitarget.h $PREFIX/include/ffitarget.h
    cp $PREFIX/lib64/libffi.a $PREFIX/lib/libffi.a
    echo > _libffi_complete
fi

if ! test -f _readline_complete; then
    cp readline-7.0/colors.c readline-7.0/colors.c.orig
    cp readline-7.0/histfile.c readline-7.0/histfile.c.orig
    patch -Np0 < readline-7.0-mingw.patch
    cd readline-7.0

    ./configure CC=$CC CFLAGS="-g -O1" --disable-shared --enable-static --prefix=$PREFIX
    make
    make install
    cd $PREFIX
    echo > _readline_complete
fi

if ! test -f _guile_complete; then
    if [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
	cd guile-6d6bc013e1f9db98334e1212295b8be0e39fbf0a
	autoreconf -vif
	patch -Np0 < ../guile-mingw.patch
    else
	cd guile-2.2.3
    fi
    ./configure CC=$CC \
		CFLAGS="-I$PREFIX/include -I$PREFIX/include/readline -g -O1 -UHAVE_CLOCK_GETTIME -UFFI_CLOSURES" \
		LDFLAGS= \
		LIBS="$PREFIX/lib/gc.a $PREFIX/lib/libffi.a $PREFIX/lib/libgmp.a $PREFIX/lib/libltdl.a $PREFIX/lib/libunistring.a $PREFIX/lib/libreadline.a" \
		LIBFFI_CFLAGS=-I$PREFIX/include \
		LIBFFI_LIBS=$PREFIX/lib/libffi.a \
		BDW_GC_FLAGS=-I$PREFIX/include \
		BDW_GC_LIBS=$PREFIX/lib/gc.a \
		--disable-shared --enable-static --without-threads \
		--prefix=$PREFIX
    cat config.h | grep -v HAVE_CLOCK_ > config.h.tmp
    cp config.h.tmp config.h
    patch -Np0 < readline-7.0-mingw.patch
    make install
    cd $PREFIX
    echo > _guile_complete
fi

if ! test -f _libogg_complete; then
    cd libogg-1.3.3
    ./configure CC=$CC CFLAGS="-g -O1" \
		--disable-shared --enable-static --prefix=$PREFIX
    make
    make install
    cd $PREFIX
    echo > _libogg_complete
fi

if ! test -f _libvorbis_complete; then
    cd libvorbis-1.3.6
    ./configure CC=$CC CFLAGS="-g -O1" \
		OGG_CFLAGS=-I$PREFIX/include \
		OGG_LIBS=$PREFIX/lib/libogg.a \
		--disable-shared --enable-static --prefix=$PREFIX
    make
    make install
    cd $PREFIX
    echo > _libvorbis_complete
fi

# Merge Ogg and Vorbis
cd lib
ar -M < ../vorbis.mri
cd $PREFIX

if ! test -f _burro_complete; then
    cd burro-master
    autoreconf -vif
    if [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
	./configure CC=$CC CFLAGS="-g -O1" \
		    CPPFLAGS="-DRELATIVE_PATHS" \
		    LIBS="$PREFIX/lib/libguile-2.2.a $PREFIX/lib/gc.a $PREFIX/lib/libffi.a $PREFIX/lib/libgmp.a $PREFIX/lib/libltdl.a $PREFIX/lib/libunistring.a $PREFIX/lib/libreadline.a $PREFIX/lib/liboggvorbis.a -liconv -lws2_32 -lintl"	\
		    GUILE_CFLAGS=-I$PREFIX/include/guile/2.2 \
		    GUILE_LIBS=$PREFIX/lib/libguile-2.2.a \
		    --disable-shared --enable-static \
		    --prefix=$PREFIX \
		    --with-guilesitedir=$PREFIX/share/guile/site/2.2
    else
	./configure CC=$CC CFLAGS="-g -O1" \
		    CPPFLAGS="-DRELATIVE_PATHS" \
		    LIBS="$PREFIX/lib/libguile-2.2.a $PREFIX/lib/gc.a $PREFIX/lib/libffi.a $PREFIX/lib/libgmp.a $PREFIX/lib/libltdl.a $PREFIX/lib/libunistring.a $PREFIX/lib/libreadline.a $PREFIX/lib/liboggvorbis.a -ldl -lcrypt"	\
		    GUILE_CFLAGS=-I$PREFIX/include/guile/2.2 \
		    GUILE_LIBS=$PREFIX/lib/libguile-2.2.a \
		    --disable-shared --enable-static \
		    --prefix=$PREFIX \
		    --with-guilesitedir=$PREFIX/share/guile/site/2.2

    fi
    make
    make install
    cd $PREFIX
    echo > _burro_complete
fi

# Finally, prepare the final package
if [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
    mkdir fancy-free
    cp bin/burro-engine.exe fancy-free/fancy-free.exe
    cp c:/msys64/mingw32/bin/libwinpthread-1.dll fancy-free
    cp c:/msys64/mingw32/bin/libcairo-2.dll fancy-free
    cp c:/msys64/mingw32/bin/libgdk-3-0.dll fancy-free
    cp c:/msys64/mingw32/bin/libgtk-3-0.dll fancy-free
    cp c:/msys64/mingw32/bin/libgio-2.0-0.dll fancy-free
    cp c:/msys64/mingw32/bin/libgdk_pixbuf-2.0-0.dll fancy-free
    cp c:/msys64/mingw32/bin/libglib-2.0-0.dll fancy-free
    cp c:/msys64/mingw32/bin/libgobject-2.0-0.dll fancy-free
    cp c:/msys64/mingw32/bin/libiconv-2.dll fancy-free
    cp c:/msys64/mingw32/bin/libintl-8.dll fancy-free
    cp c:/msys64/mingw32/bin/libpango-1.0-0.dll fancy-free
    cp c:/msys64/mingw32/bin/libpangocairo-1.0-0.dll fancy-free
    cp c:/msys64/mingw32/bin/libvorbisfile-3.dll fancy-free
    cp c:/msys64/mingw32/bin/libgcc_s_dw2-1.dll fancy-free
    cp c:/msys64/mingw32/bin/libfreetype-6.dll fancy-free
    cp c:/msys64/mingw32/bin/libfontconfig-1.dll fancy-free
    cp c:/msys64/mingw32/bin/libpixman-1-0.dll fancy-free
    cp c:/msys64/mingw32/bin/libpng16-16.dll fancy-free
    cp c:/msys64/mingw32/bin/libgmodule-2.0-0.dll fancy-free
    cp c:/msys64/mingw32/bin/zlib1.dll fancy-free
    cp c:/msys64/mingw32/bin/libffi-6.dll fancy-free
    cp c:/msys64/mingw32/bin/libpcre-1.dll fancy-free
    cp c:/msys64/mingw32/bin/libcairo-gobject-2.dll fancy-free
    cp c:/msys64/mingw32/bin/libepoxy-0.dll fancy-free
    cp c:/msys64/mingw32/bin/libfribidi-0.dll fancy-free
    cp c:/msys64/mingw32/bin/libpangoft2-1.0-0.dll fancy-free
    cp c:/msys64/mingw32/bin/libpangowin32-1.0-0.dll fancy-free
    cp c:/msys64/mingw32/bin/libvorbis-0.dll fancy-free
    cp c:/msys64/mingw32/bin/libogg-0.dll fancy-free
    cp c:/msys64/mingw32/bin/libbz2-1.dll fancy-free
    cp c:/msys64/mingw32/bin/libexpat-1.dll fancy-free
    cp c:/msys64/mingw32/bin/libharfbuzz-0.dll fancy-free
    cp c:/msys64/mingw32/bin/libgraphite2.dll fancy-free
    cp c:/msys64/mingw32/bin/libatk-1.0-0.dll fancy-free
    cp c:/msys64/mingw32/bin/libstdc++-6.dll fancy-free
    cp -pR bin fancy-free/bin
    cp -pR share fancy-free/share
    rm -r fancy-free/share/aclocal
    rm -r fancy-free/share/doc
    rm -r fancy-free/share/info
    rm -r fancy-free/share/man
    rm -r fancy-free/share/readline
    cp -pR lib fancy-free/lib
    mkdir fancy-free/share
    mkdir fancy-free/share/icons
    mkdir fancy-free/share/icons/Adwaita
    #mkdir fancy-free/share/icons/Adwaita/16x16
    #mkdir fancy-free/share/icons/Adwaita/22x22
    mkdir fancy-free/share/icons/Adwaita/48x48
    mkdir fancy-free/share/icons/hicolor
    cp -pR c:/msys64/mingw32/share/icons/hicolor fancy-free/share/icons
    cp -p  c:/msys64/mingw32/share/icons/Adwaita/index.theme fancy-free/share/icons/Adwaita
    #cp -pR c:/msys64/mingw32/share/icons/Adwaita/16x16 fancy-free/share/icons/Adwaita
    #cp -pR c:/msys64/mingw32/share/icons/Adwaita/22x22 fancy-free/share/icons/Adwaita
    #cp -pR c:/msys64/mingw32/share/icons/Adwaita/24x24 fancy-free/share/icons/Adwaita
    cp -pR c:/msys64/mingw32/share/icons/Adwaita/48x48 fancy-free/share/icons/Adwaita

    cd fancy-free
    gtk-update-icon-cache-3.0 share/icons/hicolor
    gtk-update-icon-cache-3.0 share/icons/Adwaita
    cd ..

    cp -pR C:/msys64/mingw32/lib/gdk-pixbuf-2.0 fancy-free/lib

    cd fancy-free
    GDK_PIXBUF_MODULEDIR=lib/gdk-pixbuf-2.0/2.10.0/loaders gdk-pixbuf-query-loaders > lib/gdk-pixbuf-2.0/2.10.0/loaders.cache
    cd ..

    mkdir fancy-free/share/glib-2.0
    cp -pR c:/msys64/mingw32/share/glib-2.0/schemas fancy-free/share/glib-2.0
else

    mkdir fancy-free
    cp bin/burro-engine fancy-free/fancy-free
    cp -pR bin fancy-free/bin
    cp -pR share fancy-free/share
    rm -r fancy-free/share/aclocal
    rm -r fancy-free/share/doc
    rm -r fancy-free/share/info
    rm -r fancy-free/share/man
    rm -r fancy-free/share/readline
    cp -pR lib fancy-free/lib
    mkdir fancy-free/share
    mkdir fancy-free/share/icons
    mkdir fancy-free/share/icons/hicolor
    cp -pR c:/msys64/mingw32/share/icons/hicolor fancy-free/share/icons

    cd fancy-free
    gtk-update-icon-cache share/icons/hicolor
    cd ..
fi
