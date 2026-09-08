import 'package:flutter/material.dart';
import 'package:tooodooo_app/util/app_icons.dart';

class SubTask {
  String name;
  bool completed;
  SubTask(this.name, {this.completed = false});

  factory SubTask.fromJson(Map<String, dynamic> json) => SubTask(
    json['name'],
    completed: json['completed'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'completed': completed,
  };
}

class Task {
  String name;
  bool completed; // for single task OR overall completion (all subtasks)
  double priority;
  String? iconName;
  Duration? duration; // Changed from time to duration
  bool isGroup;
  List<SubTask> subtasks;
  int? colorValue; // custom color (ARGB) optional

  Task(this.name, this.completed, this.priority, this.iconName, [this.duration, this.isGroup = false, List<SubTask>? subtasks, this.colorValue])
      : subtasks = subtasks ?? [];

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        json['name'],
        json['completed'],
        (json['priority'] as num).toDouble(),
        json['iconName'],
        json['duration'] != null ? Duration(minutes: json['duration']) : null,
        json['isGroup'] ?? false,
        (json['subtasks'] as List?)?.map<SubTask>((e) => SubTask.fromJson((e as Map).cast<String, dynamic>())).toList(),
        json['colorValue'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'completed': completed,
        'priority': priority,
        'iconName': iconName,
        'duration': duration?.inMinutes,
        'isGroup': isGroup,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'colorValue': colorValue,
      };

  IconData? getIcon() {
    return AppIcons.getIcon(iconName);
  }

  void recalcCompletion() {
    if (isGroup) {
      completed = subtasks.isNotEmpty && subtasks.every((s) => s.completed);
    }
  }
}
