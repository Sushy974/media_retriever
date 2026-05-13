export 'media_retriever_stub.dart'
    if (dart.library.io) 'media_retriever_mobile.dart'
    if (dart.library.js_interop) 'media_retriever_web.dart';
