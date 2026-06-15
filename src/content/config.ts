import { defineCollection, z } from 'astro:content';

const blog = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    description: z.string(),
    pubDate: z.coerce.date(),
    updatedDate: z.coerce.date().optional(),
    heroImage: z.string().optional(),
    category: z.string().default('未分类'),
    tags: z.array(z.string()).default([]),
    draft: z.boolean().default(false),
    pin: z.boolean().default(false),
    author: z.string().default(''),
    cover: z.string().default('📝'),
    color: z.enum([
      'app-pink', 'purple', 'app-blue', 'app-yellow',
      'app-orange', 'app-teal', 'app-green', 'app-red',
      'lime-green', 'yellow-green', 'brown', 'warm-peach-pink'
    ]).default('app-blue'),
    readTime: z.string().default('5 分钟'),
  }),
});

export const collections = { blog };
