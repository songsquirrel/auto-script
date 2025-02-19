FROM alpine/java:b08-jdk
MAINTAINER  "song"

WORKDIR /app

ADD eureka-server-1.0-SNAPSHOT.jar /app.jar

# springboot配置加载可通过环境变量传入 SPRING_*, 加载优先级-命令行参数>环境变量>配置文件
CMD ["java", "-XX:UseContainerSupport", "-jar", "/app.jar"]