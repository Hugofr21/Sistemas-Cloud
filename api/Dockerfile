FROM gradle:7.3.3-jdk17 as build

WORKDIR /home/gradle/project

COPY --chown=gradle:gradle . .
RUN chmod +x ./gradlew

RUN ./gradlew build --no-daemon

FROM openjdk:17-jdk-slim

WORKDIR /app

COPY --from=build /home/gradle/project/build/libs/*.jar /app/app.jar
COPY videos /app/videos

ENTRYPOINT ["java", "-jar", "/app/app.jar"]

