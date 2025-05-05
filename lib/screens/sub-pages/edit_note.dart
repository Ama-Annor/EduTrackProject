import 'package:flutter/material.dart';
import 'package:edu_track_project/model/note_model.dart';
import 'package:edu_track_project/controller/note_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:edu_track_project/screens/widgets/audio_recorder_widget.dart';
import 'package:edu_track_project/screens/widgets/audio_player_widget.dart';
import 'package:cross_file/cross_file.dart';

class EditNote extends StatefulWidget {
  final Note note;
  const EditNote({super.key, required this.note});

  @override
  State<EditNote> createState() => _EditNoteState();
}

class _EditNoteState extends State<EditNote> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final NoteController _noteController = NoteController();

  List<String> _attachmentURLs = [];
  List<String> _audioURLs = []; // For storing audio URLs
  final List<File> _newImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isExporting = false;
  String _currentAudioPath = ''; // Track current audio recording

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.note.title;
    _contentController.text = widget.note.content;
    _attachmentURLs = List<String>.from(widget.note.attachmentURLS);
    _audioURLs = List<String>.from(widget.note.audioURLS);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _newImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadNewImages() async {
    for (File image in _newImages) {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${_newImages.indexOf(image)}.png';
      Reference ref = FirebaseStorage.instance.ref().child('note_images/$fileName');
      await ref.putFile(image);
      String downloadURL = await ref.getDownloadURL();
      _attachmentURLs.add(downloadURL);
      print('New image uploaded: $downloadURL');
    }
  }

  // Handle saved audio recordings
  void _handleAudioSaved(String audioPath, String audioUrl) {
    setState(() {
      _currentAudioPath = audioPath;
      _audioURLs.add(audioUrl);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Audio recording saved successfully'),
        backgroundColor: Color(0xFF00BFA5),
      ),
    );
  }

  // Remove audio recording
  void _removeAudio(int index) {
    setState(() {
      _audioURLs.removeAt(index);
    });
  }

  Future<Uint8List> _getImageData(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      return response.bodyBytes;
    } catch (e) {
      print('Error getting image data: $e');
      return Uint8List(0);
    }
  }

  Future<void> _exportNoteAsPdf() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final pdf = pw.Document();

      // Add images to PDF
      final imageWidgets = <pw.Widget>[];
      for (var url in _attachmentURLs) {
        try {
          final imageData = await _getImageData(url);
          if (imageData.isNotEmpty) {
            final image = pw.MemoryImage(imageData);
            imageWidgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Image(image, width: 200, height: 200, fit: pw.BoxFit.cover),
                )
            );
          }
        } catch (e) {
          print('Error processing image for PDF: $e');
        }
      }

      // Create PDF page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                widget.note.title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Created: ${widget.note.createdDate.substring(0, 10)}',
                style: const pw.TextStyle(
                  fontSize: 12,
                ),
              ),
              pw.Text(
                'Last modified: ${widget.note.lastModified.substring(0, 10)}',
                style: const pw.TextStyle(
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(widget.note.content),
              pw.SizedBox(height: 20),
              if (imageWidgets.isNotEmpty) ...[
                pw.Text('Attachments:',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                ...imageWidgets,
              ],
              if (_audioURLs.isNotEmpty) ...[
                pw.Text('Audio Recordings:',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('This note contains ${_audioURLs.length} audio recording(s). Audio cannot be embedded in the PDF.'),
              ],
            ],
          ),
        ),
      );

      // Get app's documents directory for more accessible location
      final directory = await getExternalStorageDirectory();
      final String fileName = '${widget.note.title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory!.path}/$fileName');

      // Save PDF file
      await file.writeAsBytes(await pdf.save());

      // Show success message with share option
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF exported successfully'),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () => _sharePdf(file.path),
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: const Color(0xFF00BFA5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error exporting PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export PDF: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _sharePdf(String filePath) async {
    try {
      // Use SharePlus instead of Share
      await Share.shareXFiles([XFile(filePath)], text: 'Note: ${widget.note.title}');
    } catch (e) {
      print('Error sharing PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing PDF: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachmentURLs.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _saveNote() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Upload any new images
        if (_newImages.isNotEmpty) {
          await _uploadNewImages();
        }

        // Update note data
        var data = {
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'lastModified': DateTime.now().toIso8601String(),
          'attachmentURLS': _attachmentURLs,
          'audioURLS': _audioURLs, // Include audio URLs
        };

        print('Updating note: ${widget.note.note_id} with data: $data');

        // Save to Firestore
        final result = await _noteController.updateNote(data, widget.note.note_id);

        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Note updated successfully',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xFF00BFA5),
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.pop(context, true); // Return true to indicate success
        } else {
          throw Exception('Failed to update note');
        }
      } catch (e) {
        print('Error updating note: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update note: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format the last modified date for display
    String formattedDate = '';
    try {
      final DateTime lastModified = DateTime.parse(widget.note.lastModified);
      formattedDate = '${lastModified.year}-${lastModified.month.toString().padLeft(2, '0')}-${lastModified.day.toString().padLeft(2, '0')} ${lastModified.hour.toString().padLeft(2, '0')}:${lastModified.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      formattedDate = widget.note.lastModified;
    }

    return Scaffold(
      backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
      appBar: AppBar(
        title: Text(
          'Last modified: $formattedDate',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 26,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.0,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(
                Icons.picture_as_pdf,
                color: Colors.white,
                size: 26,
              ),
              onPressed: _exportNoteAsPdf,
            ),
          IconButton(
            icon: const Icon(
              Icons.check,
              color: Colors.white,
              size: 26,
            ),
            onPressed: _isLoading ? null : _saveNote,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BFA5)))
          : Form(
        key: _formKey,
        child: Column(
          children: [
            // Title field
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                controller: _titleController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title cannot be empty';
                  }
                  return null;
                },
              ),
            ),

            const Divider(color: Colors.grey),

            // Content field
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextFormField(
                  controller: _contentController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: 'Write your note here (optional for audio notes)',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    // Skip validation if there's audio content
                    if (_audioURLs.isNotEmpty) {
                      return null;
                    }

                    // For text-only notes, require content
                    if (value == null || value.trim().isEmpty) {
                      return 'Content cannot be empty for text-only notes';
                    }
                    return null;
                  },
                ),
              ),
            ),

            // Audio recorder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: AudioRecorderWidget(
                onAudioSaved: _handleAudioSaved,
              ),
            ),

            // Audio recordings list
            if (_audioURLs.isNotEmpty)
              Container(
                height: 120,
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _audioURLs.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      margin: const EdgeInsets.only(right: 16.0),
                      child: Stack(
                        children: [
                          AudioPlayerWidget(audioUrl: _audioURLs[index]),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _removeAudio(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            // Existing images
            if (_attachmentURLs.isNotEmpty)
              Container(
                height: 120,
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachmentURLs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _attachmentURLs[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _removeAttachment(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            // New images
            if (_newImages.isNotEmpty)
              Container(
                height: 120,
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _newImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _newImages[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _removeNewImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.image,
                      color: Color(0xFF00BFA5),
                      size: 26,
                    ),
                    onPressed: _pickImage,
                  ),
                  ElevatedButton(
                    onPressed: _saveNote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      child: Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}