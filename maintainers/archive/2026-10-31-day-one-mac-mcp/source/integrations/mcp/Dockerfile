FROM node:24-bookworm-slim@sha256:c86ecead9e55a5210ac1727de38a4ca840bf03dcaf34dc9749addbf383b1920c AS build
WORKDIR /app/integrations/mcp
COPY integrations/mcp/package.json integrations/mcp/npm-shrinkwrap.json ./
RUN npm ci --ignore-scripts --no-audit --no-fund
COPY integrations/mcp/ ./
COPY docs/ /app/docs/
COPY config/mcp/ /app/config/mcp/
COPY LICENSE /app/LICENSE
RUN npm test && npm prune --omit=dev --ignore-scripts --no-audit --no-fund

FROM node:24-bookworm-slim@sha256:c86ecead9e55a5210ac1727de38a4ca840bf03dcaf34dc9749addbf383b1920c
ARG VERSION=0.1.1
LABEL org.opencontainers.image.title="day-one-mac-mcp" \
      org.opencontainers.image.version=$VERSION \
      org.opencontainers.image.source="https://github.com/CodeByKwakes/day-one-mac"
WORKDIR /app
COPY --from=build /app/integrations/mcp/package.json ./
COPY --from=build /app/integrations/mcp/LICENSE ./LICENSE
COPY --from=build /app/integrations/mcp/node_modules/ ./node_modules/
COPY --from=build /app/integrations/mcp/dist/src/ ./dist/src/
COPY --from=build /app/integrations/mcp/dist/guides.json ./dist/guides.json
COPY --from=build /app/integrations/mcp/dist/server-spec.json ./dist/server-spec.json
USER node
ENTRYPOINT ["node", "dist/src/index.js"]
