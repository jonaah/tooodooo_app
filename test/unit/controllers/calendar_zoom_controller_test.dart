import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tooodooo_app/calendar/calendar_zoom_controller.dart';

void main() {
  late CalendarZoomController controller;

  setUp(() {
    controller = CalendarZoomController();
  });

  group('default values', () {
    test('timeIntervalHeight defaults to 40', () {
      expect(controller.timeIntervalHeight, 40.0);
    });

    test('currentMinutesInterval defaults to 30', () {
      expect(controller.currentMinutesInterval, 30);
    });
  });

  group('setTimeIntervalHeight', () {
    test('clamps to minimum (20)', () {
      controller.setTimeIntervalHeight(5.0);
      expect(controller.timeIntervalHeight, CalendarZoomController.minTimeIntervalHeight);
    });

    test('clamps to maximum (80)', () {
      controller.setTimeIntervalHeight(200.0);
      expect(controller.timeIntervalHeight, CalendarZoomController.maxTimeIntervalHeight);
    });

    test('accepts values within range', () {
      controller.setTimeIntervalHeight(50.0);
      expect(controller.timeIntervalHeight, 50.0);
    });

    test('updates minutes interval based on height', () {
      controller.setTimeIntervalHeight(45.0); // >= 40 -> 30min
      expect(controller.currentMinutesInterval, 30);

      controller.setTimeIntervalHeight(30.0); // < 40 -> 60min
      expect(controller.currentMinutesInterval, 60);
    });

    test('boundary at 40 uses 30min interval', () {
      controller.setTimeIntervalHeight(40.0);
      expect(controller.currentMinutesInterval, 30);
    });

    test('just below 40 uses 60min interval', () {
      controller.setTimeIntervalHeight(39.9);
      expect(controller.currentMinutesInterval, 60);
    });
  });

  group('handleScale', () {
    test('returns false when interval does not change', () {
      // Default is 40 -> 30min. Scale by 1.0 keeps it at 40 -> 30min
      final details = ScaleUpdateDetails(
        scale: 1.0,
        focalPoint: Offset.zero,
      );
      final changed = controller.handleScale(details);
      expect(changed, false);
      expect(controller.currentMinutesInterval, 30);
    });

    test('returns true when interval changes from 30min to 60min', () {
      // Default is 40. Scale down to below 40
      final details = ScaleUpdateDetails(
        scale: 0.5, // 40 * 0.5 = 20, which is < 40 -> 60min
        focalPoint: Offset.zero,
      );
      final changed = controller.handleScale(details);
      expect(changed, true);
      expect(controller.currentMinutesInterval, 60);
    });

    test('returns true when interval changes from 60min to 30min', () {
      // First zoom out to get 60min
      controller.setTimeIntervalHeight(30.0);
      expect(controller.currentMinutesInterval, 60);

      // Now zoom in to get back to 30min
      final details = ScaleUpdateDetails(
        scale: 1.5, // 30 * 1.5 = 45, which is >= 40 -> 30min
        focalPoint: Offset.zero,
      );
      final changed = controller.handleScale(details);
      expect(changed, true);
      expect(controller.currentMinutesInterval, 30);
    });

    test('clamps height at minimum during zoom out', () {
      final details = ScaleUpdateDetails(
        scale: 0.1, // 40 * 0.1 = 4, clamped to 20
        focalPoint: Offset.zero,
      );
      controller.handleScale(details);
      expect(controller.timeIntervalHeight, CalendarZoomController.minTimeIntervalHeight);
    });

    test('clamps height at maximum during zoom in', () {
      final details = ScaleUpdateDetails(
        scale: 5.0, // 40 * 5 = 200, clamped to 80
        focalPoint: Offset.zero,
      );
      controller.handleScale(details);
      expect(controller.timeIntervalHeight, CalendarZoomController.maxTimeIntervalHeight);
    });
  });

  group('constants', () {
    test('min < max time interval height', () {
      expect(CalendarZoomController.minTimeIntervalHeight, 
             lessThan(CalendarZoomController.maxTimeIntervalHeight));
    });
  });
}
