#!/bin/bash

set -e

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null && pwd)
cd "$HERE"

rm build/*.o &> /dev/null || true

if [ "$1" = "-n" ]; then
    NI_CFLAGS=""
    NI_LDFLAGS=""
    shift
else
    NI_CFLAGS="-DWITH_NI"
    NI_LDFLAGS="-lnidaqmxbase"
fi

export CFLAGS="$CFLAGS $NI_CFLAGS -I$HERE -ggdb -I$(pwd)/.deps/pbl/src"\
"    -I$(pwd)/.deps/include"
export LDFLAGS="$LDFLAGS -L$(pwd)/.deps/lib -ggdb"
export CXXFLAGS="$CFLAGS"
LLPA="$(pwd)/.deps/lib"
if [ -z "$LD_LIBRARY_PATH" ]; then
    export LD_LIBRARY_PATH="$LLPA"
else
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$LLPA"
fi

if [ "$(uname -s)" != "Darwin" ]; then
    LDFLAGS="$LDFLAGS -lrt"
fi

function compile_c() {
    echo "- Compiling $1.c"
    ALDF="-lpthread"
    if [ "$(uname -s)" = "Darwin" ]; then
        ALDF=""
    fi
    gcc -std=gnu99 -Wall -Werror -pedantic $ALDF -c $CFLAGS \
        -Idaemon -Icommon -Igensrc \
        -o "build/$(basename $1).o" $1.c
}

function install_pbl() {
    cd .deps
    if [ ! -d pbl ]; then
        echo "- Fetching pbl"
        wget -q http://www.mission-base.com/peter/source/pbl_1_04.tar.gz
        echo "- Unpacking pbl"
        tar xf pbl_1_04.tar.gz
        mv pbl_1_04_04 pbl
    fi

    echo "- Building PBL"
    cd pbl/src
    make
    cd ../../..
}

function install_protobuf() {
  cd .deps
  if [ ! -d protobuf-src ]; then
      echo "- Fetching protobuf"
      wget -q -O protobuf.tar.bz2 'http://protobuf.googlecode.com/files/protobuf-2.4.1.tar.bz2'
      echo "- Unpacking protobuf"
      tar xjf protobuf.tar.bz2
      mv protobuf-2.4.1 protobuf-src
  fi

  if [ ! -d protobuf-c-src ]; then
      echo "- Fetching protobuf-c"
      wget -q -O protobuf-c.tar.bz2 'http://protobuf-c.googlecode.com/files/protobuf-c-0.15.tar.gz'
      echo "- Unpacking protobuf-c"
      tar xzf protobuf-c.tar.bz2
      mv protobuf-c-0.15 protobuf-c-src
  fi

  echo "- Building protobuf"
  cd protobuf-src
  if [ ! -f Makefile ]; then
      ./configure --prefix="$(pwd)/.."
  fi
  make
  make install
  cd ..

  cd protobuf-c-src
  if [ ! -f Makefile ]; then
      ./configure --prefix="$(pwd)/.."
  fi
  make
  make install
  cd ../..
}

echo "- Generating protos"
cd protos &> /dev/null
for f in *.proto; do
    protoc-c --c_out=../gensrc "$f"
done
cd ..

ld $LDFLAGS -lprotobuf -lprotobuf-c &> /dev/null || install_protobuf

if [ "$#" -lt 1 -o "$1" = "client" ]; then
    rm build/*.o &> /dev/null || true
    echo
    echo "Building Utils"
    compile_c common/utils

    echo
    echo "Building Client"

    compile_c client/libpmlab
    compile_c client/pmlabclient
    for f in gensrc/*.c; do
        compile_c ${f%*.c}
    done
    echo "- Linking pmlabclient"
    if [ -f build/libpmlab ]; then
        rm build/libpmlab
    fi
    gcc $LDFLAGS -lprotobuf-c -o build/pmlabclient build/*.o
fi


if [ "$#" -lt 1 -o "$1" = "daemon" ]; then
    install_pbl

    rm build/*.o &> /dev/null || true
    echo
    echo "Building Utils"
    compile_c common/utils

    echo
    echo "Building Daemon"
    compile_c daemon/handler
    compile_c daemon/sync
    for f in gensrc/*.c; do
        compile_c ${f%*.c}
    done
    compile_c daemon/daemon
    echo "- Linking deamon"
    if [ -f build/daemon ]; then
        rm build/daemon
    fi
    gcc $LDFLAGS $NI_LDFLAGS -lprotobuf-c -lpthread -o build/daemon \
        build/*.o .deps/pbl/src/libpbl.a
fi

CMD="export LD_LIBRARY_PATH=\"$LD_LIBRARY_PATH\""
if ! grep -q LD_LIBRARY_PATH ~/.bashrc; then
    echo "$CMD" >> ~/.bashrc
    echo "Added the following commands to your bashrc:"
    echo "$CMD"
fi
echo
echo "Don't forget:"
echo "$CMD"
