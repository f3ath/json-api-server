import 'package:json_api_document/json_api_document.dart';
import 'package:json_api_server/src/collection.dart';
import 'package:json_api_server/src/nullable.dart';
import 'package:json_api_server/src/page.dart';
import 'package:json_api_server/src/request_target.dart';
import 'package:json_api_server/src/routing.dart';

/// The Document builder is used by JsonApiServer. It abstracts the process
/// of building response documents and is responsible for such aspects as
///  adding `meta` and `jsonapi` attributes and generating links
class DocumentBuilder {
  final Routing design;

  DocumentBuilder(this.design);

  /// A document containing a list of errors
  Document error(Iterable<JsonApiError> errors) => Document.error(errors);

  /// A collection of (primary) resources
  Document<ResourceCollectionData> collection(
          Collection<Resource> collection, CollectionTarget target, Uri self,
          {Iterable<Resource> included}) =>
      Document(ResourceCollectionData(collection.elements.map(_resourceObject),
          self: Link(self),
          pagination: _pagination(collection.page, self, target)));

  /// A collection of related resources
  Document<ResourceCollectionData> relatedCollection(
          Collection<Resource> resources, RelatedTarget target, Uri self,
          {Iterable<Resource> included}) =>
      Document(ResourceCollectionData(resources.elements.map(_resourceObject),
          self: Link(self),
          pagination: _pagination(resources.page, self, target)));

  /// A single (primary) resource
  Document<ResourceData> resource(
          Resource resource, ResourceTarget target, Uri self,
          {Iterable<Resource> included}) =>
      Document(
        ResourceData(_resourceObject(resource),
            self: Link(target.url(design)),
            included: included?.map(_resourceObject)),
      );

  /// A single related resource
  Document<ResourceData> relatedResource(
          Resource resource, RelatedTarget target, Uri self,
          {Iterable<Resource> included}) =>
      Document(
        ResourceData(_resourceObject(resource),
            included: included?.map(_resourceObject),
            self: Link(target.url(design))),
      );

  /// A to-many relationship
  Document<ToMany> toMany(Iterable<Identifier> collection,
          RelationshipTarget target, Uri self) =>
      Document(ToMany(collection.map(_identifierObject),
          self: Link(target.url(design)),
          related: Link(target.toRelated().url(design))));

  /// A to-one relationship
  Document<ToOne> toOne(
          Identifier identifier, RelationshipTarget target, Uri self) =>
      Document(ToOne(nullable(_identifierObject)(identifier),
          self: Link(target.url(design)),
          related: Link(target.toRelated().url(design))));

  /// A document containing just a meta member
  Document meta(Map<String, Object> meta) => Document.empty(meta);

  IdentifierObject _identifierObject(Identifier id) =>
      IdentifierObject(id.type, id.id);

  ResourceObject _resourceObject(Resource resource) {
    final relationships = <String, Relationship>{};
    relationships.addAll(resource.toOne.map((k, v) => MapEntry(
        k,
        ToOne(nullable(_identifierObject)(v),
            self: Link(
                RelationshipTarget(resource.type, resource.id, k).url(design)),
            related: Link(
                RelatedTarget(resource.type, resource.id, k).url(design))))));
    relationships.addAll(resource.toMany.map((k, v) => MapEntry(
        k,
        ToMany(v.map(_identifierObject),
            self: Link(
                RelationshipTarget(resource.type, resource.id, k).url(design)),
            related: Link(
                RelatedTarget(resource.type, resource.id, k).url(design))))));

    return ResourceObject(resource.type, resource.id,
        attributes: resource.attributes,
        relationships: relationships,
        self: Link(ResourceTarget(resource.type, resource.id).url(design)));
  }

  Pagination _pagination(Page page, Uri self, RequestTarget target) {
    if (page == null) return Pagination.empty();
    return Pagination.fromLinks(page.map((_) => Link(_.addTo(self))));
  }
}
