#!/bin/bash

REPORT=lfs-report.txt

banner () {
    echo ""
    echo ""
    echo "  _    ___ ___   ___ _   ___ _____    ___ ___  __  __ ___ ___ _    ___ "
    echo " | |  | __/ __| | __/_\ / __|_   _|  / __/ _ \|  \/  | _ \_ _| |  | __|"
    echo " | |__| _|\__ \ | _/ _ \\__ \ | |   | (_| (_) | |\/| |  _/| || |__| _| "
    echo " |____|_| |___/ |_/_/ \_\___/ |_|    \___\___/|_|  |_|_| |___|____|___|"
    echo ""
    echo " Written by Sxrce Cxde ID (viandwi24 & ubex)"
    echo " Satu kali jalan, tinggal ngopi dahhh"
    echo ""
    echo ""
}

continue_or_not () {
    echo ""
    echo -n "Continue (y/n)? "
    read answer
    if [ "$answer" != "${answer#[Yy]}" ] ;then
        "$@"
    else
        exit
    fi
    echo ""
}

curr_pwd () {
    echo "Current Folder : $(pwd)"
}

prepare () {
    echo "LFS REPORT" > $REPORT
}

step_1 () {
    echo "==[ STEP 1 : CHECKING"
    echo "* Curent User : $(whoami)"
    echo "* LFS : ${LFS}"
    echo "* LC_ALL : ${LC_ALL}"
    echo "* LFS_TGT : ${LFS_TGT}"
    echo "* PATH : ${PATH}"
    echo "* CONFIG_SITE : ${CONFIG_SITE}"
    echo "* MAKEFLAGS : ${MAKEFLAGS}"
}

step_2 () {
    declare -a PACKAGE_CROSS_TOOLCHAIN
    PACKAGE_CROSS_TOOLCHAIN=(binutils-2.37.tar.xz gcc-11.2.0.tar.xz linux-5.13.12.tar.xz glibc-2.34.tar.xz gcc-11.2.0.tar.xz)
    COMMANDS_0=(
        "mkdir -v build"
        "cd build"
        "../configure --prefix=$LFS/tools --with-sysroot=$LFS --target=$LFS_TGT --disable-nls --disable-werror"
        "make ${MAKEFLAGS}"
        "make install ${MAKEFLAGS}"
    )
    COMMANDS_1=(
        "tar -xf ../mpfr-4.1.0.tar.xz"
        "mv -v mpfr-4.1.0 mpfr"
        "tar -xf ../gmp-6.2.1.tar.xz"
        "mv -v gmp-6.2.1 gmp"
        "tar -xf ../mpc-1.2.1.tar.gz"
        "mv -v mpc-1.2.1 mpc"
        "case $(uname -m) in
        x86_64)
            sed -e '/m64=/s/lib64/lib/' \
                -i.orig gcc/config/i386/t-linux64
        ;;
        esac"
        "mkdir -v build"
        "cd build"
        "../configure --target=$LFS_TGT --prefix=$LFS/tools --with-glibc-version=2.11  --with-sysroot=$LFS  --with-newlib  --without-headers --enable-initfini-array --disable-nls           --disable-shared        --disable-multilib      --disable-decimal-float --disable-threads       --disable-libatomic     --disable-libgomp       --disable-libquadmath   --disable-libssp        --disable-libvtv        --disable-libstdcxx     --enable-languages=c,c++"
        "make ${MAKEFLAGS}"
        "make install ${MAKEFLAGS}"
        "cd .."
        "cat gcc/limitx.h gcc/glimits.h gcc/limity.h > `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/install-tools/include/limits.h"
    )
    COMMANDS_2=(
        "make mrproper"
        "make headers"
        "find usr/include -name '.*' -delete"
        "rm usr/include/Makefile"
        "cp -rv usr/include $LFS/usr"
    )
    COMMANDS_3=(
        "case $(uname -m) in
            i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
            ;;
            x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
                    ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
            ;;
        esac"
        "patch -Np1 -i ../glibc-2.34-fhs-1.patch"
        "mkdir -v build"
        "cd build"
        'echo "rootsbindir=/usr/sbin" > configparms'
        "../configure --prefix=/usr --host=$LFS_TGT --build=$(../scripts/config.guess) --enable-kernel=3.2 --with-headers=$LFS/usr/include libc_cv_slibdir=/usr/lib"
        "make ${MAKEFLAGS}"
        "make DESTDIR=$LFS install ${MAKEFLAGS}"
        "sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd"
        "echo 'int main(){}' > dummy.c"
        "$LFS_TGT-gcc dummy.c"
        "readelf -l a.out | grep '/ld-linux'"
        "rm -v dummy.c a.out"
        "$LFS/tools/libexec/gcc/$LFS_TGT/11.2.0/install-tools/mkheaders"
    )
    COMMANDS_4=(
        "mkdir -v build"
        "cd build"
        "../libstdc++-v3/configure --host=$LFS_TGT --build=$(../config.guess)    --prefix=/usr   --disable-multilib
   --disable-nls   --disable-libstdcxx-pch       --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/11.2.0"
        "make ${MAKEFLAGS}"
        "make DESTDIR=$LFS install  ${MAKEFLAGS}"
    )


    echo "==[ STEP 2 : Compiling a Cross-Toolchain"
    echo "This step will compiling a package :"
    for i in "${PACKAGE_CROSS_TOOLCHAIN[@]}"
        do
        if [ -f "$LFS/sources/$i" ]; then
            echo "* $i [OK]"
        else
            echo "* $i [FILE NOT FOUND]"
        fi
    done
    continue_or_not

    echo "[+] ENTERING SOURCES DIR"
    cd $LFS/sources
    echo "Current Dir : $(pwd)"
    echo

    echo "[+] COMPILING PACKAGES"
    for i in "${!PACKAGE_CROSS_TOOLCHAIN[@]}"; do
        names=(${PACKAGE_CROSS_TOOLCHAIN[$i]//.tar/ })


        echo "* EXTRACTING PACKAGE..."
        echo "extracting package ${names[0]}" >> $REPORT
        tar_name="${PACKAGE_CROSS_TOOLCHAIN[$i]}"
        tar -xf $tar_name

        echo "* COMPILING PACKAGE : ${names[0]}"
        echo "Compiling package ${names[0]}" >> $REPORT
        package_folder=$LFS/sources/${names[0]}

        echo "Entering package folder $package_folder"
        cd $package_folder
        curr_pwd

        vname=COMMANDS_$i
        eval 'for j in "${!COMMANDS_'"$i"'[@]}"; do eval ${COMMANDS_'"$i"'[$j]}; done'

        echo "Compiling Complete... Leaving package folder"
        echo "Compiling Complete ${names[0]}" >> $REPORT
        cd $LFS/sources
        curr_pwd

        echo "Removing unpack folder package..."
        echo "Removing unpack folder package ${names[0]}" >> $REPORT
        rm -rf $package_folder

        echo
    done
}


# MAIN SCRIPT
prepare
banner
step_1
continue_or_not
step_2
