#!/usr/bin/env node
import { Buble, BubleAPIError } from '../dist/esm/index.js';

const apiKey = process.env.BUBLE_API_KEY;
const baseURL = process.env.BUBLE_BASE_URL || 'https://buble.ai';

if (!apiKey) {
  console.error('Missing BUBLE_API_KEY. Run with BUBLE_API_KEY=sk_...');
  process.exit(1);
}

function pass(message) {
  console.log(`PASS ${message}`);
}

function info(message) {
  console.log(`INFO ${message}`);
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

async function main() {
  const buble = new Buble({
    apiKey,
    baseURL,
    timeout: 30_000
  });

  info(`Base URL: ${baseURL}`);

  const mediaModels = await buble.mediaModels.list();
  assert(Array.isArray(mediaModels.data), 'mediaModels.list() should return { data: array }.');
  assert(mediaModels.data.length > 0, 'mediaModels.list() returned no models.');
  pass(`mediaModels.list(): ${mediaModels.data.length} models`);

  const imageModels = await buble.mediaModels.list({ media_type: 'image' });
  assert(Array.isArray(imageModels.data), 'mediaModels.list({ media_type }) should return { data: array }.');
  pass(`mediaModels.list({ media_type: image }): ${imageModels.data.length} models`);

  const apps = await buble.apps.list({ limit: 10 });
  assert(Array.isArray(apps.data), 'apps.list() should return { data: array }.');
  pass(`apps.list(): ${apps.data.length} apps in first page`);

  if (apps.data[0]?.id) {
    const app = await buble.apps.retrieve(apps.data[0].id);
    assert(app.data.id === apps.data[0].id, 'apps.retrieve() should return the requested app id.');
    assert(Array.isArray(app.data.input_parameters), 'apps.retrieve() should expose input_parameters.');
    pass(`apps.retrieve(${apps.data[0].id})`);
  }

  const chatModels = await buble.chat.models.list();
  assert(chatModels.object === 'list', 'chat.models.list() should preserve OpenAI-style object=list response.');
  assert(Array.isArray(chatModels.data), 'chat.models.list() should return data array.');
  assert(chatModels.data.length > 0, 'chat.models.list() returned no chat models.');
  pass(`chat.models.list(): ${chatModels.data.length} models`);

  try {
    await buble.generations.retrieve('sdk-smoke-non-existent-task');
  } catch (error) {
    if (error instanceof BubleAPIError) {
      assert(error.status >= 400, 'retrieve(non-existent) should return an API error status.');
      pass(`BubleAPIError parsing: ${error.status}${error.code ? ` ${error.code}` : ''}`);
    } else {
      throw error;
    }
  }

  pass('live smoke test completed without creating billable generation tasks');
}

main().catch((error) => {
  console.error('FAIL live smoke test failed');
  if (error instanceof BubleAPIError) {
    console.error(`API ${error.status}${error.code ? ` ${error.code}` : ''}: ${error.message}`);
    if (error.details) console.error(JSON.stringify(error.details, null, 2));
  } else {
    console.error(error);
  }
  process.exit(1);
});
