import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Studytimer {
  final String userID;
  final String course;
  final String startTime;
  final String endTime;
  final String studytimer_id;
  final String date;

  Studytimer({
    required this.userID,
    required this.course,
    required this.startTime,
    required this.endTime,
    required this.studytimer_id,
    required this.date,
  });

  Studytimer copyWith({
    String? userID,
    String? course,
    String? startTime,
    String? endTime,
    String? studytimer_id,
    String? date,
  }) {
    return Studytimer(
      userID: userID ?? this.userID,
      course: course ?? this.course,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      studytimer_id: studytimer_id ?? this.studytimer_id,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userID': userID,
      'course': course,
      'startTime': startTime,
      'endTime': endTime,
      'studytimer_id': studytimer_id,
      'date': date,
    };
  }

  factory Studytimer.fromMap(Map<String, dynamic> map) {
    return Studytimer(
      userID: map['userID'] as String,
      course: map['course'] as String,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      studytimer_id: map['studytimer_id'] as String,
      date: map['date'] as String,
    );
  }

  factory Studytimer.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Studytimer(
      userID: data['userID'] as String,
      course: data['course'] as String,
      startTime: data['startTime'] as String,
      endTime: data['endTime'] as String,
      studytimer_id: doc.id,
      date: data['date'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Studytimer.fromJson(String source) =>
      Studytimer.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Studytimer(userID: $userID, course: $course, startTime: $startTime, endTime: $endTime, studytimer_id: $studytimer_id, date: $date)';
  }

  @override
  bool operator ==(covariant Studytimer other) {
    if (identical(this, other)) return true;
    return other.userID == userID &&
        other.course == course &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.studytimer_id == studytimer_id &&
        other.date == date;
  }

  @override
  int get hashCode {
    return userID.hashCode ^
    course.hashCode ^
    startTime.hashCode ^
    endTime.hashCode ^
    studytimer_id.hashCode ^
    date.hashCode;
  }
}