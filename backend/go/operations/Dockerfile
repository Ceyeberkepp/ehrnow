FROM golang:1.23-bookworm AS build
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 go build -o /operations .

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /operations /operations
CMD ["/operations"]
