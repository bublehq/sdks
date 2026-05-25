import { Buble } from '@buble/sdk';

const buble = new Buble();

const response = await buble.chat.gemini.generateContent('openai/gpt-5.5', {
  contents: [
    {
      role: 'user',
      parts: [{ text: 'Write a short launch summary.' }]
    }
  ]
});

console.log(response.candidates?.[0]?.content?.parts?.[0]?.text);
