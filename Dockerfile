FROM openjdk:11 as builder
WORKDIR /app
COPY . .
RUN chmod +x ./gradlew
RUN ./gradlew build 


FROM tomcat:9.0.62-jdk16-temurin-focal
WORKDIR webapps
COPY --from=builder /app/build/libs/sampleWeb-0.0.1-SNAPSHOT.war .
RUN rm -rf ROOT && mv sampleWeb-0.0.1-SNAPSHOT.war java-app.war
