import { Buble } from '@buble/sdk';

const buble = new Buble();

const task = await buble.apps.generations.create('asmr-crushing-frozen-fruits', {
  fruit: 'Strawberries',
  video_ratio: '16:9',
  video_resolution: '720p'
});

const result = await buble.apps.generations.wait(
  'asmr-crushing-frozen-fruits',
  task.data.id
);

console.log(result.data.result?.videos?.[0]?.url);
