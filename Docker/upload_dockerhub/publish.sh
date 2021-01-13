#!/bin/bash
set -e

if [ -z $QUERYSERVICE_BACKEND_DOCKER_PATH ] || \
[ -z $QUERYSERVICE_FRONTEND_DOCKER_PATH ] || \
[ -z $QUERYSERVICE_UI_IMAGE_NAME ] || \
[ -z $QUERYSERVICE_IMAGE_NAME ] || \
[ -z $WIKIBASE_IMAGE_NAME ] || \
[ -z $RELEASE_MAJOR_VERSION ] || \
[ -z $QUERYSERVICE_VERSION ] || \
[ -z $DOCKER_HUB_ID ] || \
[ -z $DOCKER_HUB_REPOSITORY_NAME ] || \
[ -z $DOCKER_HUB_ACCESS_TOKEN ] ; then
    echo "A variable is required but isn't set. You should pass it to docker. See: https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file";
    exit 1;
fi

function tag_and_push {
    IMAGE_NAME=$1
    IMAGE_VERSION=$2

    # example: wikibase/wikibase:1.35
    IMAGE_TAG="$DOCKER_HUB_REPOSITORY_NAME/$IMAGE_NAME:$IMAGE_VERSION"
    docker tag "$IMAGE_NAME:latest" $IMAGE_TAG

    if [ -z $DRY_RUN ]; then
        docker push $IMAGE_TAG
    else
        echo "DRY RUN! Not pushing $IMAGE $IMAGE_TAG"
    fi
}

# start and wait for dockerd and set the correct socket
docker --version
sh /usr/local/bin/dockerd-entrypoint.sh dockerd &
export DOCKER_HOST=unix:///run/user/1000/docker.sock
sleep 5

echo 'Start tagging & publishing ...'

# Login
echo "Signing in as $DOCKER_HUB_ID"
echo $DOCKER_HUB_ACCESS_TOKEN | docker login --username $DOCKER_HUB_ID --password-stdin

# load images
docker load -i "$WIKIBASE_DOCKER_PATH"
docker load -i "$QUERYSERVICE_BACKEND_DOCKER_PATH"
docker load -i "$QUERYSERVICE_FRONTEND_DOCKER_PATH"

# Tag Queryservice UI with version
tag_and_push $QUERYSERVICE_UI_IMAGE_NAME $RELEASE_MAJOR_VERSION

# Tag Queryservice with version
tag_and_push $QUERYSERVICE_IMAGE_NAME $QUERYSERVICE_VERSION

# Tag Wikibase with version
tag_and_push $WIKIBASE_IMAGE_NAME $RELEASE_MAJOR_VERSION

# logout and remove credentials 
docker logout
rm /home/rootless/.docker/config.json