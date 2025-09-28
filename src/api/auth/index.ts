import { OpenAPIHono } from "@hono/zod-openapi";
import { betterAuth } from "better-auth";
import { prismaAdapter } from "better-auth/adapters/prisma";
import { openAPI } from "better-auth/plugins";
import type Valkey from "iovalkey";
import type { PrismaClient } from "#/gen/prisma";

const secondaryStorage = (valkey: Valkey) => ({
  delete: async (key: string) => {
    await valkey.del(key);
  },
  get: async (key: string) => {
    return await valkey.get(key);
  },
  set: async (key: string, value: string | number, ttl: number | undefined) => {
    if (ttl) await valkey.set(key, value, "EX", ttl);
    else await valkey.set(key, value);
  },
});
export default (prisma: PrismaClient, valkey: Valkey) => {
  const hono = new OpenAPIHono({ strict: false });

  const auth = betterAuth({
    database: prismaAdapter(prisma, { provider: "postgresql" }),
    emailAndPassword: { enabled: true },
    plugins: [openAPI()],
    secondaryStorage: secondaryStorage(valkey),
  });

  hono.on(["POST", "GET"], "/*", (c) => auth.handler(c.req.raw));

  return { auth, hono };
};
