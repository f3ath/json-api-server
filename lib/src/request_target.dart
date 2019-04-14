import 'package:json_api_server/src/request.dart';
import 'package:json_api_server/src/response.dart';

abstract class RequestTarget {
  Request getRequest(String method);
}

class CollectionTarget implements RequestTarget {
  final String type;

  const CollectionTarget(this.type);

  @override
  Request getRequest(String method) =>
      {
        'GET': () => FetchCollection(this),
        'POST': () => CreateResource(this)
      }[method.toUpperCase()]() ??
      InvalidRequest(ErrorResponse.methodNotAllowed([]));
}

class ResourceTarget implements RequestTarget {
  final String type;
  final String id;

  const ResourceTarget(this.type, this.id);

  @override
  Request getRequest(String method) =>
      {
        'GET': () => FetchResource(this),
        'POST': () => DeleteResource(this),
        'DELETE': () => UpdateResource(this)
      }[method.toUpperCase()]() ??
      InvalidRequest(ErrorResponse.methodNotAllowed([]));
}

class RelationshipTarget implements RequestTarget {
  final String type;
  final String id;
  final String relationship;

  const RelationshipTarget(this.type, this.id, this.relationship);

  @override
  Request getRequest(String method) =>
      {
        'GET': () => FetchRelationship(this),
        'PATCH': () => UpdateRelationship(this),
        'POST': () => AddToMany(this)
      }[method.toUpperCase()]() ??
      InvalidRequest(ErrorResponse.methodNotAllowed([]));
}

class RelatedTarget implements RequestTarget {
  final String type;
  final String id;
  final String relationship;

  const RelatedTarget(this.type, this.id, this.relationship);

  @override
  Request getRequest(String method) {
    if (method.toUpperCase() == 'GET') return FetchRelated(this);
    return InvalidRequest(ErrorResponse.methodNotAllowed([]));
  }
}

class InvalidTarget implements RequestTarget {
  @override
  Request getRequest(String method) =>
      InvalidRequest(ErrorResponse.badRequest([]));
}
