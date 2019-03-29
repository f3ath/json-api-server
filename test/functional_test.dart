import 'dart:async';
import 'dart:io';

import 'package:json_api_document/json_api_document.dart';
import 'package:json_api_document/src/identifier.dart';
import 'package:json_api_document/src/resource.dart';
import 'package:json_api_server/json_api_server.dart';
import 'package:test/test.dart';

void main() {
  HttpServer http;

  setUp(() async {
    http = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  });

  group('Functional test', () {});
}

//createServer(int port) async {
//  final urlDesign = StandardURLDesign(Uri.parse('http://localhost:$port'));
//
//  final controller = TestController();
//  final builder = StandardDocumentBuilder(urlDesign);
//  final jsonApiServer = JsonApiServer(urlDesign, controller, builder);
//
//  final httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
//
//  httpServer.forEach(jsonApiServer.process);
//
//  return httpServer;
//}

class TestController implements JsonApiController {
  @override
  Future<void> addToMany(
      ControllerRequest<RelationshipTarget, Iterable<Identifier>> request,
      AddToManyResponse response) {
    return _errorBadRequest(response);
  }

  @override
  Future<void> createResource(
      ControllerRequest<CollectionTarget, Resource> request,
      CreateResourceResponse response) {
    return _errorBadRequest(response);
  }

  @override
  Future<void> deleteResource(ControllerRequest<ResourceTarget, void> request,
      DeleteResourceResponse response) {
    return _errorBadRequest(response);
  }

  @override
  Future<void> fetchCollection(
      ControllerRequest<CollectionTarget, void> request,
      FetchCollectionResponse response) {
    return _errorBadRequest(response);
  }

  @override
  Future<void> fetchRelated(ControllerRequest<RelatedTarget, void> request,
      FetchRelatedResponse response) {
    return _errorBadRequest(response);
  }

  @override
  Future<void> fetchRelationship(
      ControllerRequest<RelationshipTarget, void> request,
      FetchRelationshipResponse response) {
    return _errorBadRequest(response);
  }

  @override
  Future<void> fetchResource(ControllerRequest<ResourceTarget, void> request,
      FetchResourceResponse response) {
    return _errorBadRequest(response);
  }

  @override
  Future<void> replaceToMany(
      ControllerRequest<RelationshipTarget, Iterable<Identifier>> request,
      ReplaceToManyResponse response) {
    return _errorBadRequest(response);
  }

  @override
  Future<void> replaceToOne(
      ControllerRequest<RelationshipTarget, Identifier> request,
      ReplaceToOneResponse response) {
    return _errorBadRequest(response);
  }

  @override
  Future<void> updateResource(
      ControllerRequest<ResourceTarget, Resource> request,
      UpdateResourceResponse response) {
    return _errorBadRequest(response);
  }

  Future<void> _errorBadRequest(ControllerResponse response) =>
      response.errorBadRequest([JsonApiError(detail: 'Not implemented')]);
}
