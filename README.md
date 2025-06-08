# GraphHopper Docker Provider

This repository provides a simple yet essential setup for building and maintaining an up-to-date [GraphHopper](https://www.graphhopper.com/) Docker image, used in our production environment.

📦 Docker images are published here:
➡️ https://hub.docker.com/r/mouhamedtec/graphhopper

## 🙏 Acknowledgements
We would like to express our sincere gratitude to the [GraphHopper](https://www.graphhopper.com/) team for their incredible work. Their routing engine is outstanding, and we're proud to have contributed to their codebase in the past.

Since the [GraphHopper](https://www.graphhopper.com/) team does not provide an official Docker image, this repository serves to fill that gap.


## 🔧 What This Repository Does
This repository is intentionally minimal. It performs the following:

1. Nightly Build at 1 AM (UTC):
Automatically pulls the latest code from the GraphHopper repository, builds the Docker image, and pushes it to Docker Hub with the latest tag.

Version Tagging:
If a new release tag is detected, it builds and pushes a versioned image accordingly.

## 📥 Configuration
The Docker image supports the following environment variables:
```yaml
CONFIG_FILE: "/app/config.yml"  # Path to the GraphHopper config file
JAVA_OPTS: "-Xmx1g -Xms1g"      # JVM options for memory allocation
GRAPHHOPPER_CACHE: "/data/gh"   # Default path for graph cache storage
```

## Security Features
- Runs as a non-root user (graphhopper, UID 1000)
- Automatic cleanup of temporary files
- Health checks using startup probes
- Version-pinned dependencies for security and stability

## 🚀 Quick Start
To quickly get started:
```bash
docker run -d \
  -p 8989:8989 \
  -v ./gh-data:/data \
  -v ./config.yml:/app/config.yml \
  mouhamedtec/graphhopper:latest \
  --config /app/config.yml \
  --graph-cache /data/gh-cache
```
Then open `http://localhost:8989/` in your browser.

## 🛠️ Development with Docker Compose
```yaml
version: '3.8'
services:
  graphhopper:
    image: mouhamedtec/graphhopper:latest
    ports:
      - "8989:8989"
    volumes:
      - ./data:/data
      - ./config.yml:/app/config.yml
    environment:
      - JAVA_OPTS=-Xmx2g -Xms2g
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8989/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## 🏗️ Building Specific Versions
To build a Docker image for a specific version of GraphHopper:
```bash
./build.sh --build-arg GH_VERSION=8.0
```

Check out the graphhopper.sh script for additional commands like importing data.

To build the Docker image locally:
```bash
./build.sh
```

## 🤝 Contributing
We welcome issues and pull requests! If you’d like to improve or extend the functionality, feel free to contribute.