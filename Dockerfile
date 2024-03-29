FROM python:3.10.0b2-alpine3.12 AS base

RUN pip install --upgrade pip==21.0.1
COPY python/ghsa ./ghsa

FROM base AS build

RUN apk --update \
    add --no-cache --virtual build_dependencies \
        alpine-sdk=1.0-r0 \
        libc-dev=0.7.2-r3 \
        libressl-dev=3.1.5-r0 \
        libffi-dev=3.3-r2 \
        python3-dev=3.8.10-r0

WORKDIR /app

COPY python/requirements.txt ./requirements.txt
COPY python/ghsa ./ghsa

RUN pip install -r ./requirements.txt && rm -rf ./requirements.txt
RUN apk del build_dependencies && rm -rf /root/.cache

FROM build AS prod

LABEL "maintainer"="atom.long <atom.long@hotmail.com>"
LABEL "repository"="https://github.com/atomlong/gh-secrets-action/"

RUN apk add --no-cache tini=0.19.0-r0

WORKDIR /app

ENV PYTHONPATH=/app
ENV PYTHONOPTIMIZE=2

COPY ./entrypoint.sh ./
COPY --from=build /app/ghsa ./ghsa

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/app/entrypoint.sh"]
