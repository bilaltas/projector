# Projector
Wordpress development environment with Docker. Starter template is being developed with Flexible Grid System. (Only tested on MacOS)
<br><br>

## Why Projector
* Docker based environment
* Faster development starter
* No need to deal with etc/hosts file
* Works with the IP over 127.0.0.2+


## Installation
Install the builder in an appropriate folder that you don't usually see, with the code below:
```bash
git clone https://github.com/bilaltas/projector.git && cd projector && sudo bash install.sh
```


## Usage
Write "**projector**" command in terminal where your "Projects" folder is located to see available actions:
```bash
projector
```


## Todo
* Reduce the need of permission fix after clonning and pulling
* Detect conflicts when pulling
* Add ability to revert to any commit with DB
* Add ability to work with branches
* Better DB change handling