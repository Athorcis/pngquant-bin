#!/bin/bash

build() {
	MSYS_NO_PATHCONV=1 docker run --rm -v "$(pwd):/workdir/mount" -e CROSS_TRIPLE=$1 cirkwi/crossbuild ./mount/build.sh
	cp $1*/pngquant ../vendor/$2/pngquant$3
	rm -R $1*
}

if [ -z "$(docker image ls -q multiarch/crossbuild:cirkwi 2> /dev/null)" ]
then
	docker image build https://github.com/multiarch/crossbuild.git#529881986478b18c9973b8979fa6287d44a77c8f --tag multiarch/crossbuild:cirkwi
fi

docker image build . --tag cirkwi/crossbuild

build x86_64-apple-darwin macos
build x86_64-w64-mingw32 win .exe
build x86_64-linux-gnu linux/x64
