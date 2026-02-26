# FROM 이전에 ARG 선언 필요, 빌드 이후 사용 못함
ARG JETPACK_VERSION=r36.4.0

FROM nvcr.io/nvidia/l4t-jetpack:r36.4.0

# Prevent interactive prompts during build
ARG DEBIAN_FRONTEND=noninteractive

# ENV 는 컨테이너 내부에서 여전히 유효
ENV PATH="/usr/local/cuda/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Add NVIDIA Jetson public key
RUN curl -fsSL https://repo.download.nvidia.com/jetson/jetson-ota-public.asc | gpg --dearmor -o /usr/share/keyrings/nvidia-jetson-keyring.gpg

# Setup source lists
RUN echo "deb [signed-by=/usr/share/keyrings/nvidia-jetson-keyring.gpg] https://repo.download.nvidia.com/jetson/common r36.4 main" > /etc/apt/sources.list.d/nvidia-l4t-apt-source.list && \
    echo "deb [signed-by=/usr/share/keyrings/nvidia-jetson-keyring.gpg] https://repo.download.nvidia.com/jetson/t234 r36.4 main" >> /etc/apt/sources.list.d/nvidia-l4t-apt-source.list

# Install System Dependencies
# specific libraries are combined into one block
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    libopenblas-base \
    libopenmpi-dev \
    libomp-dev \
    libjpeg-dev \
    zlib1g-dev \
    libpython3-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    python3-opencv \
    && rm -rf /var/lib/apt/lists/*

# Install PyTorch and Torchvision
# (URLs kept as provided, assuming they are correct for your specific JetPack version)
RUN pip install --no-cache-dir https://pypi.jetson-ai-lab.io/jp6/cu126/+f/02f/de421eabbf626/torch-2.9.1-cp310-cp310-linux_aarch64.whl#sha256=02fde421eabbf62633092de30405ea4d917323c55bea22bfd10dfeb1f1023506 \
    https://pypi.jetson-ai-lab.io/jp6/cu126/+f/d5b/caaf709f11750/torchvision-0.24.1-cp310-cp310-linux_aarch64.whl#sha256=d5bcaaf709f11750b5bb0f6ec30f37605da2f3d5cb3cd2b0fe5fac2850e08642

# Install CUDSS
# Checks file, installs, and then deletes the .deb to save space
RUN wget https://developer.download.nvidia.com/compute/cudss/0.7.1/local_installers/cudss-local-tegra-repo-ubuntu2204-0.7.1_0.7.1-1_arm64.deb && \
    dpkg -i cudss-local-tegra-repo-ubuntu2204-0.7.1_0.7.1-1_arm64.deb && \
    cp /var/cudss-local-tegra-repo-ubuntu2204-0.7.1/cudss-*-keyring.gpg /usr/share/keyrings/ && \
    apt-get update && \
    apt-get -y install cudss && \
    rm cudss-local-tegra-repo-ubuntu2204-0.7.1_0.7.1-1_arm64.deb && \
    rm -rf /var/lib/apt/lists/*


EXPOSE 8888
LABEL maintainer="basamg@allai.com"
LABEL description="Environment for Training and Inference Network for Jetson"
LABEL version="L4T_36.4.4_CUDA_12.6"

# 컨테이너 진입시 실행할 명령어
ENTRYPOINT ["/bin/bash"]
VOLUME ["/workspace"]
# Create user 'allai'
RUN useradd -ms /bin/bash allai

# Set permissions for workspace (if it exists or will be mounted)
RUN mkdir -p /workspace && chown -R allai:allai /workspace

USER allai
WORKDIR /workspace

