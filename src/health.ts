import { OpenAPIHono } from "@hono/zod-openapi";
import type Valkey from "iovalkey";
import type { PrismaClient } from "#/gen/prisma";

export default (prisma: PrismaClient, valkey: Valkey) => {
  const hono = new OpenAPIHono();

  hono.on("GET", "/", async (c) => {
    await prisma.$queryRaw`SELECT 1`;
    await valkey.ping();
    return c.text("OK");
  });

  return hono;
};
