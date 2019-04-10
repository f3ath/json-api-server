import 'package:json_api_document/json_api_document.dart';
import 'package:json_api_server/src/collection.dart';
import 'package:json_api_server/src/nullable.dart';
import 'package:json_api_server/src/page.dart';
import 'package:json_api_server/src/request.dart';
import 'package:json_api_server/src/routing.dart';

/// The Document builder is used by JsonApiServer. It abstracts the process
/// of building response documents and is responsible for such aspects as
///  adding `meta` and `jsonapi` attributes and generating links
class DocumentBuilder {
  final Routing route;

  DocumentBuilder(this.route);

  /// A document containing a list of errors
  Document errorDocument(Iterable<JsonApiError> errors) => Document.error(errors);

  /// A collection of (primary) resources
  Document<ResourceCollectionData> collectionDocument(
          Collection<Resource> collection, Uri self,
          {Iterable<Resource> included}) =>
      Document(ResourceCollectionData(collection.elements.map(resourceObject),
          self: Link(self), pagination: pagination(collection.page, self)));

  /// A collection of related resources
  Document<ResourceCollectionData> relatedCollectionDocument(
          Collection<Resource> resources, Uri self,
          {Iterable<Resource> included}) =>
      Document(ResourceCollectionData(resources.elements.map(resourceObject),
          self: Link(self), pagination: pagination(resources.page, self)));

  /// A single (primary) resource
  Document<ResourceData> resourceDocument(Resource resource, Uri self,
          {Iterable<Resource> included}) =>
      Document(
        ResourceData(resourceObject(resource),
            self: Link(self), included: included?.map(resourceObject)),
      );

  /// A single related resource
  Document<ResourceData> relatedResourceDocument(
          Resource resource, RelatedTarget target, Uri self,
          {Iterable<Resource> included}) =>
      Document(ResourceData(resourceObject(resource),
          included: included?.map(resourceObject),
          self: Link(
              route.related(target.type, target.id, target.relationship))));

  /// A to-many relationship
  Document<ToMany> toManyDocument(Iterable<Identifier> collection,
          RelationshipTarget target, Uri self) =>
      Document(ToMany(collection.map(identifierObject),
          self: Link(
              route.relationship(target.type, target.id, target.relationship)),
          related: Link(
              route.related(target.type, target.id, target.relationship))));

  /// A to-one relationship
  Document<ToOne> toOneDocument(
          Identifier identifier, RelationshipTarget target, Uri self) =>
      Document(ToOne(nullable(identifierObject)(identifier),
          self: Link(
              route.relationship(target.type, target.id, target.relationship)),
          related: Link(
              route.related(target.type, target.id, target.relationship))));

  /// A document containing just a meta member
  Document metaDocument(Map<String, Object> meta) => Document.empty(meta);

  IdentifierObject identifierObject(Identifier id) =>
      IdentifierObject(id.type, id.id);

  ResourceObject resourceObject(Resource resource) {
    final relationships = <String, Relationship>{};
    relationships.addAll(resource.toOne.map((k, v) => MapEntry(
        k,
        ToOne(nullable(identifierObject)(v),
            self: Link(route.relationship(resource.type, resource.id, k)),
            related: Link(route.related(resource.type, resource.id, k))))));

    relationships.addAll(resource.toMany.map((k, v) => MapEntry(
        k,
        ToMany(v.map(identifierObject),
            self: Link(route.relationship(resource.type, resource.id, k)),
            related: Link(route.related(resource.type, resource.id, k))))));

    return ResourceObject(resource.type, resource.id,
        attributes: resource.attributes,
        relationships: relationships,
        self: Link(route.resource(resource.type, resource.id)));
  }

  Pagination pagination(Page page, Uri self) {
    if (page == null) return Pagination.empty();
    return Pagination.fromLinks(page.map((_) => Link(_.addTo(self))));
  }
}
