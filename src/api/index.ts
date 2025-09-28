import { OpenAPIHono } from "@hono/zod-openapi";
import { Scalar } from "@scalar/hono-api-reference";
import type Valkey from "iovalkey";
import type { PrismaClient } from "#/gen/prisma";
import auth from "#/src/api/auth";

export default (prisma: PrismaClient, valkey: Valkey) => {
  const hono = new OpenAPIHono();
  const betterAuth = auth(prisma, valkey);

  hono.route("/auth", betterAuth.hono);

  hono.doc("/open-api/generate-schema", { openapi: "3.0.0", info: { version: "1.0.0", title: "API" } });
  hono.get(
    "/documentation",
    Scalar({
      sources: [{ url: "/api/auth/open-api/generate-schema", title: "Auth" }],
    }),
  );
  return hono;
};
