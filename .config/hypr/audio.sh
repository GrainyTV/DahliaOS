#!/bin/bash

pipewire &
sleep 1s

pipewire-pulse &
sleep 1s

wireplumber &
sleep 1s

easyeffects --gapplication-service &