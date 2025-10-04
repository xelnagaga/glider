# Build Stage
FROM golang:1.24-alpine AS build-env
ADD . /src
RUN apk --no-cache add git \
    && cd /src && go build -v -ldflags "-s -w"

# Final Stage
FROM alpine
COPY --from=build-env /src/glider /app/
COPY --from=build-env /src/glider.conf /app/
WORKDIR /app
RUN apk -U upgrade --no-cache \
    && apk --no-cache add ca-certificates
USER 1000
ENTRYPOINT ["./glider"]
