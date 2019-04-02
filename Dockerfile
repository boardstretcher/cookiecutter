FROM centos:centos7
MAINTAINER boardstretcher version: 42.0

WORKDIR /container/directory/

ADD https://localhost/some/remote/file.tar.gz /container/directory/file.tar.gz

RUN \
	echo Hello \
	echo World

COPY localfile /container/directory/

ENV \
	VARIABLE1=foo \
	VARIABLE2=bar 

EXPOSE 80 443

CMD ["/usr/bin/echo"]
