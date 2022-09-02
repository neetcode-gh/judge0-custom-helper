# Judge0
> Edgar's extended version of Judge0.

This project automates importing additional libraries, languages, etc. along with Judge0.

## How do I use this?
The core of this project is the `build_image.sh` script. This script generates the required
Dockerfile based on the structure of the project and arguments provided. All of the arguments
have a default value, so it can be run as is.
It downloads a Judge0 release, prepares a Dockerfile and builds the Docker image.
To see the options provided by the script run `./build_image.sh -h`.

### The `build_image.sh` script
The script goes through each subdirectory of the project and gathers all of the `Dockerfile.ext` files in them. It concatenates all of the files along with the `Dockerfile.langs` file into a single Dockerfile ready for building.
The `Dockerfile.langs` file is responsible for injecting additional language dependencies into the Judge0 database, which are specified in JSON files in each of the subdirectories. How this works is described in the [Adding langugaes](#adding-languages) section.

#### Adding dependencies
Additional dependencies are specified in a `Dockerfile.ext` file. The file lists regular Docker commands which will be concatenated into a single Dockerfile. Must not contain a `FROM` directive.Example from the *nasp* subdirectory, where we require the **Eigen** library depndency:

```
ENV EIGEN_VERSION 3.3.8
RUN set -xe && \
    curl -fSsL "https://gitlab.com/libeigen/eigen/-/archive/$EIGEN_VERSION/eigen-$EIGEN_VERSION.zip" -o /tmp/eigen.zip && \
    unzip /tmp/eigen.zip -d /tmp && \
    mv /tmp/eigen-$EIGEN_VERSION/Eigen /usr/include && \
    rm -rf /tmp/*

```

#### Adding languages
A language can be added by adding a JSON file into a subdirectory of the project. The JSON files have to be a JSON lists
of objects which adhere to Judge0's database schema. The IDs of the languages are automatically generated starting from the last ID that comes with Judge0. This is to prevent bugs with new Judge0 releases which could have addtiional languages. An example of this can be found in the *oop/oop.json* file:

```JSON
[
  {
    name: "Java (OpenJDK 17.0.2)",
    is_archived: false,
    source_file: "Main.java",
    compile_cmd: "/usr/lib/jvm/jdk-17.0.2/bin/javac %s Main.java",
    run_cmd: "/usr/lib/jvm/jdk-17.0.2/bin/java Main"
  }
]
```
If we need additional specific libraries added, which have to be passed to the compiler you should
use the JSON and the `Dockerfile.ext` in tandem to both install the dependency and add
the compile command with a langugae specification to the Judge0 database.

#### Judge0 release handling
The script downloads the Judge0 release, but only copies and modifies their `docker-compose.yml` file,
the *judge0.conf* file is a part of this repository and is tailored to Edgar's needs.
If the *judge0.conf* file changes with a new release of Judge0 it should be updated manually.

## How do I update?
After the new Judge0 release you can run the `build_image.sh` script again with a different
argument for the Judge0 version. This should work for minor versions, but updates
to the project will probably be required on major releases and Judge0 project refactorings.

After the script builds your image. You need to push it to the GitLab Registry:
```
docker push registry.gitlab.com/edgar-group/judge0:X.Y.Z
```


---

Please note that in order for `docker push` to work you need to login to GitLab's Registry since not everyone are allowed to write to your repository registry. To do that you need to:
```
docker login registry.gitlab.com
```
