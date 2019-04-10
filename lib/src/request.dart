import 'dart:async';

import 'package:json_api_document/json_api_document.dart';
import 'package:json_api_document/parser.dart';
import 'package:json_api_server/src/collection.dart';
import 'package:json_api_server/src/controller.dart';
import 'package:json_api_server/src/document_builder.dart';
import 'package:json_api_server/src/response.dart';

abstract class RequestTarget {
  Uri get uri;
}

class CollectionTarget implements RequestTarget {
  final Uri uri;
  final String type;

  const CollectionTarget(this.uri, this.type);

  JsonApiRequest getControllerRequest(String method) {
    if (method == 'GET') return FetchCollection(this);
    if (method == 'POST') return CreateResource(this);
    throw 'Invalid method $method';
  }
}

class ResourceTarget implements RequestTarget {
  final Uri uri;
  final String type;
  final String id;

  const ResourceTarget(this.uri, this.type, this.id);

  JsonApiRequest getControllerRequest(String method) {
//    if (method == 'GET') return FetchResource(this);
//    if (method == 'DELETE') return DeleteResource(this);
//    if (method == 'PATCH') return UpdateResource(this);
    throw 'Invalid method $method';
  }
}

class RelationshipTarget implements RequestTarget {
  final Uri uri;
  final String type;
  final String id;
  final String relationship;

  const RelationshipTarget(this.uri, this.type, this.id, this.relationship);
}

class RelatedTarget implements RequestTarget {
  final Uri uri;
  final String type;
  final String id;
  final String relationship;

  const RelatedTarget(this.uri, this.type, this.id, this.relationship);
}

/*
    REQUEST
 */

abstract class JsonApiRequest {
  JsonApiResponse response;

  void errorNotFound(Iterable<JsonApiError> errors) => error(404, errors);

  void errorBadRequest(Iterable<JsonApiError> errors) => error(400, errors);

  void errorConflict(Iterable<JsonApiError> errors) => error(409, errors);

  void error(int status, Iterable<JsonApiError> errors) =>
      response = ErrorResponse(status, errors);

  Future<void> call(JsonApiController controller, Object body);
}

class FetchCollection extends JsonApiRequest implements FetchCollectionRequest {
  final CollectionTarget target;

  FetchCollection(this.target);

  void sendCollection(Collection<Resource> resources) =>
      response = CollectionResponse(resources);

  @override
  Future<void> call(JsonApiController controller, Object body) =>
      controller.fetchCollection(this);
}

class CreateResource extends JsonApiRequest implements CreateResourceRequest {
  final CollectionTarget target;

  CreateResource(this.target);

  void sendCreated(Resource resource) =>
      response = ResourceCreatedResponse(resource);

  void sendNoContent() => response = NoContentResponse();

  void sendAccepted(Resource job) => response = AcceptedResponse(job);

  @override
  Future<void> call(JsonApiController controller, Object body) {
    final resource = JsonApiParser().parseResourceData(body).toResource();
    return controller.createResource(this, resource);
  }
}

class UpdateResource {}

class DeleteResource {}

class FetchResource {}

/*
    RESPONSE
 */

abstract class JsonApiResponse {
  ServerResponse build(DocumentBuilder builder);
}

class ErrorResponse extends JsonApiResponse {
  final int status;
  final Iterable<JsonApiError> errors;

  ErrorResponse(this.status, this.errors);

  @override
  ServerResponse build(DocumentBuilder builder) =>
      ServerResponse(status, builder.errorDocument(errors));
}

class CollectionResponse extends JsonApiResponse {
  final Collection<Resource> resources;

  CollectionResponse(this.resources);

  @override
  ServerResponse build(DocumentBuilder builder) => builder.collectionDocument(resources)

}

class ResourceCreatedResponse extends JsonApiResponse {
  final Resource resource;

  ResourceCreatedResponse(this.resource);

  @override
  Future<void> send(Responder responder) => responder.sendCreated(resource);
}

class NoContentResponse extends JsonApiResponse {
  @override
  Future<void> send(Responder responder) => responder.sendNoContent();
}

class AcceptedResponse extends JsonApiResponse {
  final Resource job;

  AcceptedResponse(this.job);

  @override
  Future<void> send(Responder responder) => responder.sendAccepted(job);
}
