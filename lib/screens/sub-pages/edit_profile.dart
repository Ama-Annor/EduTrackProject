import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:edu_track_project/controller/auth_controller.dart';
import 'package:edu_track_project/screens/widgets/custom_norm_btn.dart';
import 'package:edu_track_project/screens/widgets/textfield.dart';

class EditProfile extends StatefulWidget {
  final String picURL;
  final String username;
  final String email;

  const EditProfile({
    super.key,
    this.picURL = "",
    this.username = "",
    this.email = "",
  });

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  File? _userImage;
  String? _profileImage;
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  final AuthController _auth = AuthController();

  @override
  void initState() {
    super.initState();
    _profileImage = widget.picURL;
    usernameController.text = widget.username;
    emailController.text = widget.email;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 150,
    );

    if (pickedImage != null) {
      setState(() {
        _userImage = File(pickedImage.path);
      });

      final profilePicUrl = await _uploadImage();
      if (profilePicUrl != null) {
        setState(() {
          _profileImage = profilePicUrl;
        });
      }
    }
  }

  Future<void> _saveProfile(BuildContext context) async {
    Map<String, dynamic> data = {
      'profilePicURL': _profileImage ?? '',
    };
    try {
      var result = await _auth.editUser(widget.email, data);
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile updated successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF00BFA5),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // Return true to trigger refresh in view_userprofile.dart
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to update profile',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF00BFA5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update profile: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF00BFA5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<String?> _uploadImage() async {
    if (_userImage == null) return _profileImage;

    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imagesRef = storageRef.child(
          'profile_pics/${DateTime.now().millisecondsSinceEpoch}.png');
      final uploadTask = imagesRef.putFile(_userImage!);

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print("Download URL: $downloadUrl");

      setState(() {
        _profileImage = downloadUrl;
      });

      print("Profile image URL updated: $_profileImage");
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to upload image: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF00BFA5),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(29, 29, 29, 1),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 40, 16.0, 0),
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _profileImage != null &&
                        _profileImage!.isNotEmpty
                        ? NetworkImage(_profileImage!)
                        : null,
                    child: _profileImage == null || _profileImage!.isEmpty
                        ? const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.grey,
                    )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00BFA5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              CustomTextField(
                controller: usernameController,
                labelText: 'Username',
                hintText: 'Enter a valid username',
                readOnly: true,
                maxLenOfInput: 100,
              ),
              const SizedBox(height: 50),
              CustomTextField(
                controller: emailController,
                labelText: 'Email',
                hintText: 'Enter a valid email',
                readOnly: true,
                maxLenOfInput: 100,
              ),
              const SizedBox(height: 50),
              CustomNormButton(
                text: 'Save Profile',
                onPressed: () {
                  _saveProfile(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}