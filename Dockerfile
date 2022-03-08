FROM golang:1.14-alpine AS builder

RUN mkdir /user && \
    echo 'nobody:x:65534:65534:nobody:/:' > /user/passwd && \
    echo 'nobody:x:65534:' > /user/group

WORKDIR /src

RUN apk add --update --no-cache ca-certificates git nodejs nodejs-npm

COPY go.mod go.sum ./

RUN go mod download

COPY . .

RUN cd web && npm install && npm run build

RUN CGO_ENABLED=0 GOOS=linux go build -installsuffix 'static' -v -o /app .

FROM linuxserver/ffmpeg:latest

ARG BUILD_VERSION=${BUILD_VERSION}

ENV VERSION=$BUILD_VERSION

COPY --from=builder /user/group /user/passwd /etc/

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=builder /src/web/dist /web/dist

COPY --from=builder /app /app

COPY --from=builder /src/config/default.yml /config/default.yml

EXPOSE 8080

RUN chmod +x /app

USER nobody:nobody

ENTRYPOINT ["/app"]