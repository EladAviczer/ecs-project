FROM golang:1.24-alpine AS builder

ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go build -o app .

FROM gcr.io/distroless/static-debian12

COPY --from=builder /app/app /

ENTRYPOINT ["/app"]
