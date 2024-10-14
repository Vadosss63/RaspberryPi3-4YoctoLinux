# Dockerfile for setting up Yocto build environment for Raspberry Pi 3 with Qt6 support

# Use an Ubuntu LTS image as the base
FROM ubuntu:22.04

# Set up environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PATH=$PATH:/home/yoctouser/bin

# Install required packages for Yocto and repo tool
RUN apt-get update && apt-get install -y \
    gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath \
    socat cpio python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping \
    libsdl1.2-dev xterm curl locales sudo bash \
    file lz4 zstd git repo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set locale to avoid locale issues
RUN locale-gen en_US.UTF-8

# Install repo tool for managing Yocto layers via manifest
RUN mkdir -p /home/yoctouser/bin && \
    curl https://storage.googleapis.com/git-repo-downloads/repo > /home/yoctouser/bin/repo && \
    chmod a+x /home/yoctouser/bin/repo

# Ensure /home/yoctouser/bin is in PATH
RUN echo 'export PATH=$PATH:/home/yoctouser/bin' >> /home/yoctouser/.bashrc

# Create a user to run Yocto build and set permissions
RUN useradd -ms /bin/bash yoctouser && \
    echo "yoctouser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER yoctouser
WORKDIR /home/yoctouser

# Set the default command to bash
CMD ["bash"]
