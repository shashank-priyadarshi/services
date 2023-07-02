# Stage 1: Enter the domain of the Go binary construction
FROM golang:1.20 AS builder

WORKDIR /app

# Fetch the ancient scrolls of Go module manifests
COPY go.mod go.sum ./

# Unleash the dark magic to download the Go modules
RUN go mod download

# Infuse the application source code into the cauldron
COPY . .

# Forge the Go binary with unparalleled power
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

# Stage 2: Summon the ethereal vessel to house the Go binary
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Transfer the Go binary from the realm of builders
COPY --from=builder /app/app .

# Unveil the mystical portal to port 10000
EXPOSE 10000

# Unleash the incantation to awaken the Go binary
CMD ["./app"]
