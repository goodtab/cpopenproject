FROM node:18

WORKDIR /app
COPY package.json ./
COPY index.js ./
RUN npm install
EXPOSE 1234

CMD ["node", "index.js"]
