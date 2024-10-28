#!/usr/bin/env bash
docker run -v $(pwd):/opt/build --rm -it suma:latest /opt/build/bin/build

