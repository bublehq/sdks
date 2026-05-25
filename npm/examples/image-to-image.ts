import { Buble } from '@buble/sdk';

const buble = new Buble();

const uploaded = await buble.files.upload('./reference.png', {
  file_type: 'image',
  model: 'google/nano-banana',
  mode: 'image_to_image'
});

const task = await buble.generations.create({
  model: 'google/nano-banana',
  mode: 'image_to_image',
  prompt: 'Turn this reference into a polished ecommerce hero image.',
  image_urls: [uploaded.data.url],
  aspect_ratio: '1:1'
});

const result = await buble.generations.wait(task.data.id);
console.log(result.data.result?.images?.[0]?.url);
