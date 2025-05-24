# ARG MATLAB_VERSION=r2024b

FROM ubuntu:24.04

#ARG SCALA_VERSION=2.13.13
ARG SBT_VERSION=1.3.7
ARG KYX_VERSION_STRING=5
ARG ARCH_YEAR=arch2022
ARG WOLFRAM_ENGINE_PATH=/usr/local/Wolfram/WolframEngine
ARG DEBIAN_FRONTEND=noninteractive
ARG USER_NAME
ENV TZ=America/New_York


# Install requirements
RUN apt-get --yes update && \
  apt-get --yes upgrade && \
  apt-get --no-install-recommends --yes install \
  apt-utils \
  software-properties-common \
  curl \
  avahi-daemon \
  wget \
  unzip \
  zip \
  build-essential \
  openjdk-21-jre-headless \
  openjdk-21-jdk \
  git \
  sshpass \
  sudo \
  locales \
  locales-all \
  ssh \
  vim \
  expect \
  libfontconfig1 \
  util-linux \
  ca-certificates && \
  apt-get clean && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/*

# Install Z3
RUN apt-get update && \
  apt-get install -y z3 && \
  rm -rf /var/lib/apt/lists/*

# Add user and grant sudo permission.
RUN useradd --shell /bin/bash --create-home --base-dir / ${USER_NAME} || true && \
  echo "${USER_NAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER_NAME} && \
  chmod 0440 /etc/sudoers.d/${USER_NAME}

USER ${USER_NAME}
WORKDIR /${USER_NAME}

RUN sudo systemctl enable avahi-daemon

WORKDIR /tmp/

# Install SBT
RUN wget https://scala.jfrog.io/artifactory/debian/sbt-${SBT_VERSION}.deb && \
  sudo dpkg -i sbt-${SBT_VERSION}.deb && \
  sudo apt-get --yes update && \
  sudo apt-get --yes upgrade && \
  sudo apt-get --yes install sbt && \
  rm sbt-${SBT_VERSION}.deb

# Install Wolfram Engine
RUN sudo bash -c 'echo "en_US.UTF-8 UTF-8" > /etc/locale.gen' && \
  sudo locale-gen
RUN wget -O wolframengine "https://account.wolfram.com/dl/WolframEngine?version=14.2.1&platform=Linux&downloadManager=false&includesDocumentation=false" && \
  sudo bash wolframengine -- -auto -verbose && \
  rm wolframengine

# # Pull KeYmaera X
WORKDIR /${USER_NAME}/
COPY keymaerax-core-5.1.1.jar /${USER_NAME}/keymaerax.jar

# # Export Wolfram Engine version for dockersetup.sh and path for dockerrun.sh
RUN ls ${WOLFRAM_ENGINE_PATH} > weversion.txt
RUN bash -l -c "echo \"${WOLFRAM_ENGINE_PATH}/"'$(<weversion.txt)/Executables" > wepath.txt'

# # Import benchmark index and script
WORKDIR /${USER_NAME}
COPY index${KYX_VERSION_STRING}/ ./index${KYX_VERSION_STRING}/
ADD *.xml ./
ADD runKeYmaeraX${KYX_VERSION_STRING}Benchmarks ./

# # Pull KeYmaera X Projects
WORKDIR /${USER_NAME}/
RUN git clone https://github.com/LS-Lab/KeYmaeraX-projects.git
RUN git checkout b9d7cb584e8fd1c3cc4f30644e82ba12cbb1d6fe

RUN mkdir -p /${USER_NAME}/kyx${KYX_VERSION_STRING}/
RUN cp KeYmaeraX-projects/benchmarks/*.kyx /${USER_NAME}/kyx${KYX_VERSION_STRING}/

# # Set final working directory
WORKDIR /${USER_NAME}/
