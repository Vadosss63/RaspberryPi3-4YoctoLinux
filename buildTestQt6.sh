#!/bin/bash
set -e

YOCTO_BRANCH="kirkstone"
RPI_MACHINE="raspberrypi3-64"
QT_VERSION="v6.5.0"
APP_NAME="myapp"

echo "Cloning Yocto layers..."

if [ ! -d "poky" ]; then
    git clone git://git.yoctoproject.org/poky -b $YOCTO_BRANCH
fi

if [ ! -d "meta-raspberrypi" ]; then
    git clone git://git.yoctoproject.org/meta-raspberrypi -b $YOCTO_BRANCH
fi

if [ ! -d "meta-qt6" ]; then
    git clone https://code.qt.io/yocto/meta-qt6.git meta-qt6
    cd meta-qt6
    git checkout refs/tags/$QT_VERSION
    cd ..
fi

if [ ! -d "meta-openembedded" ]; then
    git clone git://git.openembedded.org/meta-openembedded -b $YOCTO_BRANCH
fi

echo "Setting up Yocto build environment..."
source poky/oe-init-build-env build

if [ ! -d "../meta-$APP_NAME" ]; then
    echo "Creating custom layer for $APP_NAME..."
    cd ..
    bitbake-layers create-layer meta-$APP_NAME
    cd build
fi

APP_RECIPE_PATH="../meta-$APP_NAME/recipes-qt/$APP_NAME"
APP_SRC_PATH="/home/yoctouser/testQt6"  

if [ ! -d "$APP_RECIPE_PATH" ]; then
    echo "Creating recipe for $APP_NAME..."
    mkdir -p $APP_RECIPE_PATH/files
    cp -r $APP_SRC_PATH/* $APP_RECIPE_PATH/files
    
    cat << EOF > $APP_RECIPE_PATH/$APP_NAME.bb
SUMMARY = "My Test Qt6 Application"
LICENSE = "CLOSED"
SRC_URI = "file://CMakeLists.txt \
           file://main.cpp \
           file://mainwindow.cpp \
           file://mainwindow.h \
           file://mainwindow.ui"

S = "\${WORKDIR}"

inherit qt6-cmake

DEPENDS += "qtbase qtdeclarative qtwayland"

do_install() {
    install -d \${D}\${bindir}
    install -m 0755 \${B}/testQt6 \${D}\${bindir}
}
EOF
fi

echo "Configuring local.conf and adding layers..."

if ! grep -q "MACHINE = \"$RPI_MACHINE\"" conf/local.conf; then
    echo "MACHINE = \"$RPI_MACHINE\"" >> conf/local.conf
fi

bitbake-layers add-layer ../meta-raspberrypi
bitbake-layers add-layer ../meta-openembedded/meta-oe
bitbake-layers add-layer ../meta-openembedded/meta-python
bitbake-layers add-layer ../meta-openembedded/meta-networking
bitbake-layers add-layer ../meta-openembedded/meta-filesystems
bitbake-layers add-layer ../meta-qt6
bitbake-layers add-layer ../meta-$APP_NAME

if ! grep -q 'IMAGE_INSTALL:append = " qtbase qtwayland qtwayland-dev wayland wayland-protocols weston mesa-driver-swrast libdrm libdrm-dev kernel-modules"' conf/local.conf; then
    echo 'IMAGE_INSTALL:append = " qtbase qtwayland qtwayland-dev wayland wayland-protocols weston mesa-driver-swrast libdrm libdrm-dev kernel-modules"' >> conf/local.conf
fi

if ! grep -q 'DISTRO_FEATURES:append = " opengl wayland"' conf/local.conf; then
    echo 'DISTRO_FEATURES:append = " opengl wayland"' >> conf/local.conf
fi

if ! grep -q 'DISTRO_FEATURES:remove = " x11"' conf/local.conf; then
    echo 'DISTRO_FEATURES:remove = " x11"' >> conf/local.conf
fi

if ! grep -q "IMAGE_INSTALL:append = \" $APP_NAME\"" conf/local.conf; then
    echo "IMAGE_INSTALL:append = \" $APP_NAME\"" >> conf/local.conf
fi

echo "Building the image with Qt6 and Wayland support..."
bitbake core-image-minimal
