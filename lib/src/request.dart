import 'dart:async';

import 'package:json_api_document/json_api_document.dart';
import 'package:json_api_server/json_api_server.dart';
import 'package:json_api_server/src/controller.dart';
import 'package:json_api_server/src/request_target.dart';
import 'package:json_api_server/src/response.dart';

abstract class ControllerRequest {
  Future<Response> call(Controller controller, ServerRequest request);
}

class FetchCollection implements ControllerRequest {
  final CollectionTarget target;
  Response _response = NotFound([]);

  FetchCollection(this.target);

  @override
  Future<Response> call(Controller controller, ServerRequest request) async {
    await controller.fetchCollection(this, request.uri.queryParametersAll);
    return _response;
  }

  sendCollection(Collection<Resource> collection,
      {Iterable<Resource> included = const{}}) {
    _response = CollectionResponse(collection, included:included);
  }
}
