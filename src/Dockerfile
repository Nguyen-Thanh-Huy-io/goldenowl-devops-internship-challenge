# production stage #
FROM node:20-alpine as deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# runtime stage #
FROM node:20-alpine
ENV NODE_ENV=production
WORKDIR /app

COPY --from=deps --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node index.js ./
COPY --chown=node:node server/index.js ./server/index.js
COPY --chown=node:node routes ./routes

USER node
EXPOSE 3000
CMD ["node", "index.js"]