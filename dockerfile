FROM ubuntu:24.04

# Install dependencies
RUN apt update && apt install -y \
    ansible \
    python3-pymysql \
    git \
    ssh \
    curl \
    unzip \
    sudo \
    && apt clean

# Copy repo contents
COPY . /app
WORKDIR /app

# Run the deployment script
CMD ["bash", "./deploy.sh"]
