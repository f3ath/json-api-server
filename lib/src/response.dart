import 'package:json_api_document/json_api_document.dart';
import 'package:json_api_server/json_api_server.dart';
import 'package:json_api_server/src/request_target.dart';

abstract class Response {
  final int status;

  const Response(this.status);

  Document getDocument(DocumentBuilder builder, Uri self);

  Map<String, String> getHeaders(UriSchema schema) =>
      {'Content-Type': 'application/vnd.api+json'};
}

class ErrorResponse extends Response {
  final Iterable<JsonApiError> errors;

  const ErrorResponse(int status, this.errors) : super(status);

  Document getDocument(DocumentBuilder builder, Uri self) =>
      builder.errorDocument(errors);

  const ErrorResponse.notImplemented(this.errors) : super(501);

  const ErrorResponse.notFound(this.errors) : super(404);

  const ErrorResponse.badRequest(this.errors) : super(400);

  const ErrorResponse.methodNotAllowed(this.errors) : super(405);

  const ErrorResponse.conflict(this.errors) : super(409);
}

class CollectionResponse extends Response {
  final Collection<Resource> collection;
  final Iterable<Resource> included;

  const CollectionResponse(this.collection, {this.included = const []})
      : super(200);

  @override
  Document getDocument(DocumentBuilder builder, Uri self) =>
      builder.collectionDocument(collection, self, included: included);
}

class ResourceResponse extends Response {
  final Resource resource;
  final Iterable<Resource> included;

  const ResourceResponse(this.resource, {this.included = const []})
      : super(200);

  @override
  Document getDocument(DocumentBuilder builder, Uri self) =>
      builder.resourceDocument(resource, self, included: included);
}

class RelatedResourceResponse extends Response {
  final Resource resource;
  final Iterable<Resource> included;

  const RelatedResourceResponse(this.resource, {this.included = const []})
      : super(200);

  @override
  Document getDocument(DocumentBuilder builder, Uri self) =>
      builder.relatedResourceDocument(resource, self);
}

class RelatedCollectionResponse extends Response {
  final Collection<Resource> collection;
  final Iterable<Resource> included;

  const RelatedCollectionResponse(this.collection, {this.included = const []})
      : super(200);

  @override
  Document getDocument(DocumentBuilder builder, Uri self) =>
      builder.relatedCollectionDocument(collection, self);
}

class ToOneResponse extends Response {
  final Identifier identifier;
  final RelationshipTarget target;

  const ToOneResponse(this.target, this.identifier) : super(200);

  @override
  Document<PrimaryData> getDocument(DocumentBuilder builder, Uri self) =>
      builder.toOneDocument(identifier, target, self);
}

class ToManyResponse extends Response {
  final Iterable<Identifier> collection;
  final RelationshipTarget target;

  const ToManyResponse(this.target, this.collection) : super(200);

  @override
  Document<PrimaryData> getDocument(DocumentBuilder builder, Uri self) =>
      builder.toManyDocument(collection, target, self);
}

class MetaResponse extends Response {
  final Map<String, Object> meta;

  MetaResponse(this.meta) : super(200);

  @override
  Document<PrimaryData> getDocument(DocumentBuilder builder, Uri self) =>
      builder.metaDocument(meta);
}

class NoContent extends Response {
  const NoContent() : super(204);

  @override
  Document<PrimaryData> getDocument(DocumentBuilder builder, Uri self) => null;
}

class SeeOther extends Response {
  final Resource resource;

  SeeOther(this.resource) : super(303);

  @override
  Document<PrimaryData> getDocument(DocumentBuilder builder, Uri self) => null;

  @override
  Map<String, String> getHeaders(UriSchema schema) => super.getHeaders(schema)
    ..['Location'] = schema.resource(resource.type, resource.id).toString();
}

class ResourceCreated extends Response {
  final Resource resource;

  ResourceCreated(this.resource) : super(201);

  @override
  Document<PrimaryData> getDocument(DocumentBuilder builder, Uri self) =>
      builder.resourceDocument(resource, self);

  @override
  Map<String, String> getHeaders(UriSchema schema) => super.getHeaders(schema)
    ..['Location'] = schema.resource(resource.type, resource.id).toString();
}

class ResourceUpdated extends Response {
  final Resource resource;

  ResourceUpdated(this.resource) : super(200);

  @override
  Document<PrimaryData> getDocument(DocumentBuilder builder, Uri self) =>
      builder.resourceDocument(resource, self);
}

class Accepted extends Response {
  final Resource resource;

  Accepted(this.resource) : super(202);

  @override
  Document<PrimaryData> getDocument(DocumentBuilder builder, Uri self) =>
      builder.resourceDocument(resource, self);

  @override
  Map<String, String> getHeaders(UriSchema schema) => super.getHeaders(schema)
    ..['Content-Location'] =
        schema.resource(resource.type, resource.id).toString();
}
