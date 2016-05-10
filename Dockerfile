FROM drewcrawford/swift:latest
RUN apt-get update && apt-get install --no-install-recommends xz-utils -y
ADD . /atbuild
WORKDIR atbuild
RUN bootstrap/build.sh linux
RUN tests/test.sh