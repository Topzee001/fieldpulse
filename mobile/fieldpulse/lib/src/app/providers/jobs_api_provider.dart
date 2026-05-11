import 'package:fieldpulse/src/data/remote/endpoints/jobs_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_provider.dart';

final jobsApiProvider = Provider((ref) => JobsApi(ref.read(dioProvider)));
