# SimpleHTTPServer
a simple HTTP Server written in assmebly, this project is part of a module in pwncollege to learn assembly and syscalls in linux
this server takes GET, POST request and read, write from or to a file, for this it uses different syscalls like socket, bind, listen, write, accept ...

## to compile the project
```bash
as -o asm.o level14.s && ld -o server asm.o
```

## run the server
```bash
sudo ./server
```

## connect
### POST: write to a file
```bash
curl -X POST http://localhost/tmp/test -d "testkey=testValue"
```

verify if the data was written there
```bash
cat /tmp/test
```

### GET: read from a file
```bash
curl -X GET http://localhost/tmp/test
```
