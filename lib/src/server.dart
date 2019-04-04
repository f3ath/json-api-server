import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:json_api_document/json_api_document.dart';
import 'package:json_api_document/parser.dart';
import 'package:json_api_server/src/controller.dart';
import 'package:json_api_server/src/document_builder.dart';
import 'package:json_api_server/src/request_target.dart';
import 'package:json_api_server/src/response.dart';
import 'package:json_api_server/src/routing.dart';

class JsonApiServer {
  final Routing routing;
  final JsonApiController controller;
  final DocumentBuilder docBuilder;

  JsonApiServer(this.routing, this.controller, this.docBuilder);

  Future<void> process(HttpRequest request) async {
    const parser = const JsonApiParser();
    final target = routing.getTarget(request.requestedUri);
    if (target == null) {
      request.response.statusCode = 404;
      return request.response.close();
    }
    final bodyString = await request.transform(utf8.decoder).join();
    final body = bodyString.isNotEmpty ? json.decode(bodyString) : null;

    final responseBuilder = ResponseBuilder(docBuilder, routing);

    if (target is CollectionTarget) {
      final rs = target.createResponse(request, responseBuilder);
      switch (request.method) {
        case 'GET':
          return controller.fetchCollection(
              ControllerRequest(request, target), rs);
        case 'POST':
          return controller.createResource(
              ControllerRequest(request, target,
                  payload: parser.parseResourceData(body).toResource()),
              rs);
      }
    } else if (target is ResourceTarget) {
      final rs = target.createResponse(request, responseBuilder);
      switch (request.method) {
        case 'GET':
          return controller.fetchResource(
              ControllerRequest(request, target), rs);
        case 'DELETE':
          return controller.deleteResource(
              ControllerRequest(request, target), rs);
        case 'PATCH':
          return controller.updateResource(
              ControllerRequest(request, target,
                  payload: parser.parseResourceData(body).toResource()),
              rs);
      }
    } else if (target is RelatedTarget && request.method == 'GET') {
      return controller.fetchRelated(ControllerRequest(request, target),
          target.createResponse(request, responseBuilder));
    } else if (target is RelationshipTarget) {
      final rs = target.createResponse(request, responseBuilder);
      switch (request.method) {
        case 'GET':
          return controller.fetchRelationship(
              ControllerRequest(request, target), rs);
        case 'PATCH':
          final relationship = parser.parseRelationship(body);
          if (relationship is ToOne) {
            return controller.replaceToOne(
                ControllerRequest(request, target,
                    payload: relationship.toIdentifier()),
                rs);
          }
          if (relationship is ToMany) {
            return controller.replaceToMany(
                ControllerRequest(request, target,
                    payload: relationship.toIdentifiers()),
                rs);
          }
          break;
        case 'POST':
          final relationship = parser.parseRelationship(body);
          if (relationship is ToMany) {
            return controller.addToMany(
                ControllerRequest(request, target,
                    payload: relationship.toIdentifiers()),
                rs);
          }
      }
    }
    throw 'Unable to create request for ${target}:${request.method}';
  }
}
