FROM node:20-alpine

RUN apk add --no-cache curl unzip git bash python3 py3-pip openssh-client && \
    pip3 install --no-cache-dir awscli --break-system-packages && \
    curl -fsSL https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip -o terraform.zip && \
    unzip terraform.zip && mv terraform /usr/local/bin/ && rm terraform.zip && \
    curl -fsSL https://github.com/cli/cli/releases/download/v2.40.1/gh_2.40.1_linux_amd64.tar.gz -o gh.tar.gz && \
    tar -xzf gh.tar.gz && mv gh_2.40.1_linux_amd64/bin/gh /usr/local/bin/ && rm -rf gh.tar.gz gh_2.40.1_linux_amd64 && \
    curl -LO https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl && \
    chmod +x kubectl && mv kubectl /usr/local/bin/

WORKDIR /mcp

COPY package.json .
RUN npm install

COPY mcp-server.js .

CMD ["node", "mcp-server.js"]
