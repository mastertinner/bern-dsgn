FROM node:current as builder
WORKDIR /usr/src/app
COPY . ./
RUN hugo

FROM nginxinc/nginx-unprivileged:alpine
COPY --from=builder /usr/src/app/docs /usr/share/nginx/html
EXPOSE 8080
ENTRYPOINT ["nginx", "-g", "daemon off;"]

