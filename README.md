# RStudio Server For Use in JupyterHub Single-User Mode

Based on the [rocker/geospatial](https://hub.docker.com/r/rocker/geospatial)
image.

## How to use this repo

This repo solves a very specific issue: the generation of a suitable rocker image
for use as a singleuser spawn in a JupyterHub environment, with:
* preinstalled Quarto plus all necessary tex (CTAN) packages
* preinstalled tidyverse, learnr, gradethis
* appropriately configured users so that the persistent storage from JupyterHub mounts properly and files are available (and saved) for users

This requires an up-to-date version of RStudio Server, and some finesse. 

### NOTE

There is a dirty, dirty hack in this image: getting a specific singleuser KubeSpawner to mount the home directory at /home/rstudio was beyond me. I tried a bunch of variations in the yml for Helm, and jupyterhub-on-k8s, and nothing seemed to want to work. So, the built-in **rstudio** user from the rocker images got its /etc/passwd modified, and a new home directory was specified at /home/jovyan, with appropriate **chown** applied. And it works. So if it's crazy, and it works, it's not crazy. 

This image is on dockerhub as wesleyburr/trent-rstudio, with the latest version as of this commit of 20230826.


