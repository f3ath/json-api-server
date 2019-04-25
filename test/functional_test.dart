import 'dart:async';
import 'dart:io';

import 'package:json_api/json_api.dart';
import 'package:json_api_document/json_api_document.dart';
import 'package:json_api_server/json_api_server.dart';
import 'package:test/test.dart';

import '../example/cars_server.dart';

void main() async {
  final port = 8080;
  final route = Routing(Uri.parse('http://localhost:$port'));
  HttpServer server;
  final client = JsonApiClient();
  setUp(() async {
    server = await createServer(InternetAddress.loopbackIPv4, port);
  });

  tearDown(() async => await server.close());

  group('Create', () {
    group('resource', () {
      /// If a POST request did not include a Client-Generated ID and the requested
      /// resource has been created successfully, the server MUST return a 201 Created status code.
      ///
      /// The response SHOULD include a Location header identifying the location of the newly created resource.
      ///
      /// The response MUST also include a document that contains the primary resource created.
      ///
      /// If the resource object returned by the response contains a self key in its links member
      /// and a Location header is provided, the value of the self member MUST match the value of the Location header.
      ///
      /// https://jsonapi.org/format/#crud-creating-responses-201
      test('201 Created', () async {
        final newYork =
            Resource('cities', null, attributes: {'name': 'New York'});
        final r0 =
            await client.createResource(route.collection('cities'), newYork);

        expect(r0.status, 201);
        expect(r0.isSuccessful, true);
        expect(r0.data.toResource().id, isNotEmpty);
        expect(r0.data.toResource().type, 'cities');
        expect(r0.data.toResource().attributes['name'], 'New York');
        expect(r0.location, isNotNull);

        // Make sure the resource is available
        final r1 = await client
            .fetchResource(route.resource('cities', r0.data.toResource().id));
        expect(r1.data.resourceObject.attributes['name'], 'New York');
      });

      /// If a request to create a resource has been accepted for processing,
      /// but the processing has not been completed by the time the server responds,
      /// the server MUST return a 202 Accepted status code.
      ///
      /// https://jsonapi.org/format/#crud-creating-responses-202
      test('202 Acepted', () async {
        final roadster2020 =
            Resource('models', null, attributes: {'name': 'Roadster 2020'});
        final r0 = await client.createResource(
            route.collection('models'), roadster2020);

        expect(r0.status, 202);
        expect(r0.isSuccessful, false); // neither success
        expect(r0.isFailed, false); // nor failure yet
        expect(r0.isAsync, true); // yay async!
        expect(r0.document, isNull);
        expect(r0.asyncDocument, isNotNull);
        expect(r0.asyncData.toResource().type, 'jobs');
        expect(r0.location, isNull);
        expect(r0.contentLocation, isNotNull);

        final r1 = await client.fetchResource(r0.contentLocation);
        expect(r1.status, 200);
        expect(r1.data.toResource().type, 'jobs');

        await Future.delayed(Duration(milliseconds: 100));

        // When it's done, this will be the created resource
        final r2 = await client.fetchResource(r0.contentLocation);
        expect(r2.data.toResource().type, 'models');
        expect(r2.data.toResource().attributes['name'], 'Roadster 2020');
      });

      /// If a POST request did include a Client-Generated ID and the requested
      /// resource has been created successfully, the server MUST return either
      /// a 201 Created status code and response document (as described above)
      /// or a 204 No Content status code with no response document.
      ///
      /// https://jsonapi.org/format/#crud-creating-responses-204
      test('204 No Content', () async {
        final newYork =
            Resource('cities', '555', attributes: {'name': 'New York'});
        final r0 =
            await client.createResource(route.collection('cities'), newYork);

        expect(r0.status, 204);
        expect(r0.isSuccessful, true);
        expect(r0.document, isNull);

        // Make sure the resource is available
        final r1 = await client.fetchResource(route.resource('cities', '555'));
        expect(r1.data.toResource().attributes['name'], 'New York');
      });

      /// A server MUST return 409 Conflict when processing a POST request to
      /// create a resource with a client-generated ID that already exists.
      ///
      /// https://jsonapi.org/format/#crud-creating-responses-409
      test('409 Conflict - Resource already exists', () async {
        final newYork =
            Resource('cities', '1', attributes: {'name': 'New York'});
        final r0 =
            await client.createResource(route.collection('cities'), newYork);

        expect(r0.status, 409);
        expect(r0.isSuccessful, false);
        expect(r0.document.errors.first.detail, 'Resource already exists');
      });

      /// A server MUST return 409 Conflict when processing a POST request in
      /// which the resource object’s type is not among the type(s) that
      /// constitute the collection represented by the endpoint.
      ///
      /// https://jsonapi.org/format/#crud-creating-responses-409
      test('409 Conflict - Incompatible type', () async {
        final newYork =
            Resource('cities', '555', attributes: {'name': 'New York'});
        final r0 =
            await client.createResource(route.collection('companies'), newYork);

        expect(r0.status, 409);
        expect(r0.isSuccessful, false);
        expect(r0.document.errors.first.detail, 'Incompatible type');
      });
    });
  });

  group('Delete', () {
    group('resource', () {
      /// A server MUST return a 204 No Content status code if a deletion request
      /// is successful and no content is returned.
      ///
      /// https://jsonapi.org/format/#crud-deleting-responses-204
      test('204 No Content', () async {
        final r0 = await client.deleteResource(route.resource('models', '1'));

        expect(r0.status, 204);
        expect(r0.isSuccessful, true);
        expect(r0.document, isNull);

        // Make sure the resource is not available anymore
        final r1 = await client.fetchResource(route.resource('models', '1'));
        expect(r1.status, 404);
      });

      /// A server MUST return a 200 OK status code if a deletion request
      /// is successful and the server responds with only top-level meta data.
      ///
      /// https://jsonapi.org/format/#crud-deleting-responses-200
      test('200 OK', () async {
        final r0 =
            await client.deleteResource(route.resource('companies', '1'));

        expect(r0.status, 200);
        expect(r0.isSuccessful, true);
        expect(r0.document.meta['dependenciesCount'], 5);

        // Make sure the resource is not available anymore
        final r1 = await client.fetchResource(route.resource('companies', '1'));
        expect(r1.status, 404);
      });

      /// https://jsonapi.org/format/#crud-deleting-responses-404
      ///
      /// A server SHOULD return a 404 Not Found status code if a deletion request
      /// fails due to the resource not existing.
      test('404 Not Found', () async {
        final r0 = await client.fetchResource(route.resource('models', '555'));
        expect(r0.status, 404);
      });
    });
  });

  group('Fetch', () {
    group('collection', () {
      test('resource collection', () async {
        final uri = route.collection('companies');
        final r = await client.fetchCollection(uri);
        expect(r.status, 200);
        expect(r.isSuccessful, true);
        expect(r.data.collection.first.attributes['name'], 'Tesla');
        expect(r.data.collection.first.self.uri.toString(),
            'http://localhost:8080/companies/1');
        expect(
            r.data.collection.first.relationships['hq'].related.uri.toString(),
            'http://localhost:8080/companies/1/hq');
        expect(r.data.collection.first.relationships['hq'].self.uri.toString(),
            'http://localhost:8080/companies/1/relationships/hq');
        expect(r.data.self.uri, uri);
      });

      test('resource collection traversal', () async {
        final uri = route
            .collection('companies')
            .replace(queryParameters: {'foo': 'bar'});

        final r0 = await client.fetchCollection(uri);
        final somePage = r0.data;

        expect(somePage.pagination.next.uri.queryParameters['foo'], 'bar',
            reason: 'query parameters must be preserved');

        final r1 = await client.fetchCollection(somePage.pagination.next.uri);
        final secondPage = r1.data;
        expect(secondPage.collection.first.attributes['name'], 'BMW');
        expect(secondPage.self.uri, somePage.pagination.next.uri);

        expect(secondPage.pagination.last.uri.queryParameters['foo'], 'bar',
            reason: 'query parameters must be preserved');

        final r2 = await client.fetchCollection(secondPage.pagination.last.uri);
        final lastPage = r2.data;
        expect(lastPage.collection.first.attributes['name'], 'Toyota');
        expect(lastPage.self.uri, secondPage.pagination.last.uri);

        expect(lastPage.pagination.prev.uri.queryParameters['foo'], 'bar',
            reason: 'query parameters must be preserved');

        final r3 = await client.fetchCollection(lastPage.pagination.prev.uri);
        final secondToLastPage = r3.data;
        expect(secondToLastPage.collection.first.attributes['name'], 'Audi');
        expect(secondToLastPage.self.uri, lastPage.pagination.prev.uri);

        expect(
            secondToLastPage.pagination.first.uri.queryParameters['foo'], 'bar',
            reason: 'query parameters must be preserved');

        final r4 =
            await client.fetchCollection(secondToLastPage.pagination.first.uri);
        final firstPage = r4.data;
        expect(firstPage.collection.first.attributes['name'], 'Tesla');
        expect(firstPage.self.uri, secondToLastPage.pagination.first.uri);
      });

      test('related collection', () async {
        final uri = route.related('companies', '1', 'models');
        final r = await client.fetchCollection(uri);
        expect(r.status, 200);
        expect(r.isSuccessful, true);
        expect(r.data.collection.first.attributes['name'], 'Roadster');
        expect(r.data.self.uri, uri);
      });

      test('related collection travesal', () async {
        final uri = route.related('companies', '1', 'models');
        final r0 = await client.fetchCollection(uri);
        final firstPage = r0.data;
        expect(firstPage.collection.length, 1);

        final r1 = await client.fetchCollection(firstPage.pagination.last.uri);
        final lastPage = r1.data;
        expect(lastPage.collection.length, 1);
      });

      test('404', () async {
        final r = await client.fetchCollection(route.collection('unicorns'));
        expect(r.status, 404);
        expect(r.isSuccessful, false);
        expect(r.document.errors.first.detail, 'Unknown resource type');
      });
    });

    group('single resource', () {
      test('single resource', () async {
        final uri = route.resource('models', '1');
        final r = await client.fetchResource(uri);
        expect(r.status, 200);
        expect(r.isSuccessful, true);
        expect(r.data.toResource().attributes['name'], 'Roadster');
        expect(r.data.self.uri, uri);
      });

      test('single resource compound document', () async {
        final uri = route.resource('companies', '1');
        final r = await client.fetchResource(uri);
        expect(r.status, 200);
        expect(r.isSuccessful, true);
        expect(r.data.toResource().attributes['name'], 'Tesla');
        expect(r.data.self.uri, uri);
        expect(r.data.included.length, 5);
        expect(r.data.included.first.type, 'cities');
        expect(r.data.included.first.attributes['name'], 'Palo Alto');
        expect(r.data.included.last.type, 'models');
        expect(r.data.included.last.attributes['name'], 'Model 3');
      });

      test('404 on type', () async {
        final r = await client.fetchResource(route.resource('unicorns', '1'));
        expect(r.status, 404);
        expect(r.isSuccessful, false);
      });

      test('404 on id', () async {
        final r = await client.fetchResource(route.resource('models', '555'));
        expect(r.status, 404);
        expect(r.isSuccessful, false);
      });
    });

    group('related resource', () {
      test('related resource', () async {
        final uri = route.related('companies', '1', 'hq');
        final r = await client.fetchResource(uri);
        expect(r.status, 200);
        expect(r.isSuccessful, true);
        expect(r.data.toResource().attributes['name'], 'Palo Alto');
        expect(r.data.self.uri, uri);
      });

      test('404 on type', () async {
        final r =
            await client.fetchResource(route.related('unicorns', '1', 'hq'));
        expect(r.status, 404);
        expect(r.isSuccessful, false);
      });

      test('404 on id', () async {
        final r =
            await client.fetchResource(route.related('models', '555', 'hq'));
        expect(r.status, 404);
        expect(r.isSuccessful, false);
      });

      test('404 on relationship', () async {
        final r = await client
            .fetchResource(route.related('companies', '1', 'unicorn'));
        expect(r.status, 404);
        expect(r.isSuccessful, false);
      });
    });

    group('relationships', () {
      test('to-one', () async {
        final uri = route.relationship('companies', '1', 'hq');
        final r = await client.fetchToOne(uri);
        expect(r.status, 200);
        expect(r.isSuccessful, true);
        expect(r.data.toIdentifier().type, 'cities');
        expect(r.data.self.uri, uri);
        expect(r.data.related.uri.toString(),
            'http://localhost:8080/companies/1/hq');
      });

      test('empty to-one', () async {
        final uri = route.relationship('companies', '3', 'hq');
        final r = await client.fetchToOne(uri);
        expect(r.status, 200);
        expect(r.isSuccessful, true);
        expect(r.data.toIdentifier(), isNull);
        expect(r.data.self.uri, uri);
        expect(r.data.related.uri.toString(),
            'http://localhost:8080/companies/3/hq');
      });

      test('generic to-one', () async {
        final uri = route.relationship('companies', '1', 'hq');
        final r = await client.fetchRelationship(uri);
        expect(r.status, 200);
        expect(r.isSuccessful, true);
        expect(r.data, TypeMatcher<ToOne>());
        expect((r.data as ToOne).toIdentifier().type, 'cities');
        expect(r.data.self.uri, uri);
        expect(r.data.related.uri.toString(),
            'http://localhost:8080/companies/1/hq');
      });

      test('to-many', () async {
        final uri = route.relationship('companies', '1', 'models');
        final r = await client.fetchToMany(uri);
        expect(r.status, 200);
        expect(r.isSuccessful, true);
        expect(r.data.toIdentifiers().first.type, 'models');
        expect(r.data.self.uri, uri);
        expect(r.data.related.uri.toString(),
            'http://localhost:8080/companies/1/models');
      });

      test('empty to-many', () async {
        final uri = route.relationship('companies', '3', 'models');
        final r = await client.fetchToMany(uri);
        expect(r.status, 200);
        expect(r.isSuccessful, true);
        expect(r.data.toIdentifiers(), isEmpty);
        expect(r.data.self.uri, uri);
        expect(r.data.related.uri.toString(),
            'http://localhost:8080/companies/3/models');
      });

      test('generic to-many', () async {
        final uri = route.relationship('companies', '1', 'models');
        final r = await client.fetchRelationship(uri);
        expect(r.status, 200);
        expect(r.isSuccessful, true);
        expect(r.data, TypeMatcher<ToMany>());
        expect((r.data as ToMany).toIdentifiers().first.type, 'models');
        expect(r.data.self.uri, uri);
        expect(r.data.related.uri.toString(),
            'http://localhost:8080/companies/1/models');
      });
    });
  });

  group('Update', () {
    /// Updating a Resource’s Attributes
    /// ================================
    ///
    /// Any or all of a resource’s attributes MAY be included
    /// in the resource object included in a PATCH request.
    ///
    /// If a request does not include all of the attributes for a resource,
    /// the server MUST interpret the missing attributes as if they were
    /// included with their current values. The server MUST NOT interpret
    /// missing attributes as null values.
    ///
    /// Updating a Resource’s Relationships
    /// ===================================
    ///
    /// Any or all of a resource’s relationships MAY be included
    /// in the resource object included in a PATCH request.
    ///
    /// If a request does not include all of the relationships for a resource,
    /// the server MUST interpret the missing relationships as if they were
    /// included with their current values. It MUST NOT interpret them
    /// as null or empty values.
    ///
    /// If a relationship is provided in the relationships member
    /// of a resource object in a PATCH request, its value MUST be
    /// a relationship object with a data member.
    /// The relationship’s value will be replaced with the value specified in this member.
    group('resource', () {
      /// If a server accepts an update but also changes the resource(s)
      /// in ways other than those specified by the request (for example,
      /// updating the updated-at attribute or a computed sha),
      /// it MUST return a 200 OK response.
      ///
      /// The response document MUST include a representation of the
      /// updated resource(s) as if a GET request was made to the request URL.
      ///
      /// A server MUST return a 200 OK status code if an update is successful,
      /// the client’s current attributes remain up to date, and the server responds
      /// only with top-level meta data. In this case the server MUST NOT include
      /// a representation of the updated resource(s).
      ///
      /// https://jsonapi.org/format/#crud-updating-responses-200
      test('200 OK', () async {
        final r0 = await client.fetchResource(route.resource('companies', '1'));
        final original = r0.document.data.toResource();

        expect(original.attributes['name'], 'Tesla');
        expect(original.attributes['nasdaq'], isNull);
        expect(original.toMany['models'].length, 4);

        original.attributes['nasdaq'] = 'TSLA';
        original.attributes.remove('name'); // Not changing this
        original.toMany['models'].removeLast();
        original.toOne['headquarters'] = null; // should be removed

        final r1 = await client.updateResource(
            route.resource('companies', '1'), original);
        final updated = r1.document.data.toResource();

        expect(r1.status, 200);
        expect(updated.attributes['name'], 'Tesla');
        expect(updated.attributes['nasdaq'], 'TSLA');
        expect(updated.toMany['models'].length, 3);
        expect(updated.toOne['headquarters'], isNull);
        expect(
            updated.attributes['updatedAt'] != original.attributes['updatedAt'],
            true);
      });

      /// If an update is successful and the server doesn’t update any attributes
      /// besides those provided, the server MUST return either
      /// a 200 OK status code and response document (as described above)
      /// or a 204 No Content status code with no response document.
      ///
      /// https://jsonapi.org/format/#crud-updating-responses-204
      test('204 No Content', () async {
        final r0 = await client.fetchResource(route.resource('models', '3'));
        final original = r0.document.data.toResource();

        expect(original.attributes['name'], 'Model X');

        original.attributes['name'] = 'Model XXX';

        final r1 = await client.updateResource(
            route.resource('models', '3'), original);
        expect(r1.status, 204);
        expect(r1.document, isNull);

        final r2 = await client.fetchResource(route.resource('models', '3'));

        expect(r2.data.toResource().attributes['name'], 'Model XXX');
      });

      /// A server MAY return 409 Conflict when processing a PATCH request
      /// to update a resource if that update would violate other
      /// server-enforced constraints (such as a uniqueness constraint
      /// on a property other than id).
      ///
      /// A server MUST return 409 Conflict when processing a PATCH request
      /// in which the resource object’s type and id do not match the server’s endpoint.
      ///
      /// https://jsonapi.org/format/#crud-updating-responses-409
      test('409 Conflict - Endpoint mismatch', () async {
        final r0 = await client.fetchResource(route.resource('models', '3'));
        final original = r0.document.data.toResource();

        final r1 = await client.updateResource(
            route.resource('companies', '1'), original);
        expect(r1.status, 409);
        expect(r1.document.errors.first.detail, 'Incompatible type');
      });
    });

    /// Updating Relationships
    /// ======================
    ///
    /// Although relationships can be modified along with resources (as described above),
    /// JSON:API also supports updating of relationships independently at URLs from relationship links.
    ///
    /// Note: Relationships are updated without exposing the underlying server semantics,
    /// such as foreign keys. Furthermore, relationships can be updated without necessarily
    /// affecting the related resources. For example, if an article has many authors,
    /// it is possible to remove one of the authors from the article without deleting the person itself.
    /// Similarly, if an article has many tags, it is possible to add or remove tags.
    /// Under the hood on the server, the first of these examples
    /// might be implemented with a foreign key, while the second
    /// could be implemented with a join table, but the JSON:API protocol would be the same in both cases.
    ///
    /// Note: A server may choose to delete the underlying resource
    /// if a relationship is deleted (as a garbage collection measure).
    ///
    /// https://jsonapi.org/format/#crud-updating-relationships
    group('relationship', () {
      /// Updating To-One Relationships
      /// =============================
      ///
      /// A server MUST respond to PATCH requests to a URL from a to-one
      /// relationship link as described below.
      ///
      /// The PATCH request MUST include a top-level member named data containing one of:
      ///   - a resource identifier object corresponding to the new related resource.
      ///   - null, to remove the relationship.
      group('to-one', () {
        group('replace', () {
          test('204 No Content', () async {
            final url = route.relationship('companies', '1', 'hq');
            final r0 = await client.fetchToOne(url);
            final original = r0.document.data.toIdentifier();
            expect(original.id, '2');

            final r1 =
                await client.replaceToOne(url, Identifier(original.type, '1'));
            expect(r1.status, 204);

            final r2 = await client.fetchToOne(url);
            final updated = r2.document.data.toIdentifier();
            expect(updated.type, original.type);
            expect(updated.id, '1');
          });
        });

        group('remove', () {
          test('204 No Content', () async {
            final url = route.relationship('companies', '1', 'hq');

            final r0 = await client.fetchToOne(url);
            final original = r0.document.data.toIdentifier();
            expect(original.id, '2');

            final r1 = await client.deleteToOne(url);
            expect(r1.status, 204);

            final r2 = await client.fetchToOne(url);
            expect(r2.document.data.toIdentifier(), isNull);
          });
        });
      });

      /// Updating To-Many Relationships
      /// ==============================
      ///
      /// A server MUST respond to PATCH, POST, and DELETE requests to a URL
      /// from a to-many relationship link as described below.
      ///
      /// For all request types, the body MUST contain a data member
      /// whose value is an empty array or an array of resource identifier objects.
      group('to-many', () {
        /// If a client makes a PATCH request to a URL from a to-many relationship link,
        /// the server MUST either completely replace every member of the relationship,
        /// return an appropriate error response if some resources can not be
        /// found or accessed, or return a 403 Forbidden response if complete replacement
        /// is not allowed by the server.
        group('replace', () {
          test('204 No Content', () async {
            final url = route.relationship('companies', '1', 'models');
            final r0 = await client.fetchToMany(url);
            final original = r0.data.toIdentifiers().map((_) => _.id);
            expect(original, ['1', '2', '3', '4']);

            final r1 = await client.replaceToMany(
                url, [Identifier('models', '5'), Identifier('models', '6')]);
            expect(r1.status, 204);

            final r2 = await client.fetchToMany(url);
            final updated = r2.data.toIdentifiers().map((_) => _.id);
            expect(updated, ['5', '6']);
          });
        });

        /// If a client makes a POST request to a URL from a relationship link,
        /// the server MUST add the specified members to the relationship
        /// unless they are already present.
        /// If a given type and id is already in the relationship, the server MUST NOT add it again.
        ///
        /// Note: This matches the semantics of databases that use foreign keys
        /// for has-many relationships. Document-based storage should check
        /// the has-many relationship before appending to avoid duplicates.
        ///
        /// If all of the specified resources can be added to, or are already present in,
        /// the relationship then the server MUST return a successful response.
        ///
        /// Note: This approach ensures that a request is successful if the server’s state
        /// matches the requested state, and helps avoid pointless race conditions
        /// caused by multiple clients making the same changes to a relationship.
        group('add', () {
          test('200 OK', () async {
            final url = route.relationship('companies', '1', 'models');
            final r0 = await client.fetchToMany(url);
            final original = r0.data.toIdentifiers().map((_) => _.id);
            expect(original, ['1', '2', '3', '4']);

            final r1 = await client.addToMany(
                url, [Identifier('models', '1'), Identifier('models', '5')]);
            expect(r1.status, 200);

            final updated = r1.data.toIdentifiers().map((_) => _.id);
            expect(updated, ['1', '2', '3', '4', '5']);
          });
        });
      });
    });
  });
}
