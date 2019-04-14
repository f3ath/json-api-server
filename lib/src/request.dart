import 'dart:async';

import 'package:json_api_document/json_api_document.dart';
import 'package:json_api_document/parser.dart';
import 'package:json_api_server/json_api_server.dart';
import 'package:json_api_server/src/controller.dart';
import 'package:json_api_server/src/request_target.dart';
import 'package:json_api_server/src/response.dart';

abstract class Request {
  Response _response = ErrorResponse.notImplemented([]);

  Response get response => _response;

  FutureOr<void> call(
      Controller controller, Map<String, List<String>> query, Object payload);
}

class FetchCollection extends Request with _Errors {
  final CollectionTarget target;

  FetchCollection(this.target);

  @override
  FutureOr<Response> call(Controller controller,
          Map<String, List<String>> query, Object payload) =>
      controller.fetchCollection(this, query);

  void sendCollection(Collection<Resource> collection,
      {Iterable<Resource> included}) {
    _response = CollectionResponse(collection, included: included);
  }
}

class FetchResource extends Request with _Errors {
  final ResourceTarget target;

  FetchResource(this.target);

  @override
  FutureOr<Response> call(Controller controller,
          Map<String, List<String>> query, Object payload) =>
      controller.fetchResource(this, query);

  void sendResource(Resource resource, {Iterable<Resource> included}) {
    _response = ResourceResponse(resource, included: included);
  }

  void sendSeeOther(Resource resource) {
    _response = SeeOther(resource);
  }
}

class FetchRelated extends Request with _Errors {
  final RelatedTarget target;

  FetchRelated(this.target);

  @override
  FutureOr<Response> call(Controller controller,
          Map<String, List<String>> query, Object payload) =>
      controller.fetchRelated(this, query);

  void sendResource(Resource resource) {
    _response = RelatedResourceResponse(resource);
  }

  void sendCollection(Collection<Resource> collection) {
    _response = RelatedCollectionResponse(collection);
  }
}

class FetchRelationship extends Request with _Errors {
  final RelationshipTarget target;

  FetchRelationship(this.target);

  @override
  FutureOr<void> call(Controller controller, Map<String, List<String>> query,
          Object payload) =>
      controller.fetchRelationship(this, query);

  void sendToOne(Identifier identifier) {
    _response = ToOneResponse(target, identifier);
  }

  void sendToMany(List<Identifier> collection) {
    _response = ToManyResponse(target, collection);
  }
}

class DeleteResource extends Request with _Errors {
  final ResourceTarget target;

  DeleteResource(this.target);

  @override
  FutureOr<void> call(Controller controller, Map<String, List<String>> query,
          Object payload) =>
      controller.deleteResource(this);

  void sendNoContent() {
    _response = NoContent();
  }

  void sendMeta(Map<String, Object> map) {
    _response = MetaResponse(map);
  }
}

class UpdateResource extends Request with _Errors {
  final ResourceTarget target;

  UpdateResource(this.target);

  @override
  FutureOr<void> call(Controller controller, Map<String, List<String>> query,
          Object payload) =>
      controller.updateResource(
          this,
          const JsonApiParser()
              .parseResourceDocument(payload)
              .data
              .resourceObject
              .toResource());

  void sendNoContent() {
    _response = NoContent();
  }

  void sendUpdated(Resource resource) {
    _response = ResourceUpdated(resource);
  }
}

class CreateResource extends Request with _Errors {
  final CollectionTarget target;

  CreateResource(this.target);

  @override
  FutureOr<void> call(Controller controller, Map<String, List<String>> query,
          Object payload) =>
      controller.createResource(
          this,
          const JsonApiParser()
              .parseResourceDocument(payload)
              .data
              .resourceObject
              .toResource());

  void sendNoContent() {
    _response = NoContent();
  }

  void sendAccepted(Resource resource) {
    _response = Accepted(resource);
  }

  void sendCreated(Resource resource) {
    _response = ResourceCreated(resource);
  }
}

class UpdateRelationship extends Request with _Errors {
  final RelationshipTarget target;

  UpdateRelationship(this.target);

  @override
  FutureOr<void> call(Controller controller, Map<String, List<String>> query,
      Object payload) async {
    final rel = const JsonApiParser().parseRelationship(payload);
    if (rel is ToOne) {
      controller.replaceToOne(this, rel.toIdentifier());
    }
    if (rel is ToMany) {
      controller.replaceToMany(this, rel.toIdentifiers());
    }
  }

  void sendNoContent() {
    _response = NoContent();
  }
}

class AddToMany extends Request with _Errors {
  final RelationshipTarget target;

  AddToMany(this.target);

  @override
  FutureOr<void> call(Controller controller, Map<String, List<String>> query,
      Object payload) async {
    final rel = const JsonApiParser().parseRelationship(payload);
    if (rel is ToMany) {
      controller.addToMany(this, rel.toIdentifiers());
    }
  }

  void sendToMany(List<Identifier> identifiers) {
    _response = ToManyResponse(target, identifiers);
  }
}

class InvalidRequest extends Request {
  InvalidRequest(ErrorResponse response) {
    _response = response;
  }

  @override
  void call(
      Controller controller, Map<String, List<String>> query, Object payload) {}
}

mixin _Errors {
  Response _response;

  void errorNotFound(List<JsonApiError> errors) {
    _response = ErrorResponse.notFound(errors);
  }

  void errorConflict(List<JsonApiError> errors) {
    _response = ErrorResponse.conflict(errors);
  }

  void error(int status, List<JsonApiError> errors) {
    _response = ErrorResponse(status, errors);
  }
}
