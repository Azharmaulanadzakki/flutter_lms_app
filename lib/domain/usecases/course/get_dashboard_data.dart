import '../../entities/dashboard_data.dart';
import 'get_course_items.dart';

class GetDashboardDataUseCase {
  const GetDashboardDataUseCase(this._getCourseItems);

  final GetCourseItemsUseCase _getCourseItems;

  Future<DashboardData> call(String userId) async =>
      DashboardData(items: await _getCourseItems(userId));
}