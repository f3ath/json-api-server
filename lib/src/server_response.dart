import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:json_api_server/src/nullable.dart';

class ServerResponse {
  final int status;
  final headers = <String, String>{};
  final String body;

  ServerResponse(this.status, {Map<String, String> headers, Object payload})
      : body = nullable(json.encode)(payload) {
    this.headers.addAll(headers ?? {});
  }

  Future send(HttpResponse response) {
    response.statusCode = status;
    headers.forEach(response.headers.add);
    response.write(body);
    return response.close();
  }
}
