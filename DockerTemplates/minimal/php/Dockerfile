# ---------- Build Stage ----------
FROM maven:3.9-eclipse-temurin-17 as builder
WORKDIR /build
COPY . .
RUN mvn clean package -DskipTests

# ---------- Runtime Stage ----------
FROM {{BASE_IMAGE}}
WORKDIR /app
COPY --from=builder /build/target/*.jar /app/app.jar
USER 1001
EXPOSE {{PORT}}

# ---------- Healthcheck ----------
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:{{PORT}}/ || exit 1

# ---------- Runtime Command ----------
CMD ["{{RUN_CMD}}"]
