#!/usr/bin/env bash

  # detect sudo:
  sudo echo test 2>/dev/null && SUDO=sudo
  
  # detect installer:
  INSTALL=
  $SUDO apt-get update 2>/dev/null 1>/dev/null && INSTALL="$SUDO apt-get install -y"
  [ "$INSTALL" == "" ] && $SUDO yum --version 2>/dev/null 1>/dev/null && INSTALL="$SUDO yum install -y"
  [ "$INSTALL" == "" ] && $SUDO apk update 2>/dev/null 1>/dev/null && INSTALL="$SUDO apk add" 2>/dev/null
  [ "$INSTALL" == "" ] && echo "No installer found! Exiting..."

  # returning 0 or 1:
  [ "$INSTALL" != "" ]
  
  
