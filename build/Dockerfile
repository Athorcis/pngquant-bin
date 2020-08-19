FROM multiarch/crossbuild:cirkwi

RUN apt-get update		\
 && apt-get install -y	\
 		default-jdk		\
		pkg-config		\
 && apt-get clean

RUN rm /usr/i386-apple-darwin14/bin/pkg-config \
 && rm /usr/x86_64-apple-darwin14/bin/pkg-config

ENV OSXCROSS_LLVM_DSYMUTIL=/usr/bin/llvm-dsymutil-3.8
