import 'package:sumi_app/features/home_widgets/data/sumi_widget_data.dart';

abstract class WidgetService {
  Future<void> updateAndroidWidgets(SumiWidgetData data);
}
