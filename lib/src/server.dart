import 'dart:convert';
import 'dart:io';

import 'package:json_api_server/src/controller.dart';
import 'package:json_api_server/src/document_builder.dart';
import 'package:json_api_server/src/routing.dart';

class Server {
  final Routing routing;
  final Controller controller;
  final DocumentBuilder builder;

  Server(this.routing, this.controller) : builder = DocumentBuilder(routing);

  Future process(HttpRequest http) async {
    final request =
        routing.getTarget(http.requestedUri).getRequest(http.method);

    final body = await http.transform(utf8.decoder).join();
    await request.call(controller, http.requestedUri.queryParametersAll,
        body.isNotEmpty ? json.decode(body) : null);

    http.response.statusCode = request.response.status;
    request.response.getHeaders(routing).forEach(http.response.headers.add);
    final doc = request.response.getDocument(builder, http.requestedUri);
    if (doc != null) {
      http.response.write(json.encode(doc));
    }
    return http.response.close();
  }
}
