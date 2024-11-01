# Taller Spring con Virtualización en AWS

Para la implementación de este proyecto debe contar con los siquientes requesitos mínimos:

* JDK >= 17
* Conocimientos de Java
* Maven 3.9 instalado
* Docker Desktop instalado
* Tener cuenta AWS profesional o académica

## Lo que haremos será:
* Crearemos una aplicación web mínima usando Spring Framework.
* Alistaremos la aplicacion para ejecutarla en un microcontenedor (Docker).
* Crearemos una imagen Docker y la ejecutaremos en la máquina local.
* Subiremos la imagen a Docker Hub.
* Por último crearemos una máquina en AWS, instalaremos Docker y ejecutremos nuestra aplicación desde AWS.

## Empezemos :)
Empezaré adjuntando el código para una vista rápida. 

```java
@RestController
public class HelloRestController {
    private static final String template = "Hello, %s!";
    @GetMapping("/greeting")
    public String greeting(@RequestParam(value = "name", defaultValue = "World") String name) {
        return String.format(template, name);
    }
}
```
### Ahora una breve explicación.

Empezamos creando la aplicación mínima `HelloRestController` que define el controlador con una ruta HTTP específica (en este caso, `/greeting`) que responde con un saludo. Le pasamos un atributo, que en nuestro caso hemos `#Template` que define el formato del mensaje que se devolverá, en este caso, "`Hello, %s!`", donde `%s` es un marcador de posición para insertar el nombre del usuario.

Luego utilizaremos el método `@GetMapping("/greeting")` que responderá a solicitudes GET. Asignamos un parámetro `@RequestParam` que permita obtener el valor del parámetro `#name` de la URL. Si no se proporciona, tomará el valor por defecto `"World"`.

El método `return String.format(template, name)` formatea el saludo usando `String.format()` e inserta el valor de name en el marcador `%s` de `template`. Por ejemplo, si se llama con `/greeting?name=John`, devolverá `"Hello, John!"`; si no se proporciona un nombre, devolverá `"Hello, World!"`.

## Continuamos?

Bueno, está bien! Ahora crearemos una clase principal para arrancar una aplicación Spring.

```java
@SpringBootApplication
public class RestServiceApplication {
    public static void main(String[] args) {
        SpringApplication app = new SpringApplication(RestServiceApplication.class);
        app.setDefaultProperties(Collections.singletonMap("server.port", getPort()));
        app.run(args);
    }
    private static int getPort() {
        if (System.getenv("PORT") != null) {
            return Integer.parseInt(System.getenv("PORT"));
        }
        return 33025;
    }
}
```
### Tranquilos! También hay una breve explicación.

* `@SpringBootApplication` Es una anotación que marca la clase como la principal para arrancar una aplicación Spring Boot.
* `RestServiceApplication` Define la aplicación principal. En Spring Boot, la clase con el método `main` es el punto de entrada que inicializa el contexto de la aplicación.
* `SpringApplication app = new SpringApplication(RestServiceApplication.class);` crea una instancia de `SpringApplication`, que administra el ciclo de vida de la aplicación.
*  `app.setDefaultProperties(Collections.singletonMap("server.port", getPort()));` configura el puerto del servidor usando un mapa de propiedades. Llama al método `getPort()` para determinar el puerto.
*  `app.run(args);` Inicia la aplicación Spring Boot.
*  `getPort` verifica si hay una variable de entorno llamada PORT. Si existe, la usa como puerto de la aplicación (convirtiéndola a un valor entero).
*  Si la variable `PORT` no está definida, se establece el puerto predeterminado `33025`.

Este código permite que la aplicación Spring Boot se ejecute en un puerto configurable, en este ejemplo hemos asigando el puerto 33025.

**Importante**
* Importe las dependencias de Spring en el archivo `pom.xml`.
  ```
  <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
            <version>3.3.3</version>
        </dependency>
    </dependencies>
  ```

* Y asegúrese que el proyecto esté compilando hacia la versión 17 de Java o mayor, igual en el archivo `pom.xml`.
    ```
    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <maven.compiler.source>23</maven.compiler.source>
        <maven.compiler.target>23</maven.compiler.target>
        <exec.mainClass>com.mycompany.docker1.Docker1</exec.mainClass>
    </properties>
    ```

* Aseguree tambien que el proyecto este copiando las dependencias en el directorio target al compilar el proyecto. Esto es necesario para poder construir una imagen de contenedor de docker usando los archivos ya compilados de java. Para hacer esto use el plugin de dependencias de Maven.
    ```
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-dependency-plugin</artifactId>
                <version>3.0.1</version>
                <executions>
                    <execution>
                        <id>copy-dependencies</id>
                        <phase>package</phase>
                        <goals><goal>copy-dependencies</goal></goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
    ```
**Recuerden instalar Maven**

Lo pueden hacer con el comando `mvn clean install`. 

Posterior a eso ejecutamos nuestro proyecto en la máquina virtual de Java, para eso lo hacemos con la siguiente linea de código `java -cp "target/classes:target/dependency/*" com.mycompany.docker1.RestServiceApplication`.

**Nota:** En la línea antes indica pueden observar la separación se hace con `:` esto se debe a que en Linux y Mac se separa así, en Windows se separa con `;`.

<img width="1291" alt="Captura de pantalla 2024-11-01 a la(s) 12 36 41 p m" src="https://github.com/user-attachments/assets/0c0b5d6f-8102-4be0-9319-17ad958ab019">

Como pueden ver en la imagen, el mensaje que nos muestra en la ruta `/greeting` es `Hello, World!`.

<img width="472" alt="Captura de pantalla 2024-11-01 a la(s) 11 49 32 a m" src="https://github.com/user-attachments/assets/67950cfb-c0b1-4033-ac33-1973e2232f8b">

Por el contrario si le decimos a la ruta `/greeting?name=Luis`, nos devolverá el mensaje `Hello, Luis!`.

<img width="656" alt="Captura de pantalla 2024-11-01 a la(s) 11 57 43 a m" src="https://github.com/user-attachments/assets/81de12c7-a09d-42a2-81fc-06ad4f723c41">

**Listo! De momento hemos concluido con la primera parte.**

# Ahora continuaremos creando una imágen en Docker para poder subirla.

En la raíz de nuestro proyecto vamos a crear una archivo Dockerfile con lo siguiente:

```java
FROM openjdk:23
WORKDIR /usrapp/bin
ENV PORT=33025
COPY /target/classes /usrapp/bin/classes
COPY /target/dependency /usrapp/bin/dependency
CMD ["java","-cp","./classes:./dependency/*","com.mycompany.docker1.RestServiceApplication"]
```
**Tranquilos, ya les explico.**

* `FROM openjdk:23` Especifica la imagen base para construir la imagen Docker.
* `WORKDIR /usrapp/bin` Establece el directorio de trabajo dentro de la imagen en /usrapp/bin.
* `ENV PORT=33025` Define una variable de entorno PORT con el valor 33025.
* `COPY /target/classes /usrapp/bin/classes` Copia el contenido del directorio local /target/classes al directorio /usrapp/bin/classes dentro de la imagen.
* `COPY /target/dependency /usrapp/bin/dependency` Copia las dependencias externas (librerías) de la aplicación desde el directorio local /target/dependency al directorio /usrapp/bin/dependency dentro de la imagen.
* `CMD ["java","-cp","./classes:./dependency/*","com.mycompany.docker1.RestServiceApplication"]` Define el comando para ejecutar la aplicación Java cuando se inicia el contenedor.








