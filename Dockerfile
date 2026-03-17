FROM jenkins/jenkins:lts

USER root

# Install docker + curl
RUN groupadd -f -g 999 docker \
 && usermod -aG docker jenkins \
 && apt-get update \
 && apt-get install -y docker.io curl \
 && rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
 && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

USER jenkins
