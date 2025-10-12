/// Model Instruction - Hướng dẫn nấu ăn
class Instruction {
  final String id;
  final int step;
  final String description;
  final String recipeId;

  Instruction({
    required this.id,
    required this.step,
    required this.description,
    required this.recipeId,
  });

  factory Instruction.fromJson(Map<String, dynamic> json) {
    return Instruction(
      id: json['id'],
      step: json['step'],
      description: json['description'],
      recipeId: json['recipeId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'step': step,
      'description': description,
      'recipeId': recipeId,
    };
  }
}