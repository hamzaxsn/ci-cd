FROM node:18-alpine AS build

WORKDIR /app

COPY package*.json ./

COPY . .

RUN npm install

RUN npm run build

FROM nginx:alpine

WORKDIR /app

COPY --from=build /app/build /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
