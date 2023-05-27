# Deploy the application binary into a lean image
FROM gcr.io/distroless/base-debian11

WORKDIR /

COPY todos /todos
EXPOSE 8080

#USER nonroot:nonroot

ENTRYPOINT ["/todos"]