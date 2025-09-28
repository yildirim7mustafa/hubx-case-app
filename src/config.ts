import { z } from "@hono/zod-openapi";

export default z
  .object({
    NODE_ENV: z.enum(["development", "production"]).default("development"),
    PORT: z.number().default(8080),
    POSTGRESQL_URL: z.string().trim(),
    VALKEY_HOST: z.string().trim(),
    VALKEY_PORT: z.preprocess((val) => val ? Number(val) : 6379, z.number().default(6379)),
  })
  .parse(process.env);
