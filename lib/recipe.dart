
import 'dart:convert';

class Recipe {
  final int? id;
  final String name;
  final String category;

  // Nullable because a recipe may not have a picture yet.
  final String? image;

  final String time;
  final String difficulty;
  final String description;
  final List<String> ingredients;
  final List<String> steps;

  const Recipe({
    this.id,
    required this.name,
    required this.category,
    this.image,
    required this.time,
    required this.difficulty,
    required this.description,
    required this.ingredients,
    required this.steps,
  });

  // Convert recipe into database format.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'image': image,
      'time': time,
      'difficulty': difficulty,
      'description': description,
      'ingredients': jsonEncode(ingredients),
      'steps': jsonEncode(steps),
    };
  }

  // Convert database data into a Recipe object.
  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      image: map['image'] as String?,
      time: map['time'] as String,
      difficulty: map['difficulty'] as String,
      description: map['description'] as String,
      ingredients: List<String>.from(
        jsonDecode(map['ingredients'] as String),
      ),
      steps: List<String>.from(
        jsonDecode(map['steps'] as String),
      ),
    );
  }
}
