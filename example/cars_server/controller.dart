import 'dart:async';
import 'dart:math';

import 'package:json_api_document/json_api_document.dart';
import 'package:json_api_server/json_api_server.dart';
import 'package:uuid/uuid.dart';

import 'dao.dart';
import 'job_queue.dart';

class CarsController implements Controller {
  final Map<String, DAO> _dao;

  CarsController(this._dao);

  @override
  void fetchCollection(
      FetchCollection request, Map<String, List<String>> query) {
    if (!_dao.containsKey(request.target.type)) {
      request.errorNotFound([JsonApiError(detail: 'Unknown resource type')]);
      return;
    }
    final page = NumberedPage.fromQueryParameters(query,
        total: _dao[request.target.type].length);
    request.sendCollection(Collection(
        _dao[request.target.type]
            .fetchCollection(offset: page.offset)
            .map(_dao[request.target.type].toResource),
        page: page));
  }

  @override
  void fetchRelated(FetchRelated request, Map<String, List<String>> query) {
    if (!_dao.containsKey(request.target.type)) {
      request.errorNotFound([JsonApiError(detail: 'Unknown resource type')]);
      return;
    }
    final res =
        _dao[request.target.type].fetchByIdAsResource(request.target.id);
    if (res == null) {
      request.errorNotFound([JsonApiError(detail: 'Resource not found')]);
      return;
    }

    if (res.toOne.containsKey(request.target.relationship)) {
      final id = res.toOne[request.target.relationship];
      final resource = _dao[id.type].fetchByIdAsResource(id.id);
      request.sendResource(resource);
      return;
    }

    if (res.toMany.containsKey(request.target.relationship)) {
      final pageSize = 2;
      final totalPages =
          max(0, res.toMany[request.target.relationship].length - 1) ~/
                  pageSize +
              1;
      final page = NumberedPage.fromQueryParameters(query, total: totalPages);
      final resources = res.toMany[request.target.relationship]
          .skip(page.offset * pageSize)
          .take(pageSize)
          .map((id) => _dao[id.type].fetchByIdAsResource(id.id));
      request.sendCollection(Collection(resources, page: page));
      return;
    }
    request.errorNotFound([JsonApiError(detail: 'Relationship not found')]);
  }

  @override
  void fetchResource(FetchResource request, Map<String, List<String>> query) {
    if (!_dao.containsKey(request.target.type)) {
      request.errorNotFound([JsonApiError(detail: 'Unknown resource type')]);
      return;
    }
    final obj = _dao[request.target.type].fetchById(request.target.id);

    if (obj == null) {
      request.errorNotFound([JsonApiError(detail: 'Resource not found')]);
      return;
    }
    if (obj is Job && obj.resource != null) {
      request.sendSeeOther(obj.resource);
      return;
    }

    final fetchById = (Identifier _) => _dao[_.type].fetchByIdAsResource(_.id);

    final res = _dao[request.target.type].toResource(obj);
    final children = res.toOne.values
        .map(fetchById)
        .followedBy(res.toMany.values.expand((_) => _.map(fetchById)));

    request.sendResource(res, included: children);
  }

  @override
  void fetchRelationship(
      FetchRelationship request, Map<String, List<String>> query) {
    if (!_dao.containsKey(request.target.type)) {
      request.errorNotFound([JsonApiError(detail: 'Unknown resource type')]);
      return;
    }
    final res =
        _dao[request.target.type].fetchByIdAsResource(request.target.id);
    if (res == null) {
      request.errorNotFound([JsonApiError(detail: 'Resource not found')]);
      return;
    }

    if (res.toOne.containsKey(request.target.relationship)) {
      final id = res.toOne[request.target.relationship];
      request.sendToOne(id);
      return;
    }

    if (res.toMany.containsKey(request.target.relationship)) {
      final ids = res.toMany[request.target.relationship];
      request.sendToMany(ids);
      return;
    }
    request.errorNotFound([JsonApiError(detail: 'Relationship not found')]);
  }

  @override
  void deleteResource(DeleteResource request) {
    if (!_dao.containsKey(request.target.type)) {
      request.errorNotFound([JsonApiError(detail: 'Unknown resource type')]);
      return;
    }
    final res =
        _dao[request.target.type].fetchByIdAsResource(request.target.id);
    if (res == null) {
      request.errorNotFound([JsonApiError(detail: 'Resource not found')]);
      return;
    }
    final dependenciesCount =
        _dao[request.target.type].deleteById(request.target.id);
    if (dependenciesCount == 0) {
      request.sendNoContent();
      return;
    }
    request.sendMeta({'dependenciesCount': dependenciesCount});
  }

  @override
  void createResource(CreateResource request, Resource resource) {
    if (!_dao.containsKey(request.target.type)) {
      request.errorNotFound([JsonApiError(detail: 'Unknown resource type')]);
      return;
    }
    if (request.target.type != resource.type) {
      request.errorConflict([JsonApiError(detail: 'Incompatible type')]);
      return;
    }

    if (resource.hasId) {
      if (_dao[request.target.type].fetchById(resource.id) != null) {
        request
            .errorConflict([JsonApiError(detail: 'Resource already exists')]);
        return;
      }
      final created = _dao[request.target.type].create(resource);
      _dao[request.target.type].insert(created);
      request.sendNoContent();
      return;
    }

    final created = _dao[request.target.type].create(Resource(
        resource.type, Uuid().v4(),
        attributes: resource.attributes,
        toMany: resource.toMany,
        toOne: resource.toOne));

    if (request.target.type == 'models') {
      // Insertion is artificially delayed
      final job = Job(Future.delayed(Duration(milliseconds: 100), () {
        _dao[request.target.type].insert(created);
        return _dao[request.target.type].toResource(created);
      }));
      _dao['jobs'].insert(job);
      request.sendAccepted(_dao['jobs'].toResource(job));
      return;
    }

    _dao[request.target.type].insert(created);

    request.sendCreated(_dao[request.target.type].toResource(created));
  }

  @override
  void updateResource(UpdateResource request, Resource resource) {
    if (!_dao.containsKey(request.target.type)) {
      request.errorNotFound([JsonApiError(detail: 'Unknown resource type')]);
      return;
    }
    if (request.target.type != resource.type) {
      request.errorConflict([JsonApiError(detail: 'Incompatible type')]);
      return;
    }
    if (_dao[request.target.type].fetchById(request.target.id) == null) {
      request.errorNotFound([JsonApiError(detail: 'Resource not found')]);
      return;
    }
    final updated =
        _dao[request.target.type].update(request.target.id, resource);
    if (updated == null) {
      request.sendNoContent();
      return;
    }
    request.sendUpdated(updated);
  }

  @override
  void replaceToOne(UpdateRelationship request, Identifier identifier) {
    if (!_dao.containsKey(request.target.type)) {
      request.errorNotFound([JsonApiError(detail: 'Unknown resource type')]);
      return;
    }
    _dao[request.target.type].replaceToOne(
        request.target.id, request.target.relationship, identifier);
    request.sendNoContent();
  }

  @override
  void replaceToMany(UpdateRelationship request, List<Identifier> identifiers) {
    if (!_dao.containsKey(request.target.type)) {
      request.errorNotFound([JsonApiError(detail: 'Unknown resource type')]);
      return;
    }
    _dao[request.target.type].replaceToMany(
        request.target.id, request.target.relationship, identifiers);
    request.sendNoContent();
  }

  @override
  void addToMany(AddToMany request, List<Identifier> identifiers) {
    if (!_dao.containsKey(request.target.type)) {
      request.errorNotFound([JsonApiError(detail: 'Unknown resource type')]);
      return;
    }
    request.sendToMany(_dao[request.target.type].addToMany(
        request.target.id, request.target.relationship, identifiers));
  }
}
