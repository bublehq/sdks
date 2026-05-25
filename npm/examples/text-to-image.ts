import { Buble } from '@buble/sdk';

const buble = new Buble();

const task = await buble.generations.create({
  model: 'google/nano-banana',
  mode: 'text_to_image',
  prompt: 'A cinematic product photo of a ceramic coffee grinder',
  aspect_ratio: '1:1',
  output_format: 'png'
});

const result = await buble.generations.wait(task.data.id);
console.log(result.data.result?.images?.[0]?.url);
