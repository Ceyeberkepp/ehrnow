FROM rust:1-bookworm AS build
WORKDIR /app
COPY . .
RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /app/target/release/ehrnow-clinical-api /usr/local/bin/ehrnow-clinical-api
COPY --from=build /app/migrations /app/migrations
EXPOSE 8080
CMD ["ehrnow-clinical-api"]
