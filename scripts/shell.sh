#!/usr/bin/env sh
exec nix --extra-experimental-features "nix-command flakes" develop "$@"
