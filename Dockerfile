# Stage 1: Build the frontend
FROM node:18-alpine AS frontend
WORKDIR /app
COPY . .
WORKDIR /app/web
RUN npm install
RUN npm run build-prod

# Stage 2: Build the server
FROM golang:1.20-alpine AS backend
WORKDIR /app
RUN go install github.com/rakyll/statik@latest
COPY --from=frontend /app/web/dist ./web/dist
COPY . .
RUN statik -m -src="./web/dist" -f -dest="./server/embed" -p web -ns web
WORKDIR /app/server
RUN go build -ldflags "-s -w" -tags=jsoniter -o /server .

# Stage 3: Final image
FROM alpine:latest
WORKDIR /app
COPY --from=backend /server /app/server
EXPOSE 7860
ENV SPARK_LISTEN=:7860
ENV SPARK_SALT=default-salt
CMD ["/app/server"]
