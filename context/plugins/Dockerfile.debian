ARG PRETALX_IMAGE=docker.io/library/pretalx/pretalx
ARG PRETALX_TAG=latest

FROM ${PRETALX_IMAGE}:${PRETALX_TAG}

RUN pip3 install -U prtx-faq \
                    pretalx-pages \
                    pretalx-public-voting
