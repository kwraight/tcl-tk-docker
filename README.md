# tcl-tk-docker

repo for setting up remote tkinter thing

__Pre-requisites__

You gotta have:

- docker
- some display packages (check Dockerfile for list)

## Instructions

Build and run with docker

### Build Image

> docker build -f dockerFiles/Dockerfile -t tk-app .

### Run Container

Container will run and display tkinter stuff provided some mappings are used.

Run container:

> docker run -it -p 8015:8015 -e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix:ro tk-app sh

notes:

- _it_: run interactively
- _p_: map ports
- _e_: environment variable
- _v_: volume mapping

#### Tests 

A couple of checks display mapping works in container:

__xclock__

Once in container run (from any directory):

> xclock

- should see clock pop-up

__TkPool__

In container /cloudtk directory:

- run Cloudkt to unpack files

 > ./tclkit CloudTk.kit

- close application (crtl+C)

- run Tkinter pool code

 > tclsh Tk/TkPool/TkPool.tcl


### display issue

Debugs:

- check /tmp/.X11-unix exists on host system - else, you can't mount it into the container
- 
