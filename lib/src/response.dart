import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:json_api_document/json_api_document.dart';
import 'package:json_api_server/src/collection.dart';
import 'package:json_api_server/src/controller.dart';
import 'package:json_api_server/src/document_builder.dart';
import 'package:json_api_server/src/request_target.dart';
import 'package:json_api_server/src/routing.dart';

class ResponseBuilder {
  final Routing routing;
  final DocumentBuilder docBuilder;

  ResponseBuilder(this.docBuilder, this.routing);

  collection(CollectionTarget target, HttpRequest request) =>
      CollectionResponse(target, request, docBuilder, routing);

  resource(ResourceTarget target, HttpRequest request) =>
      ResourceResponse(target, request, docBuilder, routing);

  relationship(RelationshipTarget target, HttpRequest request) =>
      RelationshipResponse(target, request, docBuilder, routing);

  related(RelatedTarget target, HttpRequest request) =>
      RelatedResponse(target, request, docBuilder, routing);
}

class Responder {
  final HttpRequest httpRequest;
  final commonHeaders = <String, String>{'Access-Control-Allow-Origin': '*'};
  final DocumentBuilder docBuilder;
  final Routing routing;

  Responder(this.httpRequest, this.docBuilder, this.routing);

  Future<void> sendSeeOther(Resource resource) {
    return write(303, headers: {
      'Location': routing.resource(resource.type, resource.id).toString()
    });
  }

  Future write(int status,
      {Map<String, String> headers = const {}, Document document}) {
    httpRequest.response.statusCode = status;
    <String, String>{}
      ..addAll(commonHeaders)
      ..addAll(headers)
      ..forEach(httpRequest.response.headers.add);

    if (document != null) {
      httpRequest.response.write(json.encode(document));
    }
    return httpRequest.response.close();
  }

  Future error(int status, Iterable<JsonApiError> errors,
          {Map<String, String> headers = const {}}) =>
      write(status, headers: headers, document: docBuilder.error(errors));
}

abstract class Response<T extends RequestTarget> {
  final headers = <String, String>{};
  final HttpRequest request;

  final DocumentBuilder docBuilder;

  final T target;

  Responder r;

  Response(this.target, this.request, this.docBuilder, Routing routing) {
    r = Responder(request, docBuilder, routing);
  }

  Future<void> sendNoContent() => r.write(204);

  Future<void> sendAccepted(Resource resource) {
    final doc = docBuilder.resource(resource,
        ResourceTarget(resource.type, resource.id), request.requestedUri);
    return r.write(202,
        headers: {
          'Content-Location': doc.data.resourceObject.self.uri.toString()
        },
        document: doc);
  }

  Future<void> errorBadRequest(Iterable<JsonApiError> errors) =>
      r.error(400, errors);

  Future<void> errorForbidden(Iterable<JsonApiError> errors) =>
      r.error(403, errors);

  Future<void> errorNotFound([Iterable<JsonApiError> errors]) =>
      r.error(404, errors);

  Future<void> errorConflict(Iterable<JsonApiError> errors) =>
      r.error(409, errors);

  Future<void> sendMeta(Map<String, Object> meta) =>
      r.write(200, document: Document.empty(meta));
}

class CollectionResponse extends Response<CollectionTarget>
    implements FetchCollectionResponse, CreateResourceResponse {
  CollectionResponse(CollectionTarget target, HttpRequest request,
      DocumentBuilder docBuilder, Routing routing)
      : super(target, request, docBuilder, routing);

  Future<void> sendCollection(Collection<Resource> resources) => r.write(200,
      document: docBuilder.collection(resources, target, request.requestedUri));

  Future<void> sendCreated(Resource resource) {
    final doc = docBuilder.resource(resource,
        ResourceTarget(resource.type, resource.id), request.requestedUri);
    return r.write(201,
        headers: {'Location': doc.data.resourceObject.self.uri.toString()},
        document: doc);
  }
}

class RelatedResponse extends Response<RelatedTarget>
    implements FetchRelatedResponse {
  RelatedResponse(RelatedTarget target, HttpRequest request,
      DocumentBuilder docBuilder, Routing routing)
      : super(target, request, docBuilder, routing);

  Future<void> sendCollection(Collection<Resource> resources) => r.write(200,
      document: docBuilder.relatedCollection(
          resources, target, request.requestedUri));

  Future<void> sendResource(Resource resource) => r.write(200,
      document:
          docBuilder.relatedResource(resource, target, request.requestedUri));
}

class RelationshipResponse extends Response<RelationshipTarget>
    implements
        FetchRelationshipResponse,
        ReplaceToOneResponse,
        ReplaceToManyResponse,
        AddToManyResponse {
  RelationshipResponse(RelationshipTarget target, HttpRequest request,
      DocumentBuilder docBuilder, Routing routing)
      : super(target, request, docBuilder, routing);

  Future<void> sendToMany(Iterable<Identifier> collection) => r.write(200,
      document: docBuilder.toMany(collection, target, request.requestedUri));

  Future<void> sendToOne(Identifier id) => r.write(200,
      document: docBuilder.toOne(id, target, request.requestedUri));
}

class ResourceResponse extends Response<ResourceTarget>
    implements
        FetchResourceResponse,
        DeleteResourceResponse,
        UpdateResourceResponse {
  ResourceResponse(ResourceTarget target, HttpRequest request,
      DocumentBuilder docBuilder, Routing routing)
      : super(target, request, docBuilder, routing);

  Future<void> sendResource(Resource resource, {Iterable<Resource> included}) =>
      _resource(resource, included: included);

  Future<void> sendUpdated(Resource resource) => _resource(resource);

  @override
  Future<void> sendSeeOther(Resource resource) => r.sendSeeOther(resource);

  Future _resource(Resource resource, {Iterable<Resource> included}) => r.write(
      200,
      document: docBuilder.resource(resource, target, request.requestedUri,
          included: included));
}
