import 'package:buble/buble.dart';

Future<void> main() async {
  final client = BubleClient.fromEnvironment();

  final task = await client.generations.create(
    CreateGenerationRequest(
      model: 'google/nano-banana',
      mode: 'text_to_image',
      prompt: 'A cinematic product photo of a matte black espresso cup',
    ).withParam('aspect_ratio', '1:1').withParam('output_format', 'png'),
  );

  final result = await client.generations.wait(task.data.id);
  print(result.data.result?.images.firstOrNull?.url);
}
