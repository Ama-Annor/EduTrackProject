import 'package:flutter/material.dart';

class CustomNormButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color textColor;
  final Color buttonColor;

  const CustomNormButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.textColor = Colors.white,
    this.buttonColor = const Color(0xFF00BFA5),});

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return SizedBox(
      width: width * 0.8,
      height: 70,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(buttonColor),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 15)),
          shape: WidgetStateProperty.all(const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          )),
        ),
        child: Text(text, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }
}