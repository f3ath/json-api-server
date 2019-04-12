import 'dart:async';

import 'package:json_api_document/json_api_document.dart';
import 'package:json_api_server/json_api_server.dart';

abstract class Controller {
  Future<void> fetchCollection(
      FetchCollection request, Map<String, List<String>> query);
}

class ControllerException implements Exception {
  final int status;
  final List<JsonApiError> errors;

  ControllerException(this.status, this.errors);
}
