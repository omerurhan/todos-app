FROM alpine:3.18

WORKDIR /app

COPY todos ./todos
COPY public ./public
COPY views ./views

EXPOSE 8080

RUN addgroup -S nonroot \
    && adduser -S nonroot -G nonroot

USER nonroot

ENTRYPOINT ["/app/todos"]
