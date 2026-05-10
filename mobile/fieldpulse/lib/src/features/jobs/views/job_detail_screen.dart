import 'package:flutter/material.dart';

class JobDetailScreen extends StatelessWidget {
  final int jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Job Detail')),
      body: const Center(child: Text('Job Detail')),
    );
  }
}
