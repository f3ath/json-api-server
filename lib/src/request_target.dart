import 'dart:io';

import 'package:json_api_server/src/response.dart';
import 'package:json_api_server/src/routing.dart';

abstract class RequestTarget {
  Uri url(Routing design);

  const RequestTarget();
}

class CollectionTarget extends RequestTarget {
  final String type;

  const CollectionTarget(this.type);

  @override
  Uri url(Routing design) => design.collection(type);

  CollectionResponse createResponse(
          HttpRequest request, ResponseBuilder builder) =>
      builder.collection(this, request);


}

class ResourceTarget extends RequestTarget {
  final String type;
  final String id;

  const ResourceTarget(this.type, this.id);

  @override
  Uri url(Routing design) => design.resource(type, id);

  ResourceResponse createResponse(
          HttpRequest request, ResponseBuilder builder) =>
      builder.resource(this, request);
}

class RelationshipTarget extends RequestTarget {
  final String type;
  final String id;
  final String relationship;

  const RelationshipTarget(this.type, this.id, this.relationship);

  @override
  Uri url(Routing design) => design.relationship(type, id, relationship);

  RelatedTarget toRelated() => RelatedTarget(type, id, relationship);

  RelationshipResponse createResponse(
          HttpRequest request, ResponseBuilder builder) =>
      builder.relationship(this, request);
}

class RelatedTarget extends RequestTarget {
  final String type;
  final String id;
  final String relationship;

  const RelatedTarget(this.type, this.id, this.relationship);

  @override
  Uri url(Routing design) => design.related(type, id, relationship);

  RelatedResponse createResponse(
          HttpRequest request, ResponseBuilder builder) =>
      builder.related(this, request);
}
