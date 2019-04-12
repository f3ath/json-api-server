import 'package:json_api_server/src/request.dart';

abstract class RequestTarget {
  ControllerRequest getRequest(String method);
}

class CollectionTarget implements RequestTarget {
  final String type;

  const CollectionTarget(this.type);

  @override
  ControllerRequest getRequest(String method) {
    if (method == 'GET') return FetchCollection(this);
    throw 'Invalid method $method';
  }
}

class ResourceTarget implements RequestTarget {
  final String type;
  final String id;

  const ResourceTarget(this.type, this.id);

  @override
  ControllerRequest getRequest(String method) {
    // TODO: implement getRequest
    return null;
  }
}

class RelationshipTarget implements RequestTarget {
  final String type;
  final String id;
  final String relationship;

  const RelationshipTarget(this.type, this.id, this.relationship);

  @override
  ControllerRequest getRequest(String method) {
    // TODO: implement getRequest
    return null;
  }
}

class RelatedTarget implements RequestTarget {
  final String type;
  final String id;
  final String relationship;

  const RelatedTarget(this.type, this.id, this.relationship);

  @override
  ControllerRequest getRequest(String method) {
    // TODO: implement getRequest
    return null;
  }
}
