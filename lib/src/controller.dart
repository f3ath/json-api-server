import 'dart:async';

import 'package:json_api_document/json_api_document.dart';
import 'package:json_api_server/src/request.dart';

abstract class Controller {
  FutureOr<void> fetchCollection(
      FetchCollection request, Map<String, List<String>> query);

  FutureOr<void> fetchResource(
      FetchResource request, Map<String, List<String>> query);

  FutureOr<void> fetchRelated(
      FetchRelated request, Map<String, List<String>> query);

  FutureOr<void> fetchRelationship(
      FetchRelationship request, Map<String, List<String>> query);

  FutureOr<void> deleteResource(DeleteResource request);

  FutureOr<void> createResource(CreateResource request, Resource resource);

  FutureOr<void> updateResource(UpdateResource request, Resource resource);

  FutureOr<void> replaceToOne(
      UpdateRelationship request, Identifier identifier);

  FutureOr<void> replaceToMany(
      UpdateRelationship request, List<Identifier> identifiers);

  FutureOr<void> addToMany(AddToMany request, List<Identifier> identifiers);
}
