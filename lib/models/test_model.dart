// lib/test_model.dart
import 'package:hive/hive.dart';

part 'test_model.g.dart';

@HiveType(typeId: 99)
class TestModel extends HiveObject {
  @HiveField(0)
  String name;

  TestModel({required this.name});
}
