FROM ubuntu:16.04

RUN apt-get update -y && apt-get install -y git curl unzip software-properties-common python jq unzip

RUN add-apt-repository -y ppa:webupd8team/java && apt-get update -y

RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
RUN apt-get install -y oracle-java8-installer && apt-get install -y oracle-java8-set-default

RUN curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" && \
    unzip awscli-bundle.zip && \
    ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws && \
    rm awscli-bundle.zip && rm -rf awscli-bundle

RUN git clone https://github.com/kamatama41/tfenv.git ~/.tfenv && ln -s ~/.tfenv/bin/* /usr/local/bin

RUN tfenv install 0.10.8 && tfenv use 0.10.8

RUN curl -o packer.zip https://releases.hashicorp.com/packer/1.1.3/packer_1.1.3_linux_amd64.zip && \
    unzip packer.zip && \
    mv packer /usr/bin && \
    rm packer.zip && \
    packer --version

WORKDIR /terraform

CMD ["bash", "-c", "./create_all.sh"]
