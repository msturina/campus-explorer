import 'package:flutter/material.dart';
import 'markers_page.dart'; // Import fail markers_page

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MarkersPage(), // Panggil class dari markers_page.dart
    ));