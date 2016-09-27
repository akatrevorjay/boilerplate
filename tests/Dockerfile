FROM ${IMAGE}
MAINTAINER Trevor Joynson "<docker@trevor.joynson.io>"

WORKDIR $IMAGE_ROOT
ADD layers/layers_test layers/layers_test
RUN apply-state-layer layers/layers_test

WORKDIR $APP_ROOT
