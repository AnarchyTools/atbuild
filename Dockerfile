FROM drewcrawford/buildbase:latest
RUN apt-get update && apt-get install package-deb libcurl4-openssl-dev
ADD . /atbuild
WORKDIR atbuild
RUN bootstrap/build.sh linux
RUN tests/test.sh