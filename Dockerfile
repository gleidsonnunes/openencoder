FROM golang:1.14-alpine AS builder

WORKDIR /src

RUN apk add --update --no-cache ca-certificates git nodejs nodejs-npm build-base

RUN git clone https://github.com/alfg/openencoder.git

RUN cd openencoder && go mod download

RUN cd openencoder && cd web && npm install && npm run build

RUN CGO_ENABLED=0 GOOS=linux cd openencoder && go clean -modcache

RUN CGO_ENABLED=0 GOOS=linux cd openencoder && go build -installsuffix 'static' -v -o /app .

RUN chmod +x /app

FROM linuxserver/ffmpeg:latest

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=builder /src/openencoder/web/dist /web/dist

COPY --from=builder /app /

COPY --from=builder /src/openencoder/config/default.yml /config/

EXPOSE 8080

RUN chmod +x /app

ENTRYPOINT ["/app"]