import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// A robust network image widget that works across all Flutter platforms.
///
/// - **Web**: Proxies external URLs through the backend (`/api/image-proxy`)
///   to bypass CORS restrictions in CanvasKit renderer.
/// - **Mobile/Desktop**: Uses [Dio] to fetch raw bytes directly.
class DioNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext context)? placeholderBuilder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final BorderRadius? borderRadius;

  const DioNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderBuilder,
    this.errorBuilder,
    this.borderRadius,
  });

  @override
  State<DioNetworkImage> createState() => _DioNetworkImageState();
}

class _DioNetworkImageState extends State<DioNetworkImage> {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    responseType: ResponseType.bytes,
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Accept': 'image/*,*/*;q=0.8',
    },
  ));

  /// Simple in-memory cache.
  static final Map<String, Uint8List> _cache = {};

  late Future<Uint8List> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _fetchImage(widget.imageUrl);
  }

  @override
  void didUpdateWidget(covariant DioNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageFuture = _fetchImage(widget.imageUrl);
    }
  }

  /// Resolve the fetch URL.
  /// On Web, external URLs go through our backend image proxy to bypass CORS.
  /// On Mobile/Desktop, use the URL directly.
  String _resolveUrl(String url) {
    if (!kIsWeb) return url;

    // If the URL is already pointing to our own backend, no proxy needed
    final apiBase = AppConfig.baseUrl;
    final origin = apiBase.endsWith('/api')
        ? apiBase.substring(0, apiBase.length - 4)
        : apiBase;

    if (url.startsWith(origin)) return url;

    // External URL on Web → proxy through backend
    final encoded = Uri.encodeComponent(url);
    return '$origin/api/image-proxy?url=$encoded';
  }

  Future<Uint8List> _fetchImage(String url) async {
    if (_cache.containsKey(url)) return _cache[url]!;

    final fetchUrl = _resolveUrl(url);
    debugPrint('🖼️ DioNetworkImage: Fetching $fetchUrl');

    final response = await _dio.get<List<int>>(fetchUrl);
    final bytes = Uint8List.fromList(response.data!);

    // Cache (limit to 100 entries)
    if (_cache.length > 100) _cache.remove(_cache.keys.first);
    _cache[url] = bytes;

    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return _wrapBorderRadius(
      FutureBuilder<Uint8List>(
        future: _imageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return widget.placeholderBuilder?.call(context) ??
                _defaultPlaceholder();
          }

          if (snapshot.hasError || !snapshot.hasData) {
            debugPrint(
                '⚠️ DioNetworkImage error: ${widget.imageUrl} → ${snapshot.error}');
            return widget.errorBuilder
                    ?.call(context, snapshot.error ?? 'Unknown error') ??
                _defaultError();
          }

          return Image.memory(
            snapshot.data!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          );
        },
      ),
    );
  }

  Widget _wrapBorderRadius(Widget child) {
    if (widget.borderRadius == null) return child;
    return ClipRRect(
      borderRadius: widget.borderRadius!,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: child,
      ),
    );
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _defaultError() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
