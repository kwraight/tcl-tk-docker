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

- _it_: run interactively (booting with _sh_ commandline)
- _p_: map ports
- _e_: environment variable
- _v_: volume mapping

#### Tests 

A couple of checks display mapping works in container.

If things don't work, check [below](#display-issues).

__xclock__

Once in container run (from any directory):

> xclock

- should see clock pop-up

__TkPool__

Using example script from [CloudTk](#cloudtk-part).

In container /cloudtk directory:

- run Cloudkt to unpack files

    > ./tclkit CloudTk.kit

- close application (crtl+C)

- run Tkinter pool code

    > tclsh Tk/TkPool/TkPool.tcl


### Display Issues

__Debugs__

- check /tmp/.X11-unix exists on host system - else, you can't mount it into the container

- make sure forwarding not forbidden on host system

    > xhost +Local:*

    > xhost

## CloudTk part

Based on [here](https://cloudtk.tcl-lang.org/CloudTkFAQ.tml#Q2.1)

Running in /cloudtk directory of container:

> ./tclkit CloudTk.kit

You should see some lines including (container) port and debug password.

 - more info [here](https://cloudtk.tcl-lang.org/CloudTkFAQ.tml#Q3.1)

In a browser navigate to the mapped port of the host system

 - e.g. (for example above) localhost:8015

Here you should see the CloudTk webapp front page.

To see available tkinter scripts got to cloud tk page

 - e.g. localhost:8015/cloudtk

 - a pop-up should appear with fields for user and password. Use _webmaster_ for both

    - this can be changed using the _Access Control_ settings from the next page

You should see a list of available scripts which are (dynamically) compiled from container's /cloudtk/Tk directory.

To run a script, click on the script radio button and then _submit_ button.

The CloudTk webapp should then take you to a new page with the running app.

### Issues

If there is an issue the webapp will take you to the _debug_ page.

To view the debug output click the _See the error info_ button.

- a pop-up should appear with fields for user and password. Input _debug_ as user and the password (no quotations) from the terminal.

You should now have access to the error output.

