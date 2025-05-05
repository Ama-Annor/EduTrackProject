import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:edu_track_project/controller/note_controller.dart';
import 'package:edu_track_project/model/note_model.dart';
import 'package:edu_track_project/screens/sub-pages/edit_note.dart';

class NotesCard extends StatelessWidget {
  final Note note;
  final VoidCallback onDelete;
  final BuildContext rootContext;
  final VoidCallback onNoteChanged;

  const NotesCard({
    super.key,
    required this.note,
    required this.onDelete,
    required this.rootContext,
    required this.onNoteChanged,
  });

  @override
  Widget build(BuildContext context) {
    final String title = note.title;
    final String content = note.content;

    // Format the date
    String formattedDate = '';
    try {
      final DateTime lastModified = DateTime.parse(note.lastModified);
      final DateFormat formatter = DateFormat('d MMMM, yyyy');
      formattedDate = formatter.format(lastModified);
    } catch (e) {
      print('Error formatting date: $e');
      formattedDate = note.lastModified.substring(0, 10); // Fallback
    }

    // Check if note has attachments
    final bool hasAttachments = note.attachmentURLS.isNotEmpty;
    // Check if note has audio recordings
    final bool hasAudio = note.audioURLS.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color.fromRGBO(38, 38, 38, 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditNote(note: note),
            ),
          );

          if (result == true) {
            onNoteChanged();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditNote(note: note),
                            ),
                          );

                          if (result == true) {
                            onNoteChanged();
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Divider(color: Colors.grey, height: 1),
              const SizedBox(height: 8),

              // Note content
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Attachment and Audio indicators
              Row(
                children: [
                  if (hasAttachments) ...[
                    const Icon(
                      Icons.image,
                      color: Color(0xFF00BFA5),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${note.attachmentURLS.length} attachment${note.attachmentURLS.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF00BFA5),
                      ),
                    ),
                  ],
                  if (hasAttachments && hasAudio)
                    const SizedBox(width: 12),
                  if (hasAudio) ...[
                    const Icon(
                      Icons.mic,
                      color: Color(0xFF00BFA5),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${note.audioURLS.length} audio${note.audioURLS.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF00BFA5),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}