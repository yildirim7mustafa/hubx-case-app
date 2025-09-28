import { serve } from "@hono/node-server";
import { OpenAPIHono } from "@hono/zod-openapi";
import Valkey from "iovalkey";
import { PrismaClient } from "#/gen/prisma";
import api from "#/src/api";
import config from "#/src/config";
import health from "#/src/health";

const hono = new OpenAPIHono();
const prisma = new PrismaClient();
const valkey = new Valkey(config.VALKEY_PORT, config.VALKEY_HOST);

const main = async () => {
  await prisma.$connect();
  await valkey.ping();

  hono.route("/api", api(prisma, valkey));
  hono.route("/healthz", health(prisma, valkey));

  serve({
    port: config.PORT,
    fetch: (req) => {
      const url = new URL(req.url);
      url.protocol = req.headers.get("X-Forwarded-Proto") ?? url.protocol;
      const request = new Request(url, req);
      return hono.fetch(request);
    },
  });
};

["SIGINT", "SIGQUIT", "SIGTERM"].map((event) =>
  process.on(event, async () => {
    await prisma.$disconnect();
    valkey.disconnect();
    process.exit(0);
  }),
);

main().catch(console.error);
