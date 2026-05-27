import 'package:buble/buble.dart';

Future<void> main() async {
  final client = BubleClient.fromEnvironment();

  final task = await client.apps.generations.create(
    'video-background-remover',
    {
      'source_video': ['https://example.com/source.mp4'],
      'refine_foreground_edges': true,
      'subject_is_person': true,
    },
  );

  final result = await client.apps.generations.wait(
    'video-background-remover',
    task.data.id,
  );
  print(result.data.result?.videos.firstOrNull?.url);
}
