FROM golang:1.22 as builder

WORKDIR /opt/
RUN git clone https://github.com/nerdswords/yet-another-cloudwatch-exporter.git . \
    && git checkout v0.56.0
RUN GOPROXY=direct go mod download

ENV GOOS linux
ENV CGO_ENABLED=0

ARG VERSION
RUN go build -v -ldflags "-X main.version=$VERSION" -o yace ./cmd/yace

FROM alpine:3.19.1

EXPOSE 5000

RUN addgroup -g 1000 exporter && \
    adduser -u 1000 -D -G exporter exporter -h /exporter

WORKDIR /exporter/

RUN apk --no-cache add ca-certificates

COPY --from=builder /opt/yace /usr/local/bin/yace


COPY yace-config.txt /exporter/config.yml
ENTRYPOINT ["yace"]
USER exporter
CMD ["--config.file=/exporter/config.yml"]

