class Hobby {
  final String title;
  final String? memo;
  final String imageFileName;

  Hobby({
    required this.title,
    this.memo,
    required this.imageFileName,
  });

  String getImagePath(String basePath) {
    return '$basePath/images/$imageFileName';
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'memo': memo,
    'imageFileName': imageFileName,
  };

  factory Hobby.fromJson(Map<String, dynamic> json) => Hobby(
    title: json['title'] as String,
    memo: json['memo'] as String?,
    imageFileName: json['imageFileName'] as String,
  );
}
