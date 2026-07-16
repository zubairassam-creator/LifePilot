// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lifepilot_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LifePilotTaskAdapter extends TypeAdapter<LifePilotTask> {
  @override
  final int typeId = 4;

  @override
  LifePilotTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LifePilotTask(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      category: fields[3] as String,
      priority: fields[4] as TaskPriority,
      status: fields[5] as TaskStatus,
      dueDateTime: fields[6] as DateTime?,
      reminderEnabled: fields[7] as bool,
      reminderMode: fields[8] as ReminderMode,
      repeatType: fields[9] as RepeatType,
      isPinned: fields[10] as bool,
      isAiGenerated: fields[11] as bool,
      aiConfidence: fields[12] as double,
      createdAt: fields[13] as DateTime,
      updatedAt: fields[14] as DateTime,
      completedAt: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LifePilotTask obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.dueDateTime)
      ..writeByte(7)
      ..write(obj.reminderEnabled)
      ..writeByte(8)
      ..write(obj.reminderMode)
      ..writeByte(9)
      ..write(obj.repeatType)
      ..writeByte(10)
      ..write(obj.isPinned)
      ..writeByte(11)
      ..write(obj.isAiGenerated)
      ..writeByte(12)
      ..write(obj.aiConfidence)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt)
      ..writeByte(15)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LifePilotTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskPriorityAdapter extends TypeAdapter<TaskPriority> {
  @override
  final int typeId = 0;

  @override
  TaskPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskPriority.low;
      case 1:
        return TaskPriority.normal;
      case 2:
        return TaskPriority.high;
      case 3:
        return TaskPriority.critical;
      default:
        return TaskPriority.low;
    }
  }

  @override
  void write(BinaryWriter writer, TaskPriority obj) {
    switch (obj) {
      case TaskPriority.low:
        writer.writeByte(0);
        break;
      case TaskPriority.normal:
        writer.writeByte(1);
        break;
      case TaskPriority.high:
        writer.writeByte(2);
        break;
      case TaskPriority.critical:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskStatusAdapter extends TypeAdapter<TaskStatus> {
  @override
  final int typeId = 1;

  @override
  TaskStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskStatus.pending;
      case 1:
        return TaskStatus.completed;
      case 2:
        return TaskStatus.archived;
      default:
        return TaskStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, TaskStatus obj) {
    switch (obj) {
      case TaskStatus.pending:
        writer.writeByte(0);
        break;
      case TaskStatus.completed:
        writer.writeByte(1);
        break;
      case TaskStatus.archived:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReminderModeAdapter extends TypeAdapter<ReminderMode> {
  @override
  final int typeId = 2;

  @override
  ReminderMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReminderMode.silent;
      case 1:
        return ReminderMode.normal;
      case 2:
        return ReminderMode.speakAloud;
      default:
        return ReminderMode.silent;
    }
  }

  @override
  void write(BinaryWriter writer, ReminderMode obj) {
    switch (obj) {
      case ReminderMode.silent:
        writer.writeByte(0);
        break;
      case ReminderMode.normal:
        writer.writeByte(1);
        break;
      case ReminderMode.speakAloud:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RepeatTypeAdapter extends TypeAdapter<RepeatType> {
  @override
  final int typeId = 3;

  @override
  RepeatType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RepeatType.none;
      case 1:
        return RepeatType.daily;
      case 2:
        return RepeatType.weekly;
      case 3:
        return RepeatType.monthly;
      case 4:
        return RepeatType.yearly;
      default:
        return RepeatType.none;
    }
  }

  @override
  void write(BinaryWriter writer, RepeatType obj) {
    switch (obj) {
      case RepeatType.none:
        writer.writeByte(0);
        break;
      case RepeatType.daily:
        writer.writeByte(1);
        break;
      case RepeatType.weekly:
        writer.writeByte(2);
        break;
      case RepeatType.monthly:
        writer.writeByte(3);
        break;
      case RepeatType.yearly:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepeatTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
