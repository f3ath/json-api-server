import 'dart:async';
import 'dart:io';

import 'package:json_api_document/json_api_document.dart';
import 'package:json_api_server/src/collection.dart';
import 'package:json_api_server/src/request.dart';

abstract class JsonApiController {
  Future<void> fetchCollection(FetchCollectionRequest request);

  Future<void> fetchRelated(OldControllerRequest<RelatedTarget, void> request,
      FetchRelatedResponse response);

  Future<void> fetchResource(OldControllerRequest<ResourceTarget, void> request,
      FetchResourceResponse response);

  Future<void> fetchRelationship(
      OldControllerRequest<RelationshipTarget, void> request,
      FetchRelationshipResponse response);

  Future<void> deleteResource(
      OldControllerRequest<ResourceTarget, void> request,
      DeleteResourceResponse response);

  Future<void> createResource(CreateResourceRequest request, Resource resource);

  Future<void> updateResource(
      OldControllerRequest<ResourceTarget, Resource> request,
      UpdateResourceResponse response);

  Future<void> replaceToOne(
      OldControllerRequest<RelationshipTarget, Identifier> request,
      ReplaceToOneResponse response);

  Future<void> replaceToMany(
      OldControllerRequest<RelationshipTarget, Iterable<Identifier>> request,
      ReplaceToManyResponse response);

  Future<void> addToMany(
      OldControllerRequest<RelationshipTarget, Iterable<Identifier>> request,
      AddToManyResponse response);
}

abstract class FetchCollectionRequest {
  CollectionTarget get target;

  void sendCollection(Collection<Resource> resources);

  void error(int status, Iterable<JsonApiError> errors);

  void errorNotFound(Iterable<JsonApiError> errors);
}

abstract class CreateResourceRequest {
  CollectionTarget get target;

  void sendCreated(Resource resource);

  void sendAccepted(Resource asyncJob);

  void sendNoContent();

  void error(int status, Iterable<JsonApiError> errors);
}

class OldControllerRequest<T extends RequestTarget, P> {
  final HttpRequest _request;
  final P payload;

  final T target;

  OldControllerRequest(this._request, this.target, {this.payload});

  Uri get uri => _request.requestedUri;

  HttpHeaders get headers => _request.headers;
}

abstract class ControllerResponse {
  /// Headers to be sent in the response
  final headers = <String, String>{};

  Future<void> errorNotFound(Iterable<JsonApiError> errors);

  Future<void> errorBadRequest(Iterable<JsonApiError> errors);
}

abstract class CreateResourceResponse extends ControllerResponse {
  Future<void> sendCreated(Resource resource);

  Future<void> sendNoContent();

  Future<void> errorConflict(Iterable<JsonApiError> errors);

  Future<void> sendAccepted(Resource asyncJob);
}

abstract class FetchResourceResponse extends ControllerResponse {
  /// https://jsonapi.org/recommendations/#asynchronous-processing
  Future<void> sendSeeOther(Resource resource);

  Future<void> sendResource(Resource resource, {Iterable<Resource> included});
}

abstract class DeleteResourceResponse extends ControllerResponse {
  Future<void> sendNoContent();

  Future<void> sendMeta(Map<String, Object> meta);
}

abstract class UpdateResourceResponse extends ControllerResponse {
  Future<void> sendUpdated(Resource resource);

  Future<void> sendNoContent();

  Future<void> sendAccepted(Resource asyncJob);

  Future<void> errorConflict(Iterable<JsonApiError> errors);

  Future<void> errorForbidden(Iterable<JsonApiError> errors);
}

abstract class FetchRelationshipResponse extends ControllerResponse {
  Future<void> sendToMany(Iterable<Identifier> collection);

  Future<void> sendToOne(Identifier id);
}

abstract class ReplaceToOneResponse extends ControllerResponse {
  Future<void> sendNoContent();

  Future<void> sendAccepted(Resource asyncJob);

  Future<void> sendToMany(Iterable<Identifier> collection);

  Future<void> sendToOne(Identifier id);
}

abstract class ReplaceToManyResponse extends ControllerResponse {
  Future<void> sendNoContent();

  Future<void> sendAccepted(Resource asyncJob);

  Future<void> sendToMany(Iterable<Identifier> collection);

  Future<void> sendToOne(Identifier id);
}

abstract class AddToManyResponse extends ControllerResponse {
  Future<void> sendAccepted(Resource asyncJob);

  Future<void> sendToMany(Iterable<Identifier> collection);
}

abstract class FetchRelatedResponse extends ControllerResponse {
  Future<void> sendCollection(Collection<Resource> resources);

  Future<void> sendResource(Resource resource);
}
