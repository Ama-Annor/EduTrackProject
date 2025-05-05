import 'dart:convert';

class Schedule {
  final String userID;
  final String course;
  final String subject;
  final String description;
  final String date;
  final String start;
  final String end;
  final String priority;
  final String schedule_id;

  Schedule({
    required this.userID,
    required this.course,
    required this.subject,
    required this.description,
    required this.date,
    required this.start,
    required this.end,
    required this.priority,
    required this.schedule_id,
  });

  Schedule copyWith({
    String? userID,
    String? course,
    String? subject,
    String? description,
    String? date,
    String? start,
    String? end,
    String? priority,
    String? schedule_id,
  }) {
    return Schedule(
      userID: userID ?? this.userID,
      course: course ?? this.course,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      date: date ?? this.date,
      start: start ?? this.start,
      end: end ?? this.end,
      priority: priority ?? this.priority,
      schedule_id: schedule_id ?? this.schedule_id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'course': course,
      'subject': subject,
      'description': description,
      'date': date,
      'start': start,
      'end': end,
      'priority': priority,
      'schedule_id': schedule_id,
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      userID: map['userID'] as String,
      course: map['course'] as String,
      subject: map['subject'] as String,
      description: map['description'] as String,
      date: map['date'] as String,
      start: map['start'] as String,
      end: map['end'] as String,
      priority: map['priority'] as String,
      schedule_id: map['schedule_id'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Schedule.fromJson(String source) => Schedule.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Schedule(userID: $userID, course: $course, subject: $subject, description: $description, date: $date, start: $start, end: $end, priority: $priority, schedule_id: $schedule_id)';
  }

  @override
  bool operator ==(covariant Schedule other) {
    if (identical(this, other)) return true;

    return
      other.userID == userID &&
          other.course == course &&
          other.subject == subject &&
          other.description == description &&
          other.date == date &&
          other.start == start &&
          other.end == end &&
          other.priority == priority &&
          other.schedule_id == schedule_id;
  }

  @override
  int get hashCode {
    return userID.hashCode ^
    course.hashCode ^
    subject.hashCode ^
    description.hashCode ^
    date.hashCode ^
    start.hashCode ^
    end.hashCode ^
    priority.hashCode ^
    schedule_id.hashCode;
  }
}