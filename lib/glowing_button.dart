import 'package:flutter/material.dart';

class GlowingButton extends StatefulWidget {
  final Color color1;
  final Color color2;
  final VoidCallback onTap;
  final String text;

  const GlowingButton({
    Key? key,
    this.color1 = Colors.cyan,
    this.color2 = Colors.greenAccent,
    required this.onTap,
    required this.text,
  }) : super(key: key);

  @override
  _GlowingButtonState createState() => _GlowingButtonState();
}

class _GlowingButtonState extends State<GlowingButton> {
  var glowing = true;  // Awalnya glowing
  var scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          glowing = false;  // Setelah di klik, glowing berubah menjadi false
          scale = 1.0;
        });
        widget.onTap();  // Panggil callback onTap yang dikirim
      },
   
  
      child: AnimatedContainer(
        transform: Matrix4.identity()..scale(scale),
        duration: const Duration(milliseconds: 200),
        height: 48,
        width: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: LinearGradient(
            colors: [widget.color1, widget.color2],
          ),
          boxShadow: glowing
              ? [
                  BoxShadow(
                    color: widget.color1.withOpacity(0.6),
                    spreadRadius: 1,
                    blurRadius: 16,
                    offset: const Offset(-8, 0),
                  ),
                  BoxShadow(
                    color: widget.color2.withOpacity(0.6),
                    spreadRadius: 1,
                    blurRadius: 16,
                    offset: const Offset(8, 0),
                  ),
                  BoxShadow(
                    color: widget.color1.withOpacity(0.2),
                    spreadRadius: 16,
                    blurRadius: 32,
                    offset: const Offset(-8, 0),
                  ),
                  BoxShadow(
                    color: widget.color2.withOpacity(0.2),
                    spreadRadius: 16,
                    blurRadius: 32,
                    offset: const Offset(8, 0),
                  ),
                ]
              : [],  // Tidak glowing setelah klik
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.text,  // Tampilkan teks dari properti text
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
