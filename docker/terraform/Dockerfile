FROM ubuntu:16.04

RUN apt-get update -y && apt-get install -y git curl unzip software-properties-common python jq openvpn

RUN add-apt-repository -y ppa:webupd8team/java && apt-get update -y

RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
RUN apt-get install -y oracle-java8-installer && apt-get install -y oracle-java8-set-default

RUN curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" && \
    unzip awscli-bundle.zip && \
    ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws && \
    rm awscli-bundle.zip && rm -rf awscli-bundle

RUN curl -o terraform.zip https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip && \
    unzip terraform.zip && \
    mv terraform /usr/bin && \
    rm terraform.zip && \
    terraform --version

RUN curl -o packer.zip https://releases.hashicorp.com/packer/1.2.5/packer_1.2.5_linux_amd64.zip && \
    unzip packer.zip && \
    mv packer /usr/bin && \
    rm packer.zip && \
    packer --version

RUN curl -o consul.zip https://releases.hashicorp.com/consul/1.2.2/consul_1.2.2_linux_amd64.zip && \
    unzip consul.zip && \
    mv consul /usr/bin && \
    rm consul.zip && \
    consul --version

WORKDIR /infrastructure
