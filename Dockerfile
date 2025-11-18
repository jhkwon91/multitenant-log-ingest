FROM eclipse-temurin:17-jdk AS builder
WORKDIR /app

COPY target/multitenant-log-ingest-0.0.1-SNAPSHOT.jar app.jar

# 실제 애플리케이션 이미지
FROM eclipse-temurin:17-jre
WORKDIR /app

COPY --from=builder /app/app.jar app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]

