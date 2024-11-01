FROM openjdk:23
WORKDIR /usrapp/bin
ENV PORT=33025
COPY /target/classes /usrapp/bin/classes
COPY /target/dependency /usrapp/bin/dependency
CMD ["java","-cp","./classes:./dependency/*","com.mycompany.docker1.RestServiceApplication"]
