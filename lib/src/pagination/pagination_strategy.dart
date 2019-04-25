import 'package:json_api_server/src/pagination/page.dart';

abstract class PaginationStrategy {
  Page getPage(Map<String, List<String>> query);
}
