import { Buble } from '@buble/sdk';

const buble = new Buble();

const message = await buble.chat.messages.create({
  model: 'openai/gpt-5.5',
  system: 'You are concise.',
  messages: [{ role: 'user', content: 'Summarize this release in three bullets.' }],
  max_tokens: 800
});

console.log(message);
