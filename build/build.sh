#!/bin/bash

export JAVA_HOME=$(readlink -f /usr/lib/jvm/java-1.*)
export PKG_CONFIG_PATH=/usr/local/$CROSS_TRIPLE/lib/pkgconfig
export PKG_CONFIG_LIBDIR=/usr/$CROSS_TRIPLE/lib/pkgconfig:/usr/local/$CROSS_TRIPLE/lib/pkgconfig

DEBUG=0
MOUNT_DIR=$(pwd)/mount

PREFIX=/usr/local/$CROSS_TRIPLE
INCLUDE_DIR=$PREFIX/include
LIB_DIR=$PREFIX/lib

if echo "$CROSS_TRIPLE" | grep -q mingw32
then
	OSTYPE=msys
elif echo "$CROSS_TRIPLE" | grep -q darwin
then
	OSTYPE=darwin
else
	OSTYPE=linux-gnu
fi

mkdir "$CROSS_TRIPLE"
cd "$CROSS_TRIPLE" || exit 1

init_build_context() {

	local name

	if [ -z "$3" ]
	then
		name=$2
	else
		name=$3
	fi

	echo "Building $name for $CROSS_TRIPLE..."
	wget "$1" -qO- | tar xzf -
	cd "$2"* || exit 1
}

quit_build_context() {
	cd .. || exit 1
}

conf() {
	if [ $DEBUG -eq 0 ]
	then
		./configure "$@" > /dev/null || exit 1
	else
		./configure "$@" || exit
	fi
}

build() {
	if [ $DEBUG -eq 0 ]
	then
		make -s > /dev/null || exit 1
	else
		make || exit 1
	fi

	quit_build_context
}

install() {
	if [ $DEBUG -eq 0 ]
	then
		make -s install > /dev/null || exit 1
	else
		make install || exit 1
	fi

	quit_build_context
}

conf_build() {
	conf "$@"
	build
}

conf_install() {
	conf "$@"
	install
}

install_zlib() {
	init_build_context https://github.com/madler/zlib/archive/v1.2.11.tar.gz zlib

	if [ $OSTYPE = msys ]
	then
		sed -i "s/SHARED_MODE=0/SHARED_MODE=1/" win32/Makefile.gcc

		DESTDIR=$PREFIX/ BINARY_PATH=bin INCLUDE_PATH=include LIBRARY_PATH=lib make -f win32/Makefile.gcc -s install || exit 1
		quit_build_context
	else
		conf_install --prefix="$PREFIX" --static
	fi
}

install_libpng() {
	init_build_context https://github.com/glennrp/libpng/archive/v1.6.37.tar.gz libpng
	LIBPNG=$(pwd)

	conf_build --host "$CROSS_TRIPLE" --prefix="$PREFIX" CPPFLAGS="-I$INCLUDE_DIR" LDFLAGS="-L$LIB_DIR"
}

install_lcms2() {

	init_build_context https://github.com/mm2/Little-CMS/archive/2.11.tar.gz Little-CMS lcms2

	conf --host "$CROSS_TRIPLE" CPPFLAGS="-I$INCLUDE_DIR" LDFLAGS="-L$LIB_DIR"

	# Pour clang
	if [ $OSTYPE = darwin ]
	then
		sed -i -re 's/(-DPACKAGE_STRING=\\"[^"]+)\\ ([^"]+\\")/\1-\2/' src/Makefile utils/{linkicc,psicc,transicc}/Makefile
	fi

	install
}

install_libimagequant() {
	init_build_context https://github.com/ImageOptim/libimagequant/archive/2.12.6.tar.gz libimagequant
	LIBIMAGEQUANT=$(pwd)

	OSTYPE=$OSTYPE conf_build --prefix="$PREFIX" $OPENMP CFLAGS="-I$JAVA_HOME/include"
}

if [ $OSTYPE != 'darwin' ]
then
	OPENMP="--with-openmp=static"
fi

LDFLAGS="-L$LIB_DIR"

if [ $OSTYPE = 'msys' ]
then
	LDFLAGS="$LDFLAGS -static"
fi

install_zlib
install_libpng
install_lcms2
install_libimagequant

init_build_context https://github.com/kornelski/pngquant/archive/2.12.6.tar.gz pngquant
PNGQUANT=$(pwd)

for patch in "$MOUNT_DIR/patches/"*
do
	patch < "$patch"
done

OSTYPE=$OSTYPE conf_build --with-libimagequant="$LIBIMAGEQUANT" --with-libpng="$LIBPNG" $OPENMP LDFLAGS="$LDFLAGS"

mkdir "$MOUNT_DIR/$CROSS_TRIPLE"
cp "$PNGQUANT/pngquant" "$MOUNT_DIR/$CROSS_TRIPLE/"
