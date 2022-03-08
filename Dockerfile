FROM golang:1.14-alpine AS builder

RUN mkdir /user && \
    echo 'nobody:x:65534:65534:nobody:/:' > /user/passwd && \
    echo 'nobody:x:65534:' > /user/group

WORKDIR /src

RUN apk add --update --no-cache ca-certificates git nodejs nodejs-npm gcc

RUN git clone https://github.com/alfg/openencoder.git

RUN cd openencoder && go mod download

RUN cd openencoder && cd web && npm install && npm run build

RUN CGO_ENABLED=0 GOOS=linux cd openencoder && go clean -modcache

RUN CGO_ENABLED=0 GOOS=linux cd openencoder && go build -installsuffix 'static' -v -o /app .

RUN chmod +x /app

FROM linuxserver/ffmpeg:latest

ARG BUILD_VERSION=${BUILD_VERSION}

ENV VERSION=$BUILD_VERSION

COPY --from=builder /user/group /user/passwd /etc/

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=builder /src/web/dist /web/

COPY --from=builder /app /

COPY --from=builder /src/config/default.yml /config/

EXPOSE 8080

RUN chmod +x /app

USER nobody:nobody

ENTRYPOINT ["/app"]