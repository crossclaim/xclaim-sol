#!/bin/bash

# Start ganache on default port (separate terminal & thread)
x-terminal-emulator -e ganache-cli 

# Compile contracts
truffle compile
# deploy on development network 
truffle migrate --network development


