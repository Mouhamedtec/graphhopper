# Build stage
ARG GH_VERSION=7.0
FROM maven:3.9.5-eclipse-temurin-21 as build

WORKDIR /graphhopper

# Cache dependencies first
COPY pom.xml .
RUN mvn dependency:go-offline

# Build application
COPY src ./src
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:17-jre-jammy

# Security: Create application user
RUN groupadd -g 1000 graphhopper && \
    useradd -r -u 1000 -g graphhopper graphhopper

# Configuration
ENV JAVA_OPTS="-Xmx1g -Xms1g"
ENV CONFIG_FILE="/config/config.yml"
VOLUME /data
WORKDIR /app

# Copy artifacts
COPY --from=build --chown=graphhopper:graphhopper /graphhopper/web/target/graphhopper-web-${GH_VERSION}.jar ./app.jar
COPY --chown=graphhopper:graphhopper graphhopper.sh build.sh /app/

# Permissions
RUN chmod +x /app/graphhopper.sh

# Networking
EXPOSE 8989 8990

# Healthcheck with startup delay
HEALTHCHECK --interval=5s --timeout=3s --start-period=30s \
  CMD curl --fail http://localhost:8989/health || exit 1

# Runtime configuration
USER graphhopper
ENTRYPOINT [ "/app/graphhopper.sh", "-c", "${CONFIG_FILE}" ]
