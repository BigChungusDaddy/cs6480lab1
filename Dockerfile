FROM ubuntu
RUN apt-get update && apt-get install -y iputils-ping && apt-get install -y tcpdump && apt-get install -y net-tools
CMD ["/bin/bash"]