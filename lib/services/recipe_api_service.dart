import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/recipe.dart';

class RecipeApiService {
  static const String baseUrl = "http://10.0.2.2:5000/api/recipes";

  static Map<String, dynamic> _buildBody(Recipe recipe) {
    return {
      'title': recipe.title,
      'description': recipe.description,
      'prepTime': recipe.prepTime,
      'cookTime': recipe.cookTime,
      'servings': recipe.servings,
      'difficulty': recipe.difficulty,
      'category': recipe.category,
      'imageUrl': recipe.imageUrl,
      'isFavorite': recipe.isFavorite,
      'tags': recipe.tags,
      'nutrition': recipe.nutrition,
      'ingredients': recipe.ingredients
          .map((e) => {
                'name': e.name,
                'quantity': e.quantity,
                'unit': e.unit,
              })
          .toList(),
      'instructions': recipe.instructions
          .map((e) => {
                'step': e.step,
                'description': e.description,
              })
          .toList(),
    };
  }

  /// GET all recipes
  static Future<List<Recipe>> getAllRecipes() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['data'];
        return data.map((json) => Recipe.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load recipes (status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error fetching recipes: $e");
    }
  }

  /// GET single recipe by ID
  static Future<Recipe> getRecipeById(String id) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/$id"));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return Recipe.fromJson(body['data']);
      } else {
        throw Exception("Failed to load recipe (status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error fetching recipe by ID: $e");
    }
  }

  /// POST create new recipe
  static Future<Recipe> createRecipe(Recipe recipe) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(_buildBody(recipe)),
      );
      if (response.statusCode == 201) {
        final body = json.decode(response.body);
        return Recipe.fromJson(body['data']);
      } else {
        throw Exception("Failed to create recipe (status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error creating recipe: $e");
    }
  }

  /// PUT update recipe
  static Future<Recipe> updateRecipe(String id, Recipe recipe) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/$id"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(_buildBody(recipe)),
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return Recipe.fromJson(body['data']);
      } else {
        throw Exception("Failed to update recipe (status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error updating recipe: $e");
    }
  }

  /// DELETE recipe
  static Future<bool> deleteRecipe(String id) async {
    try {
      final response = await http.delete(Uri.parse("$baseUrl/$id"));
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception("Failed to delete recipe (status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error deleting recipe: $e");
    }
  }

  /// GET recipes by category
  static Future<List<Recipe>> getRecipesByCategory(String category) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/category/$category"));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['data'];
        return data.map((json) => Recipe.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load recipes by category (status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error fetching recipes by category: $e");
    }
  }

  /// GET search recipes
  static Future<List<Recipe>> searchRecipes(String query) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/search/$query"));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['data'];
        return data.map((json) => Recipe.fromJson(json)).toList();
      } else {
        throw Exception("Failed to search recipes (status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error searching recipes: $e");
    }
  }

  /// POST toggle favorite
  static Future<Recipe> toggleFavorite(String id) async {
    try {
      final response = await http.post(Uri.parse("$baseUrl/$id/favorite"));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return Recipe.fromJson(body['data']);
      } else {
        throw Exception("Failed to toggle favorite (status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error toggling favorite: $e");
    }
  }
}
