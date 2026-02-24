import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_retriever/media_retriever.dart';

void main() => runApp(const MediaRetrieverExampleApp());

class MediaRetrieverExampleApp extends StatelessWidget {
  const MediaRetrieverExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Retriever Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ExamplePage(),
    );
  }
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  final MediaRetriever _retriever = const MediaRetriever();
  List<File> _files = [];

  Future<void> _pickMedias({int? limit}) async {
    final files = await _retriever.recupereMedias(context, limit: limit);
    if (!mounted) return;
    setState(() => _files = files);
  }

  Future<void> _pickPhotos() async {
    final files = await _retriever.recuperePhotos(context, limit: 5);
    if (!mounted) return;
    setState(() => _files = files);
  }

  Future<void> _pickVideos() async {
    final files = await _retriever.recupereVideos(context, limit: 1);
    if (!mounted) return;
    setState(() => _files = files);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Retriever Example'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton(
            onPressed: _pickMedias,
            child: const Text('Sélectionner des médias (illimité)'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () => _pickMedias(limit: 3),
            child: const Text('Sélectionner au plus 3 médias'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _pickPhotos,
            child: const Text('Photos uniquement (max 5)'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _pickVideos,
            child: const Text('Vidéos uniquement (max 1)'),
          ),
          const SizedBox(height: 24),
          Text(
            'Fichiers reçus: ${_files.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ..._files.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(f.path, style: const TextStyle(fontSize: 12)),
              )),
        ],
      ),
    );
  }
}
