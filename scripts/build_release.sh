#!/usr/bin/env bash
docker run -v $(pwd):/opt/build --rm -it fusion:latest /opt/build/bin/build

