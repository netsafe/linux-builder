
# BUILD_TYPE - determine a work list :
# 1 - full cycle with GCC and it's supplementary libraries
# 2 - minimal set of OpenSSL and tor itself, assuming we have run a full cycle recently and we do have all the libs we need built and available
# 3 - crontab mode, tor only

BUILD_TYPE=1

IS_MINI=`echo "$1 " | grep mini | wc -c`
if [ $IS_MINI -gt 3 ]; then
    BUILD_TYPE=2
else
    IS_MINI=`echo "$1 " | grep cron | wc -c`
    if [ $IS_MINI -gt 3 ]; then
	BUILD_TYPE=3
    fi
fi

if [ $BUILD_TYPE -eq 1 ]; then
    echo "Full build cycle is running"
fi
if [ $BUILD_TYPE -eq 2 ]; then
    echo "Minimal build cycle is running"
fi
if [ $BUILD_TYPE -eq 3 ]; then
    echo "Cron build cycle is running"
fi

ARCH_TEST=`uname -p | grep -c x86_64`
# preface
CFL="-mtune=native -march=native -fPIC"
ZTK=" "
OSSL_ARCH=" "
if [ $ARCH_TEST -gt 0 ]; then
    ZTK=" --64 "
    CFL="$CFL -m64 "
    OSSL_ARCH=linux-x86_64
else
    OSSL_ARCH=linux-x32
fi

GMP_VERSION=6.0.0a
MPFR_VERSION=3.1.2
MPC_VERSION=1.0.2
CLOOG_VERSION=0.18.1
LIBEVENT_VERSION=2.0.21
TOR_VERSION=0.2.4.22
ZLIB_VERSION=1.2.8
LIBNATPMP_VERSION=20140401
MINIUPNPC_VERSION=1.9

GMP_ARCHIVE=gmp-$GMP_VERSION.tar.bz2
GMP_URL=https://gmplib.org/download/gmp/$GMP_ARCHIVE
MPFR_ARCHIVE=mpfr-$MPFR_VERSION.tar.bz2
MPFR_URL=http://www.mpfr.org/mpfr-current/$MPFR_ARCHIVE
MPC_ARCHIVE=mpc-$MPC_VERSION.tar.gz
MPC_URL=ftp://ftp.gnu.org/gnu/mpc/$MPC_ARCHIVE
CLOOG_ARCHIVE=cloog-$CLOOG_VERSION.tar.gz
CLOOG_URL=ftp://gcc.gnu.org/pub/gcc/infrastructure/$CLOOG_ARCHIVE
LIBEVENT_ARCHIVE=libevent-$LIBEVENT_VERSION-stable.tar.gz
LIBEVENT_URL=https://github.com/downloads/libevent/libevent/$LIBEVENT_ARCHIVE
TOR_ARCHIVE=tor-$TOR_VERSION.tar.gz
TOR_URL=https://www.torproject.org/dist/$TOR_ARCHIVE
ZLIB_ARCHIVE=zlib-$ZLIB_VERSION.tar.gz
ZLIB_URL=http://zlib.net/$ZLIB_ARCHIVE
LIBNATPMP_ARCHIVE=libnatpmp-$LIBNATPMP_VERSION.tar.gz
LIBNATPMP_URL=http://miniupnp.free.fr/files/download.php?file=$LIBNATPMP_ARCHIVE
MINIUPNPC_ARCHIVE=miniupnpc-$MINIUPNPC_VERSION.tar.gz
MINIUPNPC_URL=http://miniupnp.free.fr/files/download.php?file=$MINIUPNPC_ARCHIVE


if [ -d /usr/work/archive ]; then
    echo "Work directory exists"
else
    mkdir -p /usr/work/archive
fi

if [ -d /usr/work/repo ]; then
    echo "Repo directory exists"
else
    mkdir -p /usr/work/repo
fi


# Do the fetch
cd /usr/work/repo
if [ $BUILD_TYPE -lt 3 ]; then
    if [ -d openssl ]; then
	cd openssl
	git pull
	cd /usr/work/repo
    else
	git clone git://git.openssl.org/openssl.git
    fi
    if [ -d OpenSC ]; then
	cd OpenSC
	git pull
	cd /usr/work/repo
    else
	git clone https://github.com/OpenSC/OpenSC.git
    fi
    if [ -d openct ]; then
	cd openct
	git pull
	cd /usr/work/repo
    else
	git clone https://github.com/OpenSC/openct.git
    fi
    if [ -d libusb ]; then
	cd libusb
	git pull
	cd /usr/work/repo
    else
	git clone http://git.libusb.org/libusb.git
    fi
    if [ -d libusb-compat-0.1 ]; then
	cd libusb-compat-0.1
	git pull
	cd /usr/work/repo
    else
	git clone http://git.libusb.org/libusb-compat-0.1.git
    fi
