import { Buble } from '@buble/sdk';

const buble = new Buble();

const completion = await buble.chat.completions.create({
  model: 'openai/gpt-5.5',
  messages: [{ role: 'user', content: 'Write a short launch summary.' }],
  reasoning: true,
  max_completion_tokens: 800
});

console.log(completion.choices?.[0]?.message?.content);
