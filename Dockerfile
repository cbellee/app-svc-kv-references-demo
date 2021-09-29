FROM golang:1.16-alpine as builder

ENV APP_SECRET=""
WORKDIR /app

COPY go.mod ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /main

FROM alpine:3.11.3

COPY --from=builder /main .
EXPOSE 80
CMD [ "/main" ]