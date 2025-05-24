# ARG MATLAB_VERSION=r2024b

#FROM mathworks/matlab-deps:${MATLAB_VERSION}
#FROM mathworks/matlab:${MATLAB_VERSION}
FROM ubuntu:24.04

#ARG SCALA_VERSION=2.13.13
ARG SBT_VERSION=1.3.7
ARG KYX_VERSION_STRING=5
ARG ARCH_YEAR=arch2022
ARG WOLFRAM_ENGINE_PATH=/usr/local/Wolfram/WolframEngine
ARG DEBIAN_FRONTEND=noninteractive
ARG USER_NAME
ENV TZ=America/New_York

# repeat MATLAB_VERSION, otherwise it's not available in Matlab install below
# ARG MATLAB_VERSION

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
  #    libgl1-mesa-glx \
  #    libasound2 \
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


# Install MATLAB
# RUN wget https://www.mathworks.com/mpm/glnxa64/mpm && \
#     chmod +x mpm && \
#     sudo ./mpm install \
#         --release=${MATLAB_VERSION} \
#         --destination=/opt/matlab \
#         --products=MATLAB && \
#     sudo rm -f mpm /tmp/mathworks_root.log && \
#     sudo ln -s /opt/matlab/bin/matlab /usr/local/bin/matlab

# Activate MATLAB
# ARG LICENSE_FILE
# COPY ${LICENSE_FILE} /opt/matlab/licenses/

# Install MATLAB package manager
# RUN wget https://github.com/mobeets/mpm/archive/refs/tags/v3.1.0.zip && \
#   unzip v3.1.0.zip

# Download sostools
# RUN wget https://github.com/oxfordcontrol/SOSTOOLS/archive/refs/tags/v4.01.zip && \
#   unzip v4.01.zip

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
# RUN wget -O wolframengine "https://account.wolfram.com/dl/WolframEngine?version=14.2.1&platform=Linux&downloadManager=false&includesDocumentation=false" && \
#   sudo bash wolframengine -- -auto -verbose && \
#   rm wolframengine
# RUN wget -O wolframengine "https://account.wolfram.com/dl/WolframEngine?version=14.2.1&platform=Linux&downloadManager=false&includesDocumentation=false"
# RUN sudo bash wolframengine -- -auto -verbose -silent
# RUN sudo bash wolframengine -- -verbose 

# TODO: 5.1.1 Jar file and use Z3 instead.
# # Pull KeYmaera X
WORKDIR /${USER_NAME}/
# RUN wget "https://github.com/LS-Lab/KeYmaeraX-release/releases/download/5.1.1/keymaerax.jar"
COPY keymaerax-core-5.1.1.jar/ /${USER_NAME}keymaerax.jar
# RUN cp keymaerax-core/target/scala-2.13/keymaerax-core*.jar /${USER_NAME}/keymaerax.jar

# WORKDIR /${USER_NAME}/
# avoid caching git clone by adding the latest commit SHA to the container
# this worked somewhat better? 
# ADD https://api.github.com/repos/LS-Lab/KeYmaeraX-release/git/refs/heads/master kyx-version.json
# RUN git clone -n https://github.com/LS-Lab/KeYmaeraX-release.git --recurse-submodules

# # Build KeYmaera X at commit
# WORKDIR /${USER_NAME}/KeYmaeraX-release/
# RUN git checkout 5.1.1
# RUN ls ${WOLFRAM_ENGINE_PATH} > weversion.txt
# RUN bash -l -c "echo \"mathematica.jlink.path=${WOLFRAM_ENGINE_PATH}/"'$(<weversion.txt)/SystemFiles/Links/JLink/JLink.jar" > local.properties'
# RUN sbt --mem 2048 'project core' clean assembly
# RUN cp keymaerax-core/target/scala-2.13/keymaerax-core*.jar /${USER_NAME}/keymaerax.jar

# # Download and install MATLink
# # WORKDIR /${USER_NAME}/
# # RUN wget http://download.matlink.org/MATLink.zip && \
# #   mkdir -p .WolframEngine/Applications/ && \
# #   unzip MATLink.zip -d .WolframEngine/Applications/

# # Install MATLink dependencies
# # RUN sudo apt-get --yes update && \
# #   sudo apt-get --yes upgrade && \
# #   sudo apt-get --no-install-recommends --yes install \
# #     g++ \
# #     uuid-dev \
# #     csh && \
# #   sudo apt-get clean && \
# #   sudo apt-get autoremove && \
# #   sudo rm -rf /var/lib/apt/lists/*

# # Export Wolfram Engine version for dockersetup.sh and path for dockerrun.sh
# RUN ls ${WOLFRAM_ENGINE_PATH} > weversion.txt
# RUN bash -l -c "echo \"${WOLFRAM_ENGINE_PATH}/"'$(<weversion.txt)/Executables" > wepath.txt'

# # Import benchmark index and script
# Ensure this is correct
WORKDIR /${USER_NAME}
COPY index${KYX_VERSION_STRING}/ ./index${KYX_VERSION_STRING}/
ADD *.xml ./
ADD runKeYmaeraX${KYX_VERSION_STRING}Benchmarks ./

# # Pull KeYmaera X Projects
#  Ensure this is correct
WORKDIR /${USER_NAME}/
#  Ensure this is correct https://github.com/LS-Lab/KeYmaeraX-projects/releases/tag/arch2022
# RUN git clone --depth 1 https://github.com/LS-Lab/KeYmaeraX-projects.git

# TODO: 5/22/2025 Ensure this is correct
RUN git clone https://github.com/LS-Lab/KeYmaeraX-projects.git
RUN git checkout b9d7cb584e8fd1c3cc4f30644e82ba12cbb1d6fe


RUN mkdir -p /${USER_NAME}/kyx${KYX_VERSION_STRING}/
RUN cp KeYmaeraX-projects/benchmarks/*.kyx /${USER_NAME}/kyx${KYX_VERSION_STRING}/

# # Create symlink to WolframEngine math (needed by Mathlink make file)
# RUN bash -l -c "sudo ln -s "'$(<wepath.txt)/math /usr/local/bin/math'

# # Set final working directory
WORKDIR /${USER_NAME}/
