import 'domain.dart';

abstract class ExpertRepository {
  Future<List<Expert>> listExperts({String query});

  Future<Expert?> getExpert(String id, {required ExpertSourceType sourceType});
}
