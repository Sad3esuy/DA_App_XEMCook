import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/recipe.dart';
import '../model/home_feed.dart';
import '../model/collection.dart';

class RecipeApiService {
  // static const String baseUrl = "https://be-da-xemcook-app.onrender.com/api/recipes";
  static const String baseUrl = "http://10.0.2.2:5000/api/recipes";
  // Lấy headers có token khi cần (cùng key với AuthService)
  static const String _tokenKey = 'auth_token';
  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static String resolveImageUrl(String? url) {
    if (url == null) return '';
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final origin = Uri.parse(baseUrl).replace(path: '');
    final relative = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    return origin.resolve(relative).toString();
  }

  static Map<String, dynamic> _buildBody(Recipe recipe) {
    final body = {
      'title': recipe.title,
      'description': recipe.description,
      'prepTime': recipe.prepTime,
      'cookTime': recipe.cookTime,
      'servings': recipe.servings,
      'difficulty': recipe.difficulty,
      'category': recipe.category,
      'imageUrl': recipe.imageUrl,
      'isFavorite': recipe.isFavorite,
      'isPublic': recipe.isPublic,
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
                'id': e.id,
                'step': e.step,
                'description': e.description,
                if (e.imageUrl != null && e.imageUrl!.isNotEmpty)
                  'imageUrl': e.imageUrl,
                if (e.imagePublicId != null && e.imagePublicId!.isNotEmpty)
                  'imagePublicId': e.imagePublicId,
              })
          .toList(),
    };
    // Nếu imageUrl là data URI thì gửi qua field imageUpload để backend upload Cloudinary
    if (recipe.imageUrl.startsWith('data:image')) {
      body['imageUpload'] = recipe.imageUrl;
    }
    return body;
  }

  /// GET all recipes
  static Future<List<Recipe>> getAllRecipes({
    String? search,
    String? category,
    String? difficulty,
    List<String>? tags,
    List<String>? dietTags,
    int? maxTotalTime,
    String? timeframe,
    String? timeframeTarget,
    String? sort,
    int? page,
    int? limit,
  }) async {
    try {
      final q = <String, String>{};
      if (search != null && search.isNotEmpty) q['search'] = search;
      if (category != null && category.isNotEmpty) q['category'] = category;
      if (difficulty != null && difficulty.isNotEmpty)
        q['difficulty'] = difficulty;
      if (tags != null && tags.isNotEmpty) q['tags'] = tags.join(',');
      if (dietTags != null && dietTags.isNotEmpty)
        q['dietTags'] = dietTags.join(',');
      if (maxTotalTime != null && maxTotalTime > 0)
        q['maxTotalTime'] = maxTotalTime.toString();
      if (timeframe != null && timeframe.isNotEmpty) q['timeframe'] = timeframe;
      if (timeframeTarget != null && timeframeTarget.isNotEmpty) {
        q['timeframeTarget'] = timeframeTarget;
      }
      if (sort != null && sort.isNotEmpty) q['sort'] = sort;
      if (page != null && page > 0) q['page'] = page.toString();
      if (limit != null && limit > 0) q['limit'] = limit.toString();
      final uri =
          Uri.parse(baseUrl).replace(queryParameters: q.isEmpty ? null : q);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['data'];
        return data.map((json) => Recipe.fromJson(json)).toList();
      } else {
        throw Exception(
            "Failed to load recipes (status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error fetching recipes: $e");
    }
  }

  /// GET search suggestions
  static Future<List<String>> getSearchSuggestions(
    String keyword, {
    int limit = 8,
  }) async {
    final query = keyword.trim();
    if (query.isEmpty) {
      return const <String>[];
    }
    try {
      final params = <String, String>{
        'q': query,
        'limit': limit.toString(),
      };
      final uri = Uri.parse('$baseUrl/search/suggestions')
          .replace(queryParameters: params);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>? ?? {};
        final data = body['data'] as List<dynamic>? ?? const [];
        final results = <String>[];
        for (final item in data) {
          final value = item.toString().trim();
          if (value.isEmpty) continue;
          final exists = results.any(
            (element) => element.toLowerCase() == value.toLowerCase(),
          );
          if (!exists) {
            results.add(value);
          }
        }
        return results;
      } else {
        throw Exception(
            'Failed to load search suggestions (status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching search suggestions: $e');
    }
  }

  /// GET aggregated home feed sections
  static Future<HomeFeed> getHomeFeed({String? season}) async {
    try {
      final headers = await _authHeaders();
      final query = <String, String>{};
      if (season != null && season.isNotEmpty) {
        query['season'] = season;
      }
      final uri = Uri.parse("$baseUrl/home").replace(
        queryParameters: query.isEmpty ? null : query,
      );
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final data = body['data'] as Map<String, dynamic>? ?? const {};
        return HomeFeed.fromJson(data);
      } else {
        throw Exception(
            "Failed to load home feed (status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error fetching home feed: $e");
    }
  }

  /// GET single recipe by ID
  static Future<Recipe> getRecipeById(String id) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/$id"),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final data = Map<String, dynamic>.from(
            body['data'] as Map<String, dynamic>? ?? const {});
        _normalizeRatingsPayload(data);
        return Recipe.fromJson(data);
      } else {
        throw Exception(
            "Failed to load recipe (status: ${response.statusCode})");
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
        headers: await _authHeaders(),
        body: json.encode(_buildBody(recipe)),
      );
      if (response.statusCode == 201) {
        final body = json.decode(response.body);
        return Recipe.fromJson(body['data']);
      } else {
        throw Exception(
            "Failed to create recipe (status: ${response.statusCode})");
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
        headers: await _authHeaders(),
        body: json.encode(_buildBody(recipe)),
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return Recipe.fromJson(body['data']);
      } else {
        throw Exception(
            "Failed to update recipe (status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error updating recipe: $e");
    }
  }

  /// DELETE recipe
  static Future<bool> deleteRecipe(String id) async {
    try {
      final response = await http.delete(Uri.parse("$baseUrl/$id"),
          headers: await _authHeaders());
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
            "Failed to delete recipe (status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error deleting recipe: $e");
    }
  }

  /// GET recipes by category
  static Future<List<Recipe>> getRecipesByCategory(String category) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl?category=$category"));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['data'];
        return data.map((json) => Recipe.fromJson(json)).toList();
      } else {
        throw Exception(
            "Failed to load recipes by category (status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error fetching recipes by category: $e");
    }
  }

  /// GET search recipes
  static Future<List<Recipe>> searchRecipes(String query) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl?search=$query"));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['data'];
        return data.map((json) => Recipe.fromJson(json)).toList();
      } else {
        throw Exception(
            "Failed to search recipes (status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error searching recipes: $e");
    }
  }

  /// POST toggle favorite
  static Future<bool> toggleFavorite(String id) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/$id/favorite"),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = json.decode(response.body);
        return body['data']?['isFavorite'] == true;
      } else {
        throw Exception(
            "Failed to toggle favorite (status: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error toggling favorite: $e");
    }
  }

  /// GET current user's favorites (list of recipes) + lấy thêm authorName, authorAvatar
  static Future<List<Recipe>> getFavorites(
      {int page = 1, int limit = 20}) async {
    try {
      final uri = Uri.parse("$baseUrl/favorites").replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });
      final response = await http.get(uri, headers: await _authHeaders());

      if (response.statusCode != 200) {
        throw Exception(
            "Failed to load favorites (status: ${response.statusCode})");
      }

      final body = json.decode(response.body) as Map<String, dynamic>? ?? {};
      final List<dynamic> rows = body['data'] ?? [];
      final recipes = <Recipe>[];

      for (final row in rows) {
        final r = (row is Map<String, dynamic>) ? row['recipe'] : null;
        if (r == null) continue;

        // Lấy thông tin tác giả nếu có
        final dynamic author = r['author'] ?? r['user'] ?? r['createdBy'];
        String authorName = '';
        String authorAvatar = '';

        if (author is Map<String, dynamic>) {
          authorName =
              author['name'] ?? author['fullName'] ?? author['username'] ?? '';
          authorAvatar =
              author['avatarUrl'] ?? author['avatar'] ?? author['photo'] ?? '';
        }

        // Gộp vào map của recipe
        final mapped = {
          'id': r['id']?.toString() ?? '',
          'title': r['title'] ?? '',
          'description': r['description'] ?? '',
          'prepTime': r['prepTime'] ?? 0,
          'cookTime': r['cookTime'] ?? 0,
          'servings': r['servings'] ?? 1,
          'difficulty': r['difficulty'] ?? 'medium',
          'category': r['category'] ?? 'other',
          'imageUrl': r['imageUrl'] ?? '',
          'isFavorite': true,
          'isPublic': r['isPublic'] ?? true,
          'tags':
              (r['tags'] is List) ? List<String>.from(r['tags']) : <String>[],
          'nutrition': (r['nutrition'] is Map)
              ? Map<String, dynamic>.from(r['nutrition'])
              : <String, dynamic>{},
          'createdAt': r['createdAt'] ?? DateTime.now().toIso8601String(),
          'updatedAt': r['updatedAt'] ??
              r['createdAt'] ??
              DateTime.now().toIso8601String(),
          'ingredients':
              (r['ingredients'] is List) ? r['ingredients'] : <dynamic>[],
          'instructions':
              (r['instructions'] is List) ? r['instructions'] : <dynamic>[],
          // ⭐️ Thêm 2 trường mới
          'authorName': authorName,
          'authorAvatar': authorAvatar,
        };

        recipes.add(Recipe.fromJson(mapped));
      }

      return recipes;
    } catch (e) {
      throw Exception("Error fetching favorites: $e");
    }
  }

  /// POST rate a recipe
  static Future<Map<String, dynamic>> rateRecipe(
    String id,
    int rating, {
    String? comment,
    String? imageBase64,
    String? imageUrl,
    bool removeImage = false,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'rating': rating,
      };
      if (comment != null) {
        final trimmed = comment.trim();
        body['comment'] = trimmed;
      }
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        body['imageUpload'] = imageBase64;
      }
      if (imageUrl != null && imageUrl.isNotEmpty) {
        body['imageUrl'] = imageUrl;
      }
      if (removeImage) {
        body['removeImage'] = true;
      }

      final response = await http.post(
        Uri.parse("$baseUrl/$id/rate"),
        headers: await _authHeaders(),
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] ?? {};
        final ratingData = _normalizeRating(data['rating']);
        return {
          'avgRating': (data['avgRating'] is num)
              ? (data['avgRating'] as num).toDouble()
              : double.tryParse('${data['avgRating']}') ?? 0.0,
          'totalRatings': data['totalRatings'] ?? 0,
          'totalImages': data['totalImages'] ?? 0,
          if (ratingData.isNotEmpty) 'rating': ratingData,
        };
      } else {
        throw Exception(
            'Failed to rate recipe (status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error rating recipe: $e');
    }
  }

  /// DELETE rating for a recipe
  static Future<Map<String, dynamic>> deleteRating(String recipeId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/$recipeId/rate"),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] ?? {};
        return {
          'avgRating': (data['avgRating'] is num)
              ? (data['avgRating'] as num).toDouble()
              : double.tryParse('${data['avgRating']}') ?? 0.0,
          'totalRatings': data['totalRatings'] ?? 0,
          'totalImages': data['totalImages'] ?? 0,
        };
      } else {
        throw Exception(
            'Failed to delete rating (status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error deleting rating: $e');
    }
  }

  /// GET paginated ratings for a recipe
  static Future<Map<String, dynamic>> getRecipeRatings(
    String id, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      final uri = Uri.parse("$baseUrl/$id/ratings").replace(
        queryParameters: params,
      );
      final response = await http.get(
        uri,
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final data = body['data'] as Map<String, dynamic>? ?? const {};
        final ratings = (data['ratings'] as List<dynamic>? ?? const [])
            .map(_normalizeRating)
            .where((map) => map.isNotEmpty)
            .toList();
        final imagesPreview =
            (data['imagesPreview'] as List<dynamic>? ?? const [])
                .map((item) {
                  if (item is Map<String, dynamic>) {
                    final map = Map<String, dynamic>.from(item);
                    final url = map['url']?.toString();
                    if (url != null && url.isNotEmpty) {
                      map['url'] = resolveImageUrl(url);
                    }
                    return map;
                  }
                  if (item is Map) {
                    final map = Map<String, dynamic>.from(item);
                    final url = map['url']?.toString();
                    if (url != null && url.isNotEmpty) {
                      map['url'] = resolveImageUrl(url);
                    }
                    return map;
                  }
                  if (item is String) {
                    final url = resolveImageUrl(item);
                    return url.isEmpty ? null : {'url': url};
                  }
                  return null;
                })
                .whereType<Map<String, dynamic>>()
                .toList();

        return {
          'recipe': data['recipe'] ?? const {},
          'page': data['page'] ?? page,
          'limit': data['limit'] ?? limit,
          'totalPages': data['totalPages'] ?? 0,
          'hasMore': data['hasMore'] ?? false,
          'avgRating': (data['avgRating'] is num)
              ? (data['avgRating'] as num).toDouble()
              : double.tryParse('${data['avgRating']}') ?? 0.0,
          'totalRatings': data['totalRatings'] ?? ratings.length,
          'totalImages': data['totalImages'] ?? imagesPreview.length,
          'ratings': ratings,
          'imagesPreview': imagesPreview,
        };
      } else {
        throw Exception(
            'Failed to fetch recipe ratings (status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching recipe ratings: $e');
    }
  }

  /// GET my recipes (requires auth)
  static Future<List<Recipe>> getMyRecipes(
      {int page = 1, int limit = 20}) async {
    try {
      final uri = Uri.parse("$baseUrl/my/recipes").replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });
      final response = await http.get(uri, headers: await _authHeaders());
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        return data.map((e) => Recipe.fromJson(e)).toList();
      }
      throw Exception(
          'Failed to load my recipes (status: ${response.statusCode})');
    } catch (e) {
      throw Exception('Error fetching my recipes: $e');
    }
  }

  /// GET my recipe detail (requires auth)
  static Future<Recipe> getMyRecipeDetail(String id) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/my/recipes/$id"),
          headers: await _authHeaders());
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final data = Map<String, dynamic>.from(
            body['data'] as Map<String, dynamic>? ?? const {});
        _normalizeRatingsPayload(data);
        return Recipe.fromJson(data);
      }
      throw Exception(
          'Failed to load my recipe detail (status: ${response.statusCode})');
    } catch (e) {
      throw Exception('Error fetching my recipe detail: $e');
    }
  }

  /// Create recipe from fields (no need to build Recipe model)
  static Future<Recipe> createRecipeFromFields({
    required String title,
    required String description,
    required String category,
    int prepTime = 0,
    int cookTime = 0,
    int servings = 1,
    String difficulty = 'medium',
    String? imageUrl,
    String? imageUpload,
    List<String>? tags,
    Map<String, dynamic>? nutrition,
    required List<Map<String, String>> ingredients,
    required List<Map<String, dynamic>> instructions,
    bool isPublic = false,
  }) async {
    final body = {
      'title': title,
      'description': description,
      'category': category,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      'difficulty': difficulty,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (imageUpload != null) 'imageUpload': imageUpload,
      'tags': tags ?? <String>[],
      'nutrition': nutrition ?? <String, dynamic>{},
      'ingredients': ingredients,
      'instructions': instructions,
      'isPublic': isPublic,
    };
    final res = await http.post(Uri.parse(baseUrl),
        headers: await _authHeaders(), body: json.encode(body));
    if (res.statusCode == 201) {
      final jsonBody = json.decode(res.body);
      return Recipe.fromJson(jsonBody['data']);
    }
    try {
      final jsonBody = json.decode(res.body);
      final msg =
          jsonBody['message'] ?? jsonBody['error'] ?? 'Failed to create recipe';
      throw Exception('$msg (status: ${res.statusCode})');
    } catch (_) {
      throw Exception('Failed to create recipe (status: ${res.statusCode})');
    }
  }

  /// Update recipe from fields
  static Future<Recipe> updateRecipeFromFields(
    String id, {
    String? title,
    String? description,
    String? category,
    int? prepTime,
    int? cookTime,
    int? servings,
    String? difficulty,
    String? imageUrl,
    String? imageUpload,
    List<String>? tags,
    Map<String, dynamic>? nutrition,
    List<Map<String, String>>? ingredients,
    List<Map<String, dynamic>>? instructions,
    bool? isPublic,
  }) async {
    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (prepTime != null) 'prepTime': prepTime,
      if (cookTime != null) 'cookTime': cookTime,
      if (servings != null) 'servings': servings,
      if (difficulty != null) 'difficulty': difficulty,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (imageUpload != null) 'imageUpload': imageUpload,
      if (tags != null) 'tags': tags,
      if (nutrition != null) 'nutrition': nutrition,
      if (ingredients != null) 'ingredients': ingredients,
      if (instructions != null) 'instructions': instructions,
      if (isPublic != null) 'isPublic': isPublic,
    };
    final res = await http.put(Uri.parse('$baseUrl/$id'),
        headers: await _authHeaders(), body: json.encode(body));
    if (res.statusCode == 200) {
      final jsonBody = json.decode(res.body);
      return Recipe.fromJson(jsonBody['data']);
    }
    try {
      final jsonBody = json.decode(res.body);
      final msg =
          jsonBody['message'] ?? jsonBody['error'] ?? 'Failed to update recipe';
      throw Exception('$msg (status: ${res.statusCode})');
    } catch (_) {
      throw Exception('Failed to update recipe (status: ${res.statusCode})');
    }
  }

  // ============================================
  // COLLECTION API METHODS
  // ============================================

  /// GET all collections of current user
  static Future<List<Collection>> getMyCollections(
      {int page = 1, int limit = 20}) async {
    try {
      final uri = Uri.parse("$baseUrl/collections").replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });
      final response = await http.get(uri, headers: await _authHeaders());
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        return data.map((e) => Collection.fromJson(e)).toList();
      }
      throw Exception(
          'Failed to load collections (status: ${response.statusCode})');
    } catch (e) {
      throw Exception('Error fetching collections: $e');
    }
  }

  /// GET collection detail by ID
  static Future<Collection> getCollectionById(String id) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/collections/$id"),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return Collection.fromJson(body['data']);
      }
      throw Exception(
          'Failed to load collection (status: ${response.statusCode})');
    } catch (e) {
      throw Exception('Error fetching collection: $e');
    }
  }

  /// POST create new collection
  static Future<Collection> createCollection({
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    try {
      final body = {
        'name': name,
        'description': description ?? '',
        'isPublic': isPublic,
      };
      final response = await http.post(
        Uri.parse("$baseUrl/collections"),
        headers: await _authHeaders(),
        body: json.encode(body),
      );
      if (response.statusCode == 201) {
        final responseBody = json.decode(response.body);
        return Collection.fromJson(responseBody['data']);
      }
      throw Exception(
          'Failed to create collection (status: ${response.statusCode})');
    } catch (e) {
      throw Exception('Error creating collection: $e');
    }
  }

  /// PUT update collection
  static Future<Collection> updateCollection(
    String id, {
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    try {
      final body = <String, dynamic>{
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (isPublic != null) 'isPublic': isPublic,
      };
      final response = await http.put(
        Uri.parse("$baseUrl/collections/$id"),
        headers: await _authHeaders(),
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        return Collection.fromJson(responseBody['data']);
      }
      throw Exception(
          'Failed to update collection (status: ${response.statusCode})');
    } catch (e) {
      throw Exception('Error updating collection: $e');
    }
  }

  /// DELETE collection
  static Future<bool> deleteCollection(String id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/collections/$id"),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        return true;
      }
      throw Exception(
          'Failed to delete collection (status: ${response.statusCode})');
    } catch (e) {
      throw Exception('Error deleting collection: $e');
    }
  }

  /// POST add recipe to collection
  static Future<bool> addRecipeToCollection(
      String collectionId, String recipeId) async {
    try {
      final body = {'recipeId': recipeId};
      final response = await http.post(
        Uri.parse("$baseUrl/collections/$collectionId/recipes"),
        headers: await _authHeaders(),
        body: json.encode(body),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }
      throw Exception(
          'Failed to add recipe to collection (status: ${response.statusCode})');
    } catch (e) {
      throw Exception('Error adding recipe to collection: $e');
    }
  }

  /// DELETE remove recipe from collection
  static Future<bool> removeRecipeFromCollection(
      String collectionId, String recipeId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/collections/$collectionId/recipes/$recipeId"),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        return true;
      }
      throw Exception(
          'Failed to remove recipe from collection (status: ${response.statusCode})');
    } catch (e) {
      throw Exception('Error removing recipe from collection: $e');
    }
  }

  static Map<String, dynamic> _normalizeRating(dynamic value) {
    if (value is! Map) return <String, dynamic>{};
    final map = Map<String, dynamic>.from(value);
    final imageUrl = map['imageUrl']?.toString();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      map['imageUrl'] = resolveImageUrl(imageUrl);
    }
    final reviewer = map['reviewer'];
    if (reviewer is Map && reviewer.isNotEmpty) {
      map['reviewer'] = Map<String, dynamic>.from(reviewer);
    }
    return map;
  }

  static void _normalizeRatingsPayload(Map<String, dynamic> data) {
    final ratings = data['ratings'];
    if (ratings is List) {
      data['ratings'] =
          ratings.map(_normalizeRating).where((map) => map.isNotEmpty).toList();
    }
    final preview = data['ratingImagesPreview'];
    if (preview is List) {
      data['ratingImagesPreview'] = preview
          .map((item) {
            if (item is Map<String, dynamic>) {
              final map = Map<String, dynamic>.from(item);
              final url = map['url']?.toString();
              if (url != null && url.isNotEmpty) {
                map['url'] = resolveImageUrl(url);
              }
              return map;
            }
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              final url = map['url']?.toString();
              if (url != null && url.isNotEmpty) {
                map['url'] = resolveImageUrl(url);
              }
              return map;
            }
            if (item is String) {
              final url = resolveImageUrl(item);
              return url.isEmpty ? null : {'url': url};
            }
            return null;
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    }
  }
}
