import 'package:buble/buble.dart';

Future<void> main() async {
  final client = BubleClient.fromEnvironment();

  final task = await client.generations.create(
    CreateGenerationRequest(
      model: 'gork/grok-imagine-video',
      mode: 'text_to_video',
      prompt: 'A slow cinematic shot of a futuristic train station at sunrise.',
    )
        .withParam('duration', '5s')
        .withParam('resolution', '480p')
        .withParam('aspect_ratio', '16:9'),
  );

  final result = await client.generations.wait(
    task.data.id,
    options: const WaitOptions(
      interval: Duration(seconds: 2),
      timeout: Duration(minutes: 15),
    ),
  );
  print(result.data.result?.videos.firstOrNull?.url);
}
