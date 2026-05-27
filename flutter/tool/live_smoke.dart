import 'package:buble/buble.dart';

Future<void> main() async {
  final client = BubleClient.fromEnvironment();

  final models = await client.mediaModels.list(mediaType: 'image');
  print({'step': 'media_models', 'count': models.data.length});

  final completion = await client.chat.completions.create({
    'model': 'openai/gpt-5.4',
    'messages': [
      {
        'role': 'user',
        'content': 'Reply with exactly: Buble Dart SDK live smoke OK',
      },
    ],
    'max_completion_tokens': 32,
  });

  print({'step': 'chat', 'response': completion});
}
