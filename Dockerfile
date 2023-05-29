FROM alpine:3.18.0

#gcr.io/distroless/base-nossl-debian11

WORKDIR /app

COPY todos ./todos
COPY public ./public
COPY views ./views

EXPOSE 8080

USER nonroot:nonroot

ENTRYPOINT ["/app/todos"]
