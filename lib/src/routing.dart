import 'package:json_api_server/src/request.dart';

/// The routing schema (URL Design) defines the design of URLs used by the server.
class Routing {
  final Uri base;

  Routing(this.base) {
    ArgumentError.checkNotNull(base, 'base');
  }

  /// Builds a URL for a resource collection
  Uri collection(String type) => _path([type]);

  /// Builds a URL for a related resource
  Uri related(String type, String id, String relationship) =>
      _path([type, id, relationship]);

  /// Builds a URL for a relationship object
  Uri relationship(String type, String id, String relationship) =>
      _path([type, id, 'relationships', relationship]);

  /// Builds a URL for a single resource
  Uri resource(String type, String id) => _path([type, id]);

  /// This function must return either:
  /// - [CollectionTarget]
  /// - [ResourceTarget]
  /// - [RelationshipTarget]
  /// - [RelatedTarget]
  /// - null if the target can not be determined
  RequestTarget getTarget(Uri uri) {
    final seg = uri.pathSegments;
    switch (seg.length) {
      case 1:
        return CollectionTarget(uri, seg[0]);
      case 2:
        return ResourceTarget(uri, seg[0], seg[1]);
      case 3:
        return RelatedTarget(uri, seg[0], seg[1], seg[2]);
      case 4:
        if (seg[2] == 'relationships') {
          return RelationshipTarget(uri, seg[0], seg[1], seg[3]);
        }
    }
    return null;
  }

  Uri _path(List<String> segments) =>
      base.replace(pathSegments: base.pathSegments + segments);
}
