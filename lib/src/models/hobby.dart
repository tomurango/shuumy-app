import 'package:uuid/uuid.dart';

class Hobby {
  final String id;
  final String title;
  final String? memo;
  final String imageFileName;

  Hobby({
    required this.id,
    required this.title,
    this.memo,
    required this.imageFileName,
  });

  String getImagePath(String basePath) {
    return '$basePath/images/$imageFileName';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'memo': memo,
    'imageFileName': imageFileName,
  };

  factory Hobby.fromJson(Map<String, dynamic> json) => Hobby(
    id: json['id'] as String? ?? const Uuid().v4(),
    title: json['title'] as String,
    memo: json['memo'] as String?,
    imageFileName: json['imageFileName'] as String,
  );
}
