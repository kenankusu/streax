import 'package:flutter/material.dart';

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: Image.asset(
            'assets/animations/streax-loading.gif',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}