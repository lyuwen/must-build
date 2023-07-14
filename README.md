# A source independent CMake build system for MuST


```bash
git clone <url-to-repo>/must-build && cd must-build
mkdir build && cd build
CC=mpiicc CXX=mpiicpc FC=mpiifort cmake .. -DSOURCE_DIR=path-to-MuST-repo/MST
```
