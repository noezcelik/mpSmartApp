import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

import '../constants/color.dart';

class ObscuredTextFieldSample extends StatelessWidget {
  const ObscuredTextFieldSample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 75,
      height: 29,
      child: Container(
        alignment: Alignment.center,
        child: TextField(
          obscureText: false,
          decoration: InputDecoration(
            border: UnderlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            filled: true,
            fillColor: HexColor(bcon),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 17),
          ),
        ),
      ),
    );
  }
}
