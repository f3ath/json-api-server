import 'dart:convert';
import 'dart:io';

class ServerRequest {
  final String body;
  final String method;
  final Uri uri;

  ServerRequest(this.method, this.uri, {this.body = ''});

  static Future<ServerRequest> fromHttp(HttpRequest request) async =>
      ServerRequest(request.method, request.requestedUri,
          body: await request.transform(utf8.decoder).join());
}
