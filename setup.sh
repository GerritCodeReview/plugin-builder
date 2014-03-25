#!/bin/bash

# install git
apt-get install git-core

# install open-jdk
apt-get install openjdk-7-jdk

# Ant
apt-get install ant

# Maven
apt-get install maven

# Buck
mkdir pgm
cd pgm
git clone https://gerrit.googlesource.com/buck
cd buck
ant
mkdir ~/bin
ln -s `pwd`/bin/buck ~/bin/

