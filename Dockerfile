FROM nvidia/cuda:11.6.0-devel-ubuntu20.04 as base

# Assume repo for erin and hidet are cloned into ./erin and ./hidet 
COPY ./erin/ /opt/program/erin/
COPY ./hidet/ /opt/program/hidet

ENV TZ=America/Toronto
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    python3 \
    ccache \
    software-properties-common \
    python3-pip \
    git \
    nginx \
    apache2-dev \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --no-cache-dir -r /opt/program/hidet/requirements-dev.txt -r /opt/program/hidet/requirements.txt && \
    python3 -m pip install --no-cache-dir -r /opt/program/erin/requirements-dev.txt && \
    python3 -m pip install --no-cache-dir --upgrade cmake && \
    python3 -m pip install jupyter && \
    hash -r  # refresh the hash

RUN ln -s /usr/bin/python3 /usr/bin/python

RUN cd /opt/program/hidet && \
    bash scripts/wheel/build_wheel.sh && \
    WHEEL=$(find ./scripts/wheel/built_wheel/ -maxdepth 1 -name '*.whl') && \
    echo "Built wheel: $WHEEL" && \
    pip install --no-deps --force-reinstall $WHEEL

RUN cd /opt/program/erin && \
    bash scripts/build_wheel.sh && \
    WHEEL=$(find ./scripts/ -maxdepth 1 -name 'erin-*.whl') && \
    echo "Built wheel: $WHEEL" && \
    pip install --no-deps --force-reinstall $WHEEL && \
    WHEEL=$(find ./scripts/ -maxdepth 1 -name 'erin_server*.whl') && \
    echo "Built wheel: $WHEEL" && \
    pip install --no-deps --force-reinstall $WHEEL

ENV PYTHONUNBUFFERED=1
# Copy entrypoint script to the image
COPY workspace/ /opt/program/workspace
WORKDIR /opt/program/workspace

# # Define an entrypoint script for the docker image
ENTRYPOINT ["jupyter", "notebook"]
