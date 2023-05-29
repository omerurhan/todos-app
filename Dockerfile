FROM gcr.io/distroless/base-debian11

WORKDIR /app

COPY todos ./todos
COPY public ./public
COPY views ./views

EXPOSE 8080

#USER nonroot:nonroot

ENTRYPOINT ["/app/todos"]
