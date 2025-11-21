FROM eclipse-temurin:17-jdk
WORKDIR /app
# 주의: 이 파일은 Maven 빌드 후 생성되는 JAR 파일명과 일치해야 합니다.
COPY target/spring-boot-json-logging-1.0.0.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","app.jar"]
