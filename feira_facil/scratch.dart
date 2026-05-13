import 'package:flutter/material.dart'; Widget foo(BuildContext context) { final x = 1; return Text('a', style: TextStyle(color: x == 1 ? Colors.red : Colors.blue)); }
