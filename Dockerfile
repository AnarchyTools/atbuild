FROM drewcrawford/swift:latest
ADD . /atbuild
WORKDIR atbuild
RUN bootstrap/build.sh linux
RUN tests/test.sh