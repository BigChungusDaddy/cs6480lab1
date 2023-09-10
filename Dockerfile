FROM ubuntu:20.04
RUN apt-get update 
RUN apt-get install -y iputils-ping
RUN apt-get install -y tcpdump
RUN apt-get install -y net-tools
RUN apt-get install -y quagga
RUN apt-get install -y nano
RUN apt-get install -y systemctl
CMD ["/bin/bash"]