# My Web Server in Assembly (AMD64)

## Description

This project is a simple web server written in assembly language for AMD64 architecture.

## References

- [assembly64.pdf](http://www.egr.unlv.edu/%7Eed/assembly64.pdf)

## Features

- Handles HTTP GET requests
- Serve static files from the `www` directory
- Configurable port number, bind address, and root directory via assemblywebserver.conf

## Requirements

- NASM (Netwide Assembler)
- GCC (GNU Compiler Collection)
- Make

## Installation

```sh
sudo apt-get install nasm gcc
```

## Building the Project

To build the project, run:

```sh
make
```

## Running the Server

After building the project, run the server with:

```sh
./server
```

## File Structure

- `src/assemblywebserver.asm`: Main server code
- `Makefile`: Build configuration

## License

This project is licensed under the MIT License.
