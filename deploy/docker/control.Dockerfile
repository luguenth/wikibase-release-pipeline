FROM alpine:latest

# set current working directory to /app
WORKDIR /app

# install bash, git
RUN apk add --update bash git

# copy install script
COPY scripts/install-git-extension.sh /app/install-git-extension.sh
COPY extensions.csv /app/extensions.csv

# set permissions
RUN chmod +x /app/install-git-extension.sh

CMD ["/bin/bash", "/app/install-git-extension.sh"]

