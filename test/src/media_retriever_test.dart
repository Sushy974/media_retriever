// Not required for test files
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_retriever/media_retriever.dart';

void main() {
  group('MediaRetriever', () {
    test('can be instantiated', () {
      expect(MediaRetriever(), isNotNull);
    });

    group('limit validation', () {
      testWidgets('recupereMedias throws ArgumentError when limit is 0',
          (tester) async {
        const key = Key('test-context');
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              key: key,
              builder: (context) => const SizedBox(),
            ),
          ),
        );
        final context = tester.element(find.byKey(key));
        const retriever = MediaRetriever();
        expect(
          () => retriever.recupereMedias(context, limit: 0),
          throwsArgumentError,
        );
      });

      testWidgets('recupereMedias throws ArgumentError when limit is negative',
          (tester) async {
        const key = Key('test-context');
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              key: key,
              builder: (context) => const SizedBox(),
            ),
          ),
        );
        final context = tester.element(find.byKey(key));
        const retriever = MediaRetriever();
        expect(
          () => retriever.recupereMedias(context, limit: -1),
          throwsArgumentError,
        );
      });

      testWidgets('recuperePhotos throws ArgumentError when limit is 0',
          (tester) async {
        const key = Key('test-context');
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              key: key,
              builder: (context) => const SizedBox(),
            ),
          ),
        );
        final context = tester.element(find.byKey(key));
        const retriever = MediaRetriever();
        expect(
          () => retriever.recuperePhotos(context, limit: 0),
          throwsArgumentError,
        );
      });

      testWidgets('recupereVideos throws ArgumentError when limit is 0',
          (tester) async {
        const key = Key('test-context');
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              key: key,
              builder: (context) => const SizedBox(),
            ),
          ),
        );
        final context = tester.element(find.byKey(key));
        const retriever = MediaRetriever();
        expect(
          () => retriever.recupereVideos(context, limit: 0),
          throwsArgumentError,
        );
      });
    });
  });
}
