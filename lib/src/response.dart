import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:json_api_document/json_api_document.dart';
import 'package:json_api_server/src/collection.dart';
import 'package:json_api_server/src/controller.dart';
import 'package:json_api_server/src/document_builder.dart';
import 'package:json_api_server/src/request.dart';
import 'package:json_api_server/src/routing.dart';

class ServerResponse {
  final Document document;
  final int status;
  final headers = <String, String>{'Content-Type': 'application/vnd.api+json'};

  ServerResponse(this.status, this.document, {Map<String, String> headers}) {
    this.headers.addAll(headers ?? {});
  }

  ServerResponse.empty(int status, {Map<String, String> headers})
      : this(status, null, headers: headers);

  Future<void> send(HttpResponse http) async {
    headers.forEach(http.headers.add);
    if (document != null) {
      http.write(json.encode(document));
    }
    return http.close();
  }
}

class ResponseBuilder {
  
}

class Responder {
  final HttpResponse http;
  final Uri self;
  final commonHeaders = <String, String>{'Access-Control-Allow-Origin': '*'};
  final DocumentBuilder docBuilder;
  final Routing routing;

  Responder(this.self, this.http, this.docBuilder, this.routing);

  Future<void> sendSeeOther(Resource resource) {
    return write(303, headers: {
      'Location': routing.resource(resource.type, resource.id).toString()
    });
  }

  Future<void> write(int status,
      {Map<String, String> headers = const {}, Document document}) {
    http.statusCode = status;
    <String, String>{}
      ..addAll(commonHeaders)
      ..addAll(headers)
      ..forEach(http.headers.add);

    if (document != null) {
      http.write(json.encode(document));
    }
    return http.close();
  }

  Future<void> error(int status, Iterable<JsonApiError> errors,
          {Map<String, String> headers = const {}}) =>
      write(status, headers: headers, document: docBuilder.errorDocument(errors));

  Future<void> sendCreated(Resource resource) {
    final doc = docBuilder.resourceDocument(resource, self);
    return write(201,
        headers: {'Location': doc.data.resourceObject.self.uri.toString()},
        document: doc);
  }

  Future<void> sendAccepted(Resource job) {
    final doc = docBuilder.resourceDocument(job, self);
    return write(202,
        headers: {
          'Content-Location': doc.data.resourceObject.self.uri.toString()
        },
        document: doc);
  }

  Future<void> sendNoContent() => write(204);

  Future<void> sendCollection(Collection<Resource> resources) =>
      write(200, document: docBuilder.collectionDocument(resources, self));
}

abstract class Response<T extends RequestTarget> {
  final headers = <String, String>{};
  final HttpRequest request;

  final DocumentBuilder docBuilder;

  final T target;

  Responder r;

  Response(this.target, this.request, this.docBuilder, Routing routing) {
    r = Responder(request.requestedUri, request.response, docBuilder, routing);
  }

  Future<void> sendNoContent() => r.write(204);

  Future<void> sendAccepted(Resource resource) {
    final doc = docBuilder.resourceDocument(resource, request.requestedUri);
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

class RelatedResponse extends Response<RelatedTarget>
    implements FetchRelatedResponse {
  RelatedResponse(RelatedTarget target, HttpRequest request,
      DocumentBuilder docBuilder, Routing routing)
      : super(target, request, docBuilder, routing);

  Future<void> sendCollection(Collection<Resource> resources) => r.write(200,
      document: docBuilder.relatedCollectionDocument(resources, request.requestedUri));

  Future<void> sendResource(Resource resource) => r.write(200,
      document:
          docBuilder.relatedResourceDocument(resource, target, request.requestedUri));
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
      document: docBuilder.toManyDocument(collection, target, request.requestedUri));

  Future<void> sendToOne(Identifier id) => r.write(200,
      document: docBuilder.toOneDocument(id, target, request.requestedUri));
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
      document: docBuilder.resourceDocument(resource, request.requestedUri,
          included: included));
}
