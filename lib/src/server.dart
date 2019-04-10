import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:json_api_document/json_api_document.dart';
import 'package:json_api_document/parser.dart';
import 'package:json_api_server/src/controller.dart';
import 'package:json_api_server/src/document_builder.dart';
import 'package:json_api_server/src/request.dart';
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

    if (target is CollectionTarget) {
      final rq = target.getControllerRequest(request.method);

      /// AAA stuff should go here
      await rq.call(controller, body);
      return rq.response.build(docBuilder).send(request.response);


    } else if (target is ResourceTarget) {
      final rs = ResourceResponse(target, request, docBuilder, routing);
      switch (request.method) {
        case 'GET':
          return controller.fetchResource(
              OldControllerRequest(request, target), rs);
        case 'DELETE':
          return controller.deleteResource(
              OldControllerRequest(request, target), rs);
        case 'PATCH':
          return controller.updateResource(
              OldControllerRequest(request, target,
                  payload: parser.parseResourceData(body).toResource()),
              rs);
      }
    } else if (target is RelatedTarget && request.method == 'GET') {
      return controller.fetchRelated(OldControllerRequest(request, target),
          RelatedResponse(target, request, docBuilder, routing));
    } else if (target is RelationshipTarget) {
      final rs = RelationshipResponse(target, request, docBuilder, routing);
      switch (request.method) {
        case 'GET':
          return controller.fetchRelationship(
              OldControllerRequest(request, target), rs);
        case 'PATCH':
          final relationship = parser.parseRelationship(body);
          if (relationship is ToOne) {
            return controller.replaceToOne(
                OldControllerRequest(request, target,
                    payload: relationship.toIdentifier()),
                rs);
          }
          if (relationship is ToMany) {
            return controller.replaceToMany(
                OldControllerRequest(request, target,
                    payload: relationship.toIdentifiers()),
                rs);
          }
          break;
        case 'POST':
          final relationship = parser.parseRelationship(body);
          if (relationship is ToMany) {
            return controller.addToMany(
                OldControllerRequest(request, target,
                    payload: relationship.toIdentifiers()),
                rs);
          }
      }
    }
    throw 'Unable to create request for ${target}:${request.method}';
  }
}
