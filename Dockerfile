FROM node:14 as deps

WORKDIR /cal.com

# Copy rootand all workspace package.json files
COPY cal.com/package.json cal.com/yarn.lock cal.com/turbo.json ./
COPY cal.com/apps/web/package.json cal.com/apps/web/yarn.lock ./apps/web/
COPY cal.com/packages/ui/package.json ./packages/ui/package.json
COPY cal.com/packages/types/package.json ./packages/types/package.json
COPY cal.com/packages/core/package.json ./packages/core/package.json
COPY cal.com/packages/config/package.json ./packages/config/package.json
COPY cal.com/packages/ee/package.json ./packages/ee/package.json
COPY cal.com/packages/tsconfig/package.json ./packages/tsconfig/package.json
COPY cal.com/packages/prisma/package.json ./packages/prisma/package.json
COPY cal.com/packages/app-store/googlevideo/package.json ./packages/app-store/googlevideo/package.json
COPY cal.com/packages/app-store/caldavcalendar/package.json ./packages/app-store/caldavcalendar/package.json
COPY cal.com/packages/app-store/zoomvideo/package.json ./packages/app-store/zoomvideo/package.json
COPY cal.com/packages/app-store/huddle01video/package.json ./packages/app-store/huddle01video/package.json
COPY cal.com/packages/app-store/jitsivideo/package.json ./packages/app-store/jitsivideo/package.json
COPY cal.com/packages/app-store/stripepayment/package.json ./packages/app-store/stripepayment/package.json
COPY cal.com/packages/app-store/office365video/package.json ./packages/app-store/office365video/package.json
COPY cal.com/packages/app-store/office365calendar/package.json ./packages/app-store/office365calendar/package.json
COPY cal.com/packages/app-store/slackmessaging/package.json ./packages/app-store/slackmessaging/package.json
COPY cal.com/packages/app-store/tandemvideo/package.json ./packages/app-store/tandemvideo/package.json
COPY cal.com/packages/app-store/wipemycalother/package.json ./packages/app-store/wipemycalother/package.json
COPY cal.com/packages/app-store/package.json ./packages/app-store/package.json
COPY cal.com/packages/app-store/_example/package.json ./packages/app-store/_example/package.json
COPY cal.com/packages/app-store/googlecalendar/package.json ./packages/app-store/googlecalendar/package.json
COPY cal.com/packages/app-store/dailyvideo/package.json ./packages/app-store/dailyvideo/package.json
COPY cal.com/packages/app-store/applecalendar/package.json ./packages/app-store/applecalendar/package.json
COPY cal.com/packages/app-store/hubspotothercalendar/package.json ./packages/app-store/hubspotothercalendar/package.json
COPY cal.com/packages/lib/package.json ./packages/lib/package.json
COPY cal.com/packages/embeds/embed-snippet/package.json ./packages/embeds/embed-snippet/package.json
COPY cal.com/packages/embeds/embed-react/package.json ./packages/embeds/embed-react/package.json
COPY cal.com/packages/embeds/embed-core/package.json ./packages/embeds/embed-core/package.json
COPY cal.com/packages/stripe/package.json ./packages/stripe/package.json

# Prisma schema is required by a post-install script
COPY cal.com/packages/prisma/schema.prisma ./packages/prisma/schema.prisma

# Install dependencies
RUN yarn install --frozen-lockfile

FROM node:14 as builder

WORKDIR /cal.com
ARG NEXT_PUBLIC_WEBAPP_URL
ARG NEXT_PUBLIC_LICENSE_CONSENT
ARG NEXT_PUBLIC_TELEMETRY_KEY
# DEPRECATED
ARG BASE_URL
ARG NEXT_PUBLIC_APP_URL

ENV NEXT_PUBLIC_WEBAPP_URL=$NEXT_PUBLIC_WEBAPP_URL \
    BASE_URL=$BASE_URL \
    NEXT_PUBLIC_APP_URL=$NEXT_PUBLIC_APP_URL \
    NEXT_PUBLIC_LICENSE_CONSENT=$NEXT_PUBLIC_LICENSE_CONSENT \
    NEXT_PUBLIC_TELEMETRY_KEY=$NEXT_PUBLIC_TELEMETRY_KEY

COPY cal.com/package.json cal.com/yarn.lock cal.com/turbo.json ./
COPY cal.com/apps/web ./apps/web
COPY cal.com/packages ./packages
COPY --from=deps /cal.com/node_modules ./node_modules
RUN yarn build

FROM node:14 as runner
WORKDIR /cal.com
ENV NODE_ENV production
RUN apt-get update && \
    apt-get -y install netcat && \
    rm -rf /var/lib/apt/lists/* && \
    npm install --global prisma

COPY cal.com/package.json cal.com/yarn.lock cal.com/turbo.json ./
COPY --from=deps /cal.com/node_modules ./node_modules
COPY --from=builder /cal.com/packages ./packages
COPY --from=deps /cal.com/apps/web/node_modules ./apps/web/node_modules
COPY --from=builder /cal.com/apps/web/scripts ./apps/web/scripts
COPY --from=builder /cal.com/apps/web/next.config.js ./apps/web/next.config.js
COPY --from=builder /cal.com/apps/web/next-i18next.config.js ./apps/web/next-i18next.config.js
COPY --from=builder /cal.com/apps/web/public ./apps/web/public
COPY --from=builder /cal.com/apps/web/.next ./apps/web/.next
COPY --from=builder /cal.com/apps/web/package.json ./apps/web/package.json
COPY --from=builder cal.com/packages/prisma/schema.prisma ./prisma/schema.prisma
COPY scripts scripts

EXPOSE 3000
CMD ["/cal.com/scripts/start.sh"]
