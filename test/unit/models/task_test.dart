import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tooodooo_app/models/task.dart';

void main() {
  group('SubTask', () {
    test('creates with default completed = false', () {
      final subtask = SubTask('Buy milk');
      expect(subtask.name, 'Buy milk');
      expect(subtask.completed, false);
    });

    test('creates with completed = true', () {
      final subtask = SubTask('Buy milk', completed: true);
      expect(subtask.completed, true);
    });

    test('JSON round-trip preserves all fields', () {
      final original = SubTask('Clean kitchen', completed: true);
      final json = original.toJson();
      final restored = SubTask.fromJson(json);

      expect(restored.name, original.name);
      expect(restored.completed, original.completed);
    });

    test('fromJson defaults completed to false when missing', () {
      final subtask = SubTask.fromJson({'name': 'Test'});
      expect(subtask.completed, false);
    });
  });

  group('Task', () {
    test('creates with default values', () {
      final task = Task('My Task', false, 3.0, null);
      expect(task.name, 'My Task');
      expect(task.completed, false);
      expect(task.priority, 3.0);
      expect(task.iconName, isNull);
      expect(task.duration, isNull);
      expect(task.isGroup, false);
      expect(task.subtasks, isEmpty);
      expect(task.colorValue, isNull);
    });

    test('creates with all optional parameters', () {
      final subtasks = [SubTask('Sub1'), SubTask('Sub2', completed: true)];
      final task = Task(
        'Group Task',
        false,
        5.0,
        'soccer',
        const Duration(hours: 1, minutes: 30),
        true,
        subtasks,
        0xFF00FF00,
      );

      expect(task.name, 'Group Task');
      expect(task.priority, 5.0);
      expect(task.iconName, 'soccer');
      expect(task.duration, const Duration(hours: 1, minutes: 30));
      expect(task.isGroup, true);
      expect(task.subtasks.length, 2);
      expect(task.colorValue, 0xFF00FF00);
    });

    group('JSON round-trip', () {
      test('preserves simple task', () {
        final original = Task('Simple', true, 2.5, 'home');
        final json = original.toJson();
        final restored = Task.fromJson(json);

        expect(restored.name, original.name);
        expect(restored.completed, original.completed);
        expect(restored.priority, original.priority);
        expect(restored.iconName, original.iconName);
        expect(restored.duration, isNull);
        expect(restored.isGroup, false);
        expect(restored.subtasks, isEmpty);
      });

      test('preserves task with duration', () {
        final original = Task('Timed', false, 1.0, null, const Duration(hours: 2, minutes: 15));
        final json = original.toJson();
        final restored = Task.fromJson(json);

        expect(restored.duration, const Duration(hours: 2, minutes: 15));
      });

      test('preserves duration as minutes in JSON', () {
        final task = Task('Timed', false, 1.0, null, const Duration(hours: 1, minutes: 30));
        final json = task.toJson();

        expect(json['duration'], 90);
      });

      test('preserves group task with subtasks', () {
        final subtasks = [
          SubTask('Sub A', completed: true),
          SubTask('Sub B', completed: false),
        ];
        final original = Task('Group', false, 4.0, 'work', null, true, subtasks, 0xFFAABBCC);
        final json = original.toJson();
        final restored = Task.fromJson(json);

        expect(restored.isGroup, true);
        expect(restored.subtasks.length, 2);
        expect(restored.subtasks[0].name, 'Sub A');
        expect(restored.subtasks[0].completed, true);
        expect(restored.subtasks[1].name, 'Sub B');
        expect(restored.subtasks[1].completed, false);
        expect(restored.colorValue, 0xFFAABBCC);
      });

      test('handles null duration in JSON', () {
        final json = {
          'name': 'No Duration',
          'completed': false,
          'priority': 3,
          'iconName': null,
          'duration': null,
          'isGroup': false,
          'subtasks': [],
          'colorValue': null,
        };
        final task = Task.fromJson(json);
        expect(task.duration, isNull);
      });

      test('handles missing optional fields in JSON', () {
        final json = {
          'name': 'Minimal',
          'completed': false,
          'priority': 1,
          'iconName': null,
        };
        final task = Task.fromJson(json);
        expect(task.duration, isNull);
        expect(task.isGroup, false);
        expect(task.subtasks, isEmpty);
        expect(task.colorValue, isNull);
      });
    });

    group('recalcCompletion', () {
      test('sets completed=true when all subtasks completed for group', () {
        final task = Task('Group', false, 3.0, null, null, true, [
          SubTask('A', completed: true),
          SubTask('B', completed: true),
        ]);
        task.recalcCompletion();
        expect(task.completed, true);
      });

      test('sets completed=false when some subtasks incomplete for group', () {
        final task = Task('Group', true, 3.0, null, null, true, [
          SubTask('A', completed: true),
          SubTask('B', completed: false),
        ]);
        task.recalcCompletion();
        expect(task.completed, false);
      });

      test('sets completed=false when subtasks are empty for group', () {
        final task = Task('Group', true, 3.0, null, null, true, []);
        task.recalcCompletion();
        expect(task.completed, false);
      });

      test('does nothing for non-group task', () {
        final task = Task('Single', true, 3.0, null);
        task.recalcCompletion();
        // Should remain unchanged
        expect(task.completed, true);
      });
    });

    group('getIcon', () {
      test('returns correct icon for known name', () {
        final task = Task('Test', false, 1.0, 'soccer');
        expect(task.getIcon(), Icons.sports_soccer);
      });

      test('returns null for null icon name', () {
        final task = Task('Test', false, 1.0, null);
        expect(task.getIcon(), isNull);
      });

      test('returns null for unknown icon name', () {
        final task = Task('Test', false, 1.0, 'nonexistent_icon');
        expect(task.getIcon(), isNull);
      });
    });
  });
}
