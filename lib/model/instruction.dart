/// Model Instruction - Hướng dẫn nấu ăn
class Instruction {
  final String id;
  final int step;
  final String description;
  final String recipeId;
  final String? imageUrl;
  final String? imagePublicId;

  Instruction({
    required this.id,
    required this.step,
    required this.description,
    required this.recipeId,
    this.imageUrl,
    this.imagePublicId,
  });

  factory Instruction.fromJson(Map<String, dynamic> json) {
    return Instruction(
      id: json['id']?.toString() ?? '',
      step: json['step'] is int ? json['step'] : int.tryParse(json['step']?.toString() ?? '0') ?? 0,
      description: json['description']?.toString() ?? '',
      recipeId: json['recipeId']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      imagePublicId: json['imagePublicId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'step': step,
      'description': description,
      'recipeId': recipeId,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (imagePublicId != null) 'imagePublicId': imagePublicId,
    };
  }
}
