FROM drewcrawford/swift:latest
RUN apt-get update && apt-get install   curl -y && curl -s https://packagecloud.io/install/repositories/anarchytools/AT/script.deb.sh | bash && apt-get install --no-install-recommends -y package-deb xz-utils
ADD . /atbuild
WORKDIR atbuild
RUN bootstrap/build.sh linux
RUN tests/test.sh