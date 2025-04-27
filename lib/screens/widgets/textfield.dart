import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final String? errorText;
  final bool obscureText;
  final bool readOnly;
  final TextInputType keyboardType;
  final FocusNode? focusNode;
  final String? helperText;
  final int maxLenOfInput;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.errorText,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.focusNode,
    this.helperText,
    required this.maxLenOfInput,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.obscureText,
      focusNode: widget.focusNode,
      readOnly: widget.readOnly,
      keyboardType: widget.keyboardType,
      inputFormatters: [
        LengthLimitingTextInputFormatter(widget.maxLenOfInput),
      ],
      style: TextStyle(
        color: widget.readOnly ? const Color.fromRGBO(173, 172, 172, 1) : Colors.white,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color.fromRGBO(38, 38, 38, 1),
        hintText: widget.hintText,
        errorText: widget.errorText,
        errorStyle: const TextStyle(
          color: Colors.red,
        ),
        helperText: widget.helperText,
        helperStyle: const TextStyle(
          color: Colors.red,
        ),
        hintStyle: const TextStyle(
          color: Color.fromRGBO(173, 172, 172, 1),
        ),
        labelText: widget.labelText,
        labelStyle: const TextStyle(
          color: Colors.white,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color.fromRGBO(173, 172, 172, 1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color.fromRGBO(29, 29, 29, 1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color.fromRGBO(173, 172, 172, 1),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 1.0),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Color.fromRGBO(29, 29, 29, 1),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      ),
    );
  }
}