// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Deadline {
  final String userID;
  final String deadline_id;
  final String title;
  final String description;
  final String dueDate;
  final String setReminder;
  final String reminderTime;
  Deadline({
    required this.userID,
    required this.deadline_id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.setReminder,
    required this.reminderTime,
  });

  Deadline copyWith({
    String? userID,
    String? deadline_id,
    String? title,
    String? description,
    String? dueDate,
    String? setReminder,
    String? reminderTime,
  }) {
    return Deadline(
      userID: userID ?? this.userID,
      deadline_id: deadline_id ?? this.deadline_id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      setReminder: setReminder ?? this.setReminder,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userID': userID,
      'deadline_id': deadline_id,
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'setReminder': setReminder,
      'reminderTime': reminderTime,
    };
  }

  factory Deadline.fromMap(Map<String, dynamic> map) {
    return Deadline(
      userID: map['userID'] as String,
      deadline_id: map['deadline_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      dueDate: map['dueDate'] as String,
      setReminder: map['setReminder'] as String,
      reminderTime: map['reminderTime'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Deadline.fromJson(String source) => Deadline.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Deadline(userID: $userID, deadline_id: $deadline_id, title: $title, description: $description, dueDate: $dueDate, setReminder: $setReminder, reminderTime: $reminderTime)';
  }

  @override
  bool operator ==(covariant Deadline other) {
    if (identical(this, other)) return true;

    return
      other.userID == userID &&
          other.deadline_id == deadline_id &&
          other.title == title &&
          other.description == description &&
          other.dueDate == dueDate &&
          other.setReminder == setReminder &&
          other.reminderTime == reminderTime;
  }

  @override
  int get hashCode {
    return userID.hashCode ^
    deadline_id.hashCode ^
    title.hashCode ^
    description.hashCode ^
    dueDate.hashCode ^
    setReminder.hashCode ^
    reminderTime.hashCode;
  }
}