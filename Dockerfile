FROM drewcrawford/swift:latest
RUN apt-get update && apt-get install libbsd-dev libicu-dev --no-install-recommends -y
ADD . /atbuild
WORKDIR atbuild
RUN bootstrap/build.sh linux
RUN tests/test.sh