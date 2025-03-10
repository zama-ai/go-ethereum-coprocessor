# Build Geth in a stock Go builder container
FROM golang:1.24-alpine AS build

# Install dependencies
RUN apk update &&\
    apk add --no-cache \
    gcc musl-dev linux-headers git git-lfs

WORKDIR /go-ethereum

# Copy codebase and build Geth
COPY . .
RUN go run build/ci.go install -static ./cmd/geth


# Final Stage
FROM alpine:3.20.3

# Install ca-certificates
RUN apk update &&\
    apk add --no-cache ca-certificates

# Copy the Geth binary from the builder stage
COPY --from=build /go-ethereum/build/bin/geth /usr/local/bin/

# Expose required ports
EXPOSE 8545 8546 30303 30303/udp

# Set entrypoint
ENTRYPOINT ["geth"]
