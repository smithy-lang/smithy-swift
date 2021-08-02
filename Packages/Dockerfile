FROM swift:5.4-focal

WORKDIR /package

COPY . ./

# to test on al2 swift images uncomment this and comment out other line.
# RUN yum -y install openssl-devel
RUN apt-get update -qq
RUN apt-get -y install libssl-dev

RUN swift package clean

RUN swift build

CMD ["swift", "test", "-Xcc", "-g"]
