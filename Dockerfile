# Multi-stage build for Spring Boot application with Java 21
# Stage 1: Build stage
FROM maven:3.9-eclipse-temurin-21 AS builder

WORKDIR /app

# Copy pom.xml and download dependencies (layer caching for faster builds)
COPY pom.xml ./
RUN mvn dependency:resolve

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests

# Stage 2: Runtime stage
FROM eclipse-temurin:21-jre

WORKDIR /app

# Create a non-root user for security best practices
RUN useradd -m -u 1000 appuser

# Copy built JAR from builder stage
COPY --from=builder /app/target/demo-0.0.1-SNAPSHOT.jar app.jar

# Set ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose default Spring Boot port
EXPOSE 8080

# Health check (optional)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# Run the Spring Boot application
ENTRYPOINT ["java", "-Dserver.port=8080", "-jar", "app.jar"]
