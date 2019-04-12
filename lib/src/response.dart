import 'package:json_api_document/json_api_document.dart';
import 'package:json_api_server/json_api_server.dart';

abstract class Response {
  ServerResponse toServerResponse(Uri uri, DocumentBuilder doc);
}

class CollectionResponse implements Response {
  final Collection<Resource> collection;
  final Iterable<Resource> included;

  CollectionResponse(this.collection, {this.included = const []});

  @override
  ServerResponse toServerResponse(Uri uri, DocumentBuilder doc) =>
      ServerResponse(200,
          payload: doc.collectionDocument(collection, uri, included: included));
}

class NotFound implements Response {
  final Iterable<JsonApiError> errors;

  const NotFound(this.errors);

  @override
  ServerResponse toServerResponse(Uri uri, DocumentBuilder doc) =>
      ServerResponse(404, payload: doc.errorDocument(errors));
}
