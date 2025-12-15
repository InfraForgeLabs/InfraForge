#!/bin/bash
# Common helper utilities for all modules
pause() { read -e -p "Press Enter to continue..." ; }
confirm() { read -e -p "Are you sure? (y/N): " ans; [[ "$ans" == [yY]* ]]; }
