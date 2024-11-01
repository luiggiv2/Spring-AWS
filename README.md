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
Tranquilos, ya les explico.

* `FROM openjdk:23` Especifica la imagen base para construir la imagen Docker.
* `WORKDIR /usrapp/bin` Establece el directorio de trabajo dentro de la imagen en /usrapp/bin.
* `ENV PORT=33025` Define una variable de entorno PORT con el valor 33025.
* `COPY /target/classes /usrapp/bin/classes` Copia el contenido del directorio local /target/classes al directorio /usrapp/bin/classes dentro de la imagen.
* `COPY /target/dependency /usrapp/bin/dependency` Copia las dependencias externas (librerías) de la aplicación desde el directorio local /target/dependency al directorio /usrapp/bin/dependency dentro de la imagen.
* `CMD ["java","-cp","./classes:./dependency/*","com.mycompany.docker1.RestServiceApplication"]` Define el comando para ejecutar la aplicación Java cuando se inicia el contenedor.

Luego procederemos a crear la imagen en docker usando la herramienta de líneas de comando.
```
docker build --platform linux/amd64 -t taller1 .
```
Revisamos que la imagen haya sido creada con `docker images`, y debería verse algo así:

```
REPOSITORY               TAG       IMAGE ID       CREATED       SIZE
taller1                  latest    329a6fc1459e   4 hours ago   932MB
```
A partir de la imagen creada, hemos creado tres instancias de un contenedor docker. Ejecutando un contenedor en segundo plano `-d` con el nombre `springinstance1` expone el puerto `33025` dentro del contenedor al puerto `42000` en la máquina host.

```
docker run -d -p 42000:33025 --name springinstance1 taller1
docker run -d -p 42001:33025 --name springinstance2 taller1
docker run -d -p 42002:33025 --name springinstance3 taller1
```

Nos aseguramos que se encuentren ejecutando con el comando `docker ps`, y debería verse algo así:
```
CONTAINER ID   IMAGE     COMMAND                  CREATED       STATUS       PORTS                      NAMES
8aa9d1c0bbe8   taller1   "java -cp ./classes:…"   2 hours ago   Up 2 hours   0.0.0.0:42002->33025/tcp   springinstance3
47f28fa20352   taller1   "java -cp ./classes:…"   2 hours ago   Up 2 hours   0.0.0.0:42001->33025/tcp   springinstance2
cb0fc7a67f52   taller1   "java -cp ./classes:…"   2 hours ago   Up 2 hours   0.0.0.0:42000->33025/tcp   springinstance1
```

Si verificamos en nuesro Docker Desktop, veremos algo así:
<img width="1122" alt="Captura de pantalla 2024-11-01 a la(s) 4 59 21 p m" src="https://github.com/user-attachments/assets/c6d2c2c3-3f78-4430-a230-484d33f2802a">

<img width="1121" alt="Captura de pantalla 2024-11-01 a la(s) 5 01 17 p m" src="https://github.com/user-attachments/assets/9ae2c4c3-9073-4535-a1d6-f1980d17a40e">

Si accedemos al navegador con `http://localhost:42000/greeting`, `http://localhost:42001/greeting` y `http://localhost:42002/greeting`; podremos verificar que se encuentran ejecutandose. Veremos aslgo así:

<img width="519" alt="Captura de pantalla 2024-11-01 a la(s) 5 05 30 p m" src="https://github.com/user-attachments/assets/1c5f0ddf-4af7-414d-9d11-be7b7fde54b5">

# Ahora subiremos la imagen a Docker Hub

* Previamente ya debemos contar con una cuenta creada, sino la tienes es momento de hacerlo.
* Accederemos al menú de `Repositorios` y crearemos uno.
* En nuestro docker local crearemos una referencia a la imagen con el nombre del repositorio que creamos anteriormente.
  ```docker tag taller1 luiggiv2/taller1spring```
* Verificamos que la referencia de la imagen fue creada con `docker images`.
* Nos autenticacion con nuestra cuenta de docker hub (usuario/contraseña)
  ```docker login```
* Por último procederemos a empujar la imagen al repositorio de docker hub.
  ```docker push luiggiv2/taller1spring:latest```

Si todo salió correcto, podremos ver algo así:
<img width="723" alt="Captura de pantalla 2024-11-01 a la(s) 5 20 36 p m" src="https://github.com/user-attachments/assets/4d708281-ba97-4308-974f-ca8479badee8">

# Por último accederemos a nuestra cuenta AWS Academy

* Instalaremos docker. Primero `sudo yum update -y` seguido de `sudo yum install docker`.
* Iniciamos el servicio con `sudo service docker start`.
* Configuramos nuestro usuario `sudo usermod -a -G docker ec2-user` para no tener que indicar `sudo` cada vez que se invoca un comando.
* Cerramos la conexión y volvemos a iniciar sesión para que la configuración de usuarios surta efecto.
* A partir de la imagen creada en Docker Hub, creamos una instancia de un contenedor.
  ```
  docker run -d -p 42000:33025 --name awstaller1 luiggiv2/taller1spring
  ```
* Realizamos la configuración de apertura de entrada del grupo de seguridad en nuestra máquina virtual para poder acceder al servicio por el puerto 42000 que hemos asignado.  

<img width="1122" alt="Captura de pantalla 2024-11-01 a la(s) 5 29 28 p m" src="https://github.com/user-attachments/assets/57dd9395-5d6f-4c9a-bdca-a82ffc31cbb9">

* Por último accedemos al DNS público de nuestra máquina virtual para poder ejecutar nuestra pequeña aplicación Spring que realizamos.
  
<img width="387" alt="Captura de pantalla 2024-11-01 a la(s) 5 32 09 p m" src="https://github.com/user-attachments/assets/eca094e4-2b6f-4b72-b7d1-6ee74bee2c1d">

* Si accedemos a nuestro DNS público con el puerto que hemos confiurado en nuestro caso el `42000` y con la ruta que especificamos en nuestra aplicación `/greeting`. Deberíamos ver algo así con nuestra aplicación ejecutandose desde una máquina virtual de AWS.

<img width="864" alt="Captura de pantalla 2024-11-01 a la(s) 5 34 00 p m" src="https://github.com/user-attachments/assets/6eb3bf14-73e9-4607-83f5-b6ee40772812">



**Muchas gracias**



