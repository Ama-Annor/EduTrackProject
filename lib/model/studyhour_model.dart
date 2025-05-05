import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudyHour {
  final String userID;
  final String course;
  final String hoursLogged;
  final String loggedDate;
  final String studyhour_id;

  StudyHour({
    required this.userID,
    required this.course,
    required this.hoursLogged,
    required this.loggedDate,
    required this.studyhour_id,
  });

  StudyHour copyWith({
    String? userID,
    String? course,
    String? hoursLogged,
    String? loggedDate,
    String? studyhour_id,
  }) {
    return StudyHour(
      userID: userID ?? this.userID,
      course: course ?? this.course,
      hoursLogged: hoursLogged ?? this.hoursLogged,
      loggedDate: loggedDate ?? this.loggedDate,
      studyhour_id: studyhour_id ?? this.studyhour_id,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userID': userID,
      'course': course,
      'hoursLogged': hoursLogged,
      'loggedDate': loggedDate,
      'studyhour_id': studyhour_id,
    };
  }

  factory StudyHour.fromMap(Map<String, dynamic> map) {
    return StudyHour(
      userID: map['userID'] as String,
      course: map['course'] as String,
      hoursLogged: map['hoursLogged'] as String,
      loggedDate: map['loggedDate'] as String,
      studyhour_id: map['studyhour_id'] as String,
    );
  }

  factory StudyHour.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudyHour(
      userID: data['userID'] as String,
      course: data['course'] as String,
      hoursLogged: data['hoursLogged'] as String,
      loggedDate: data['loggedDate'] as String,
      studyhour_id: doc.id,
    );
  }

  String toJson() => json.encode(toMap());

  factory StudyHour.fromJson(String source) =>
      StudyHour.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'StudyHour(userID: $userID, course: $course, hoursLogged: $hoursLogged, loggedDate: $loggedDate, studyhour_id: $studyhour_id)';
  }

  @override
  bool operator ==(covariant StudyHour other) {
    if (identical(this, other)) return true;
    return other.userID == userID &&
        other.course == course &&
        other.hoursLogged == hoursLogged &&
        other.loggedDate == loggedDate &&
        other.studyhour_id == studyhour_id;
  }

  @override
  int get hashCode {
    return userID.hashCode ^
    course.hashCode ^
    hoursLogged.hashCode ^
    loggedDate.hashCode ^
    studyhour_id.hashCode;
  }
}