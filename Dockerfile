# Build stage
ARG GH_VERSION=8.0
FROM maven:3.9.5-eclipse-temurin-21 as build

WORKDIR /graphhopper

# Build application
COPY src ./src
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:17-jre-jammy

# Security: Create application user
# Configuration
ENV JAVA_OPTS="-Xmx1g -Xms1g"
ENV CONFIG_FILE="/config/config.yml"
VOLUME /data
WORKDIR /app

# Copy artifacts
COPY --from=build /graphhopper/web/target/graphhopper-web-${GH_VERSION}.jar ./app.jar
COPY graphhopper.sh build.sh /app/

# Networking
EXPOSE 8989 8990

# Healthcheck with startup delay
HEALTHCHECK --interval=5s --timeout=3s --start-period=30s \
  CMD curl --fail http://localhost:8989/health || exit 1

# Runtime configuration
ENTRYPOINT [ "/app/graphhopper.sh", "-c", "${CONFIG_FILE}" ]