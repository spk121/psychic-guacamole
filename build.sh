#!/bin/bash

set -x

#CC=/opt/lsb/bin/lsbcc
CC=gcc
PREFIX=`pwd`

if ! test -f libtool-2.4.tar; then
    wget https://mirrors.ocf.berkeley.edu/gnu/libtool/libtool-2.4.tar.xz ;
    unxz libtool-2.4.tar.xz
fi

if ! test -f gc-7.6.4.tar; then
    wget http://www.hboehm.info/gc/gc_source/gc-7.6.4.tar.gz ;
    gunzip gc-7.6.4.tar.gz
fi
if ! test -f libatomic_ops-7.6.2.tar; then
    wget http://www.hboehm.info/gc/gc_source/libatomic_ops-7.6.2.tar.gz ;
    gunzip libatomic_ops-7.6.2.tar
fi
if ! test -f libunistring-0.9.9.tar; then
    wget https://mirrors.ocf.berkeley.edu/gnu/libunistring/libunistring-0.9.9.tar.xz
    unxz libunistring-0.9.9.tar.xz
fi
if ! test -f gmp-6.1.2.tar; then
    wget https://gmplib.org/download/gmp/gmp-6.1.2.tar.lz
    lzip -d gmp-6.1.2.tar.lz
fi
if ! test -f libffi-3.2.1.tar; then
    wget ftp://sourceware.org/pub/libffi/libffi-3.2.1.tar.gz
    gunzip libffi-3.2.1.tar.gz
fi
if ! test -f readline-7.0.tar; then
    wget https://mirrors.ocf.berkeley.edu/gnu/readline/readline-7.0.tar.gz
    gunzip readline-7.0.tar.gz
fi
if [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
    if ! test -f guile.tar; then
	wget http://git.savannah.gnu.org/cgit/guile.git/snapshot/guile-925485c27615ad20884b96fd6cff6d3dc08013de.tar.gz
	gunzip guile-925485c27615ad20884b96fd6cff6d3dc08013de.tar.gz
	mv guile-925485c27615ad20884b96fd6cff6d3dc08013de.tar guile.tar
    fi
else
    if ! test -f guile.tar; then
	wget https://mirrors.ocf.berkeley.edu/gnu/guile/guile-2.2.3.tar.lz
	lzip -d guile-2.2.3.tar.lz
	mv guile-2.2.3.tar guile.tar
    fi    
fi
if ! test -f libvorbis-1.3.6.tar; then
    wget https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-1.3.6.tar.xz
    unxz libvorbis-1.3.6.tar.xz
fi
if ! test -f burro-master.zip; then
    wget https://github.com/spk121/burro/archive/master.zip
    mv master.zip burro-master.zip
fi

tar xf libtool-2.4.tar
tar xf gc-7.6.4.tar
tar xf libatomic_ops-7.6.2.tar
if ! test -L gc-7.6.4/libatomic_ops ; then
   ln -s $PREFIX/libatomic_ops-7.6.2 $PREFIX/gc-7.6.4/libatomic_ops
fi
tar xf libunistring-0.9.9.tar
tar xf gmp-6.1.2.tar
tar xf libffi-3.2.1.tar
tar xf readline-7.0.tar
tar xf guile.tar
tar xf libvorbis-1.3.6.tar
unzip -o burro-master.zip


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
	cd guile-925485c27615ad20884b96fd6cff6d3dc08013de
	autoreconf -vif
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
    make install
    cd $PREFIX
    echo > _guile_complete
fi


if ! test -f _libvorbis_complete; then
    cd libvorbis-1.3.6
    ./configure CC=$CC CFLAGS="-g -O1" --disable-shared --enable-static --prefix=$PREFIX
    make
    make install
    cd $PREFIX
    echo > _libvorbis_complete
fi

if ! test -f _burro_complete; then
    cd burro-master
    autoreconf -vif
    ./configure CC=$CC CFLAGS="-g -O1" \
		LIBS="$PREFIX/lib/libguile.a $PREFIX/lib/gc.a $PREFIX/lib/libffi.a $PREFIX/lib/libgmp.a $PREFIX/lib/libltdl.a $PREFIX/lib/libunistring.a $PREFIX/lib/libreadline.a $PREFIX/lib/libvorbis.a -ldl -lcrypt "	\
		GUILE_CFLAGS=-I$PREFIX/include/guile/2.2 \
		GUILE_LIBS=$PREFIX/lib/libguile-2.2.a \
		--disable-shared --enable-static \
		--with-libpulse \
		--prefix=$PREFIX
    make
    make install
    cd $PREFIX
    echo > _burro_complete
fi
