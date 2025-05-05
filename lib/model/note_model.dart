import 'dart:convert';
import 'package:flutter/foundation.dart';

class Note {
  final String userID;
  final String title;
  final String content;
  final String note_id;
  final String createdDate;
  final String lastModified;
  final List<dynamic> attachmentURLS;
  final List<dynamic> audioURLS;  // New field

  Note({
    required this.userID,
    required this.title,
    required this.content,
    required this.note_id,
    required this.createdDate,
    required this.lastModified,
    required this.attachmentURLS,
    this.audioURLS = const [],  // Default empty list
  });

  Note copyWith({
    String? userID,
    String? title,
    String? content,
    String? note_id,
    String? createdDate,
    String? lastModified,
    List<dynamic>? attachmentURLS,
    List<dynamic>? audioURLS,
  }) {
    return Note(
      userID: userID ?? this.userID,
      title: title ?? this.title,
      content: content ?? this.content,
      note_id: note_id ?? this.note_id,
      createdDate: createdDate ?? this.createdDate,
      lastModified: lastModified ?? this.lastModified,
      attachmentURLS: attachmentURLS ?? this.attachmentURLS,
      audioURLS: audioURLS ?? this.audioURLS,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userID': userID,
      'title': title,
      'content': content,
      'note_id': note_id,
      'createdDate': createdDate,
      'lastModified': lastModified,
      'attachmentURLS': attachmentURLS,
      'audioURLS': audioURLS,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      userID: map['userID'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      note_id: map['note_id'] as String,
      createdDate: map['createdDate'] as String,
      lastModified: map['lastModified'] as String,
      attachmentURLS: List<dynamic>.from((map['attachmentURLS'] as List<dynamic>)),
      audioURLS: map['audioURLS'] != null
          ? List<dynamic>.from((map['audioURLS'] as List<dynamic>))
          : const [],
    );
  }

  String toJson() => json.encode(toMap());

  factory Note.fromJson(String source) => Note.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Note(userID: $userID, title: $title, content: $content, note_id: $note_id, createdDate: $createdDate, lastModified: $lastModified, attachmentURLS: $attachmentURLS, audioURLS: $audioURLS)';
  }

  @override
  bool operator ==(covariant Note other) {
    if (identical(this, other)) return true;

    return
      other.userID == userID &&
          other.title == title &&
          other.content == content &&
          other.note_id == note_id &&
          other.createdDate == createdDate &&
          other.lastModified == lastModified &&
          listEquals(other.attachmentURLS, attachmentURLS) &&
          listEquals(other.audioURLS, audioURLS);
  }

  @override
  int get hashCode {
    return userID.hashCode ^
    title.hashCode ^
    content.hashCode ^
    note_id.hashCode ^
    createdDate.hashCode ^
    lastModified.hashCode ^
    attachmentURLS.hashCode ^
    audioURLS.hashCode;
  }
}