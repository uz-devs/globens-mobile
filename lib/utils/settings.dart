import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

final String grpc_host = '192.168.200.182';
final int grpc_port = 50052;

Widget getTitleWidget(String text, {Color textColor = Colors.blue}) {
  return Container(
    margin: EdgeInsets.only(left: 10.0, top: 5.0, right: 10.0, bottom: 20.0),
    child: Text(
      text,
      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: textColor),
    ),
  );
}
