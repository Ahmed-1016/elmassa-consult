import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';

class TextAnimationWidget extends StatelessWidget {
  const TextAnimationWidget({super.key});

  Future<List<AnimatedText>> _generateTextAnimations() async {
    await Future.delayed(const Duration(milliseconds: 2));
    return [
      TyperAnimatedText(
        '.A place you trust',
        textStyle: TextStyle(color: const Color.fromARGB(255, 33, 43, 96)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AnimatedText>>(
      future: _generateTextAnimations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return DefaultTextStyle(
            style: const TextStyle(
              fontSize: 28,
              color: Colors.black54,
              fontWeight: FontWeight.w900,
            ),
            child: AnimatedTextKit(
              animatedTexts: snapshot.data ?? [],
              totalRepeatCount: 1000, // 0 means animation runs indefinitely
            ),
          );
        } else {
          return const CircularProgressIndicator(); // Show a loading indicator
        }
      },
    );
  }
}