fi
if [ $BUILD_TYPE -lt 2 ]; then
    if [ -d gcc ]; then
	cd gcc
	git pull
	cd /usr/work/repo
    else
	git clone git://gcc.gnu.org/git/gcc.git
    fi

    if [ -d lksctp-tools ]; then
	cd lksctp-tools
	git pull
	cd /usr/work/repo
    else
	git clone git://github.com/borkmann/lksctp-tools.git
    fi
fi

# Do the archive fetch
cd /usr/work/archive
if [ $BUILD_TYPE -lt 3 ]; then
    if [ -f $GMP_ARCHIVE ]; then
	echo "GMP archive exists"
    else
	wget $GMP_URL
    fi

    if [ -f $MPFR_ARCHIVE ]; then
	echo "MPFR archive exists"
    else
	wget $MPFR_URL
    fi

    if [ -f $MPC_ARCHIVE ]; then
	echo "MPC archive exists"
    else
	wget $MPC_URL
    fi

    if [ -f $CLOOG_ARCHIVE ]; then
	echo "Cloog archive exists"
    else
	wget $CLOOG_URL
    fi

    if [ -f $LIBEVENT_ARCHIVE ]; then
	echo "libEvent archive exists"
    else
	wget $LIBEVENT_URL
    fi

    if [ -f $ZLIB_ARCHIVE ]; then
	echo "Zlib archive exists"
    else
	wget $ZLIB_URL
    fi

    if [ -f $LIBNATPMP_ARCHIVE ]; then
	echo "Libnatpmp archive exists"
    else
	wget $LIBNATPMP_URL -O $LIBNATPMP_ARCHIVE
    fi

    if [ -f $MINIUPNPC_ARCHIVE ]; then
	echo "Mini-UPnP client archive exists"
    else
	wget $MINIUPNPC_URL -O $MINIUPNPC_ARCHIVE
    fi
fi

if [ -f $TOR_ARCHIVE ]; then
    echo "Tor archive exists"
else
    wget $TOR_URL
fi


# Fetching and updating done

if [ -d /usr/work/build ]; then
    echo "Build directory exists, destroying"
    rm -fr /usr/work/build
fi

mkdir -p /usr/work/build
# extract
cd /usr/work/archive
mkdir /usr/work/build/gmp
tar xf $GMP_ARCHIVE -C /usr/work/build/gmp --strip-components=1
mkdir /usr/work/build/mpfr
tar xf $MPFR_ARCHIVE -C /usr/work/build/mpfr --strip-components=1
mkdir /usr/work/build/mpc
tar xf $MPC_ARCHIVE -C /usr/work/build/mpc --strip-components=1
mkdir /usr/work/build/cloog
tar xf $CLOOG_ARCHIVE -C /usr/work/build/cloog --strip-components=1
mkdir /usr/work/build/libevent
tar xf $LIBEVENT_ARCHIVE -C /usr/work/build/libevent --strip-components=1
mkdir /usr/work/build/tor
tar xf $TOR_ARCHIVE -C /usr/work/build/tor --strip-components=1
mkdir /usr/work/build/zlib
tar xf $ZLIB_ARCHIVE -C /usr/work/build/zlib --strip-components=1
mkdir /usr/work/build/libnatpmp
tar xf $LIBNATPMP_ARCHIVE -C /usr/work/build/libnatpmp --strip-components=1
mkdir /usr/work/build/miniupnpc
tar xf $MINIUPNPC_ARCHIVE -C /usr/work/build/miniupnpc --strip-components=1


# SCM extract
cd /usr/work/repo
cd openssl
if [ $BUILD_TYPE -lt 3 ]; then
    mkdir -p /usr/work/build/openssl
    cd /usr/work/repo/openssl
    git checkout-index -f -a --prefix=/usr/work/build/openssl/
    mkdir -p /usr/work/build/OpenSC
    cd ../OpenSC
    git checkout-index -f -a --prefix=/usr/work/build/OpenSC/
    mkdir -p /usr/work/build/openct
    cd ../openct
    git checkout-index -f -a --prefix=/usr/work/build/openct/
    mkdir -p /usr/work/build/libusb
    cd ../libusb
    git checkout-index -f -a --prefix=/usr/work/build/libusb/
    mkdir -p /usr/work/build/libusb-compat
    cd ../libusb-compat-0.1
    git checkout-index -f -a --prefix=/usr/work/build/libusb-compat/
fi
if [ $BUILD_TYPE -lt 3 ]; then
    mkdir -p /usr/work/build/gcc
    cd ../gcc
    git checkout-index -f -a --prefix=/usr/work/build/gcc/
    mkdir -p /usr/work/build/sctp
    cd ../lksctp-tools
    git checkout-index -f -a --prefix=/usr/work/build/sctp/
fi
# compile
cd /usr/work/build
if [ -d gmp ]; then
    echo "OK"
else
mkdir gmp
fi
if [ $BUILD_TYPE -lt 3 ]; then
    if [ -f /usr/bin/gcc-trunk ]; then
	echo " GCC is in place"
	cd gmp
    else
	# GMP
	cd gmp
	./configure --prefix=/usr --enable-cxx --with-pic --enable-dependency-tracking
	make -j4 && make install clean
	# MPFR
	cd ../mpfr
	./configure --prefix=/usr --enable-thread-safe --with-gmp=/usr --with-pic --enable-dependency-tracking
	make -j4 && make install clean
	# MPC
	cd ../mpc
	./configure --prefix=/usr --with-gmp=/usr --with-mpfr=/usr --with-pic --enable-dependency-tracking
	make -j4 && make install clean
	# ClooG
	cd ../cloog
	./configure --prefix=/usr --with-gcc-arch=native --with-isl=bundled --with-gmp-prefix=/usr --enable-dependency-tracking --with-pic
	make -j4 && make install clean
	# gcc
	cd ../gcc
	./configure --prefix=/usr --program-suffix=-trunk --enable-graphite --enable-languages=c,c++,fortran,objc,obj-c++ --disable-java --disable-libjava --with-mpc=/usr --with-gmp=/usr --with-mpfr=/usr --with-cloog=/usr --enable-objc-gc --enable-stage1-languages=c,c++,fortran,objc,obj-c++ --enable-lto --enable-libssp --enable-ld=yes --enable-gold=yes --enable-decimal-float=yes --with-arch=native --enable-tls --enable-threads --enable-multiarch --enable-multilib --enable-dependency-tracking
	make -j8 && make install clean
    fi
fi
# second circle
if [ $BUILD_TYPE -lt 3 ]; then
    cd ../gmp
    ./configure --prefix=/usr --enable-cxx --with-pic --enable-dependency-tracking CC=/usr/bin/gcc-trunk CXX=/usr/bin/g++-trunk CFLAGS="$CFL"
    make -j4 && make install clean
fi
if [ $BUILD_TYPE -lt 2 ]; then
    # MPFR
    cd ../mpfr
    ./configure --prefix=/usr --enable-thread-safe --with-gmp=/usr --with-pic --enable-dependency-tracking CC=/usr/bin/gcc-trunk CXX=/usr/bin/g++-trunk CFLAGS="$CFL"
    make -j4 && make install clean
    # MPC
    cd ../mpc
    ./configure --prefix=/usr --with-gmp=/usr --with-mpfr=/usr --with-pic --enable-dependency-tracking CC=/usr/bin/gcc-trunk CXX=/usr/bin/g++-trunk CFLAGS="$CFL"
    make -j4 && make install clean
    # ClooG
    cd ../cloog
    ./configure --prefix=/usr --with-gcc-arch=native --with-isl=bundled --with-gmp-prefix=/usr --enable-dependency-tracking --with-pic CC=/usr/bin/gcc-trunk CXX=/usr/bin/g++-trunk CFLAGS="$CFL"
    make -j4 && make install clean
    # gcc X2
    cd ../gcc
    ./configure --prefix=/usr --program-suffix=-trunk --enable-graphite --enable-languages=c,c++,fortran,objc,obj-c++ --disable-java --disable-libjava --with-mpc=/usr --with-gmp=/usr --with-mpfr=/usr --with-cloog=/usr --enable-objc-gc --enable-stage1-languages=c,c++,fortran,objc,obj-c++ --enable-lto --enable-libssp --enable-ld=yes --enable-gold=yes --enable-decimal-float=yes --with-arch=native --enable-tls --enable-threads --enable-multiarch --enable-multilib --enable-dependency-tracking CC=/usr/bin/gcc-trunk CXX=/usr/bin/g++-trunk
    make -j8 && make install clean
    # Zlib
    cd ../zlib
    export CC="/usr/bin/gcc-trunk $CFL "
    ./configure --prefix=/usr $ZTK
    make && make install clean
    unset CC
    # SCTP
    cd ../sctp
    ./bootstrap
    ./configure --prefix=/usr --enable-dependency-tracking --with-pic CC=/usr/bin/gcc-trunk CXX=/usr/bin/g++-trunk CFLAGS="$CFL"
    make && make install clean
fi
if [ $BUILD_TYPE -lt 3 ]; then
    #openssl
    cd ../openssl
    export CC="/usr/bin/gcc-trunk $CFL "
    ./Configure --prefix=/usr --openssldir=/etc/ssl threads zlib enable-ec_nistp_64_gcc_128  enable-cbc3 enable-blowfish enable-bf enable-idea enable-ec shared $OSSL_ARCH
    make && make install clean
    unset CC
    cd ../libusb
    ./autogen.sh
    ./configure --prefix=/usr --with-pic=all --enable-dependency-tracking --enable-debug-log CC=/usr/bin/gcc-trunk CXX=/usr/bin/g++-trunk CFLAGS="$CFL"
    cd ../libusb-compat
    ./autogen.sh
    ./configure --prefix=/usr --with-pic=all --enable-dependency-tracking --enable-debug-log CC=/usr/bin/gcc-trunk CXX=/usr/bin/g++-trunk CFLAGS="$CFL"
    make -j4 && make install clean
    cd ../openct
    ./bootstrap
    ./configure --prefix=/usr --enable-dependency-tracking --enable-usb --enable-non-privileged --with-pic=all --sysconfdir=/etc --localstatedir=/var CC=/usr/bin/gcc-trunk CXX=/usr/bin/g++-trunk CFLAGS="$CFL"
    make -j4 && make install
    cp etc/init-script /etc/init.d/openct
    ln -s /etc/init.d/openct /etc/rc0.d/K50openct
    ln -s /etc/init.d/openct /etc/rc1.d/S50openct
    ln -s /etc/init.d/openct /etc/rc2.d/S50openct
    ln -s /etc/init.d/openct /etc/rc3.d/S50openct
    ln -s /etc/init.d/openct /etc/rc4.d/S50openct
    ln -s /etc/init.d/openct /etc/rc5.d/S50openct
    ln -s /etc/init.d/openct /etc/rc6.d/K20openct

    cp etc/openct.udev /etc/udev/rules.d/95-openct.rules
    cp etc/openct_usb /lib/udev/openct_usb
    cp etc/openct_pcmcia /lib/udev/openct_pcmcia
    cp etc/openct_serial /lib/udev/openct_serial
    chmod +x /etc/init.d/openct
    update-rc.d openct defaults
    G_VALID=`getent group usb | wc -l`
    if [ $G_VALID -lt 1 ]; then
	groupadd -r usb
    fi
    G_VALID=`getent group openctd | wc -l`
    if [ $G_VALID -lt 1 ]; then
	useradd -m -U -r openctd
    fi
    service openct start
    make clean
    cd ../OpenSC
    ./bootstrap
    ./configure --prefix=/usr --enable-dependency-tracking --disable-man --with-pic=all --enable-openct --disable-pcsc --sysconfdir=/etc --localstatedir=/var CC=/usr/bin/gcc-trunk CXX=/usr/bin/g++-trunk CFLAGS="$CFL"
    make -j4 && make install clean
fi
if [ $BUILD_TYPE -lt 2 ]; then
    #libevent
    cd ../libevent
    ./configure --prefix=/usr --with-pic CC=/usr/bin/gcc-trunk CXX=/usr/bin/g++-trunk CFLAGS="$CFL"
    make -j4 && make install clean
    #libnatpmp
    cd ../libnatpmp
    make CC=/usr/bin/gcc-trunk && make install
    cp /usr/work/build/libnatpmp/declspec.h /usr/include
    #miniupnpc
    cd ../miniupnpc
    make CC=/usr/bin/gcc-trunk && make install
fi
#tor
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/lib64:/usr/lib"
cd /usr/work/build/tor
./configure --prefix=/usr --enable-dependency-tracking --enable-nat-pmp --enable-upnp --disable-asciidoc --sysconfdir=/etc --localstatedir=/var CC=/usr/bin/gcc-trunk CXX=/usr/bin/g++-trunk CFLAGS="-L/usr/lib -L/usr/lib64 $CFL"
make -j4 && make install

