import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'recipe.dart';

class DatabaseHelper {
  static Database? _database;

  // Database version 3 adds the recipes table.
  static Future<Database> get database async {
    if (_database != null) return _database!;

    final path = join(
      await getDatabasesPath(),
      'growwell.db',
    );

    _database = await openDatabase(
      path,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE profiles (
            uid TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL
          )
        ''');

        await _createGrowthTables(db);
        await _createRecipesTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createGrowthTables(db);
        }

        if (oldVersion < 3) {
          await _createRecipesTable(db);
        }
      },
    );

    return _database!;
  }

  // ==========================================
  // GROWTH TABLES
  // ==========================================

  static Future<void> _createGrowthTables(Database db) async {
    await db.execute(
        'CREATE TABLE growth_children (id INTEGER PRIMARY KEY AUTOINCREMENT, owner TEXT NOT NULL, name TEXT NOT NULL, birth TEXT NOT NULL, sex TEXT NOT NULL)');
    await db.execute(
        'CREATE TABLE growth_measurements (id INTEGER PRIMARY KEY AUTOINCREMENT, child_id INTEGER NOT NULL, date TEXT NOT NULL, height REAL NOT NULL, weight REAL NOT NULL, method TEXT NOT NULL, FOREIGN KEY (child_id) REFERENCES growth_children(id))');
  }

  // ==========================================
  // RECIPES TABLE
  // ==========================================

  static Future<void> _createRecipesTable(Database db) async {
    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        image TEXT,
        time TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        description TEXT NOT NULL,
        ingredients TEXT NOT NULL,
        steps TEXT NOT NULL
      )
    ''');
  }

  // Add a recipe
  static Future<int> insertRecipe(Map<String, Object?> recipe) async {
    final db = await database;

    final data = Map<String, Object?>.from(recipe);
    data.remove('id');

    return await db.insert(
      'recipes',
      data,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // Retrieve all recipes
  static Future<List<Map<String, Object?>>> getRecipes() async {
    final db = await database;

    final result = await db.query(
      'recipes',
      orderBy: 'name ASC',
    );

    return result;
  }

  // Retrieve one recipe
  static Future<Map<String, Object?>?> getRecipeById(int id) async {
    final db = await database;

    final result = await db.query(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return result.first;
  }

  // Update a recipe
  static Future<int> updateRecipe(int id, Map<String, Object?> recipe) async {
    final db = await database;

    final data = Map<String, Object?>.from(recipe);
    data.remove('id');

    return await db.update(
      'recipes',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete a recipe
  static Future<int> deleteRecipe(int id) async {
    final db = await database;

    return await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  
  // ==========================================
  // DUMMY RECIPE DATA FOR TESTING
  // ==========================================

  static Future<void> seedDummyRecipes() async {
    final db = await database;

    // Do not insert duplicates if recipes already exist.
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM recipes'),
    );

    if (count != null && count > 0) return;

    final dummyRecipes = [
      Recipe(
        name: 'Banana Pancakes',
        category: 'Breakfast',
        image: null,
        time: '15 minutes',
        difficulty: 'Easy',
        description:
            'Fluffy banana pancakes made with simple ingredients. '
            'A delicious breakfast for the whole family.',
        ingredients: [
          '1 ripe banana',
          '1 egg',
          '1/2 cup all-purpose flour',
          '1/4 cup milk',
          '1/2 teaspoon baking powder',
          '1 teaspoon cooking oil',
        ],
        steps: [
          'Mash the banana in a bowl until smooth.',
          'Add the egg and milk, then mix well.',
          'Add flour and baking powder. Stir until combined.',
          'Heat a lightly oiled pan over medium heat.',
          'Pour a small amount of batter into the pan.',
          'Cook until bubbles appear, then flip and cook the other side.',
          'Serve warm.',
        ],
      ),

      Recipe(
        name: 'Chicken Vegetable Soup',
        category: 'Lunch',
        image: null,
        time: '30 minutes',
        difficulty: 'Easy',
        description:
            'A comforting chicken soup with fresh vegetables '
            'and a light, flavourful broth.',
        ingredients: [
          '150g chicken breast',
          '1 carrot, sliced',
          '1 potato, cubed',
          '1/2 cup cabbage',
          '2 cloves garlic',
          '500ml water or chicken stock',
          'Salt and pepper to taste',
        ],
        steps: [
          'Cut the chicken into small pieces.',
          'Heat a pot and lightly sauté the garlic.',
          'Add the chicken and cook until lightly browned.',
          'Pour in the water or chicken stock.',
          'Add carrots and potatoes.',
          'Simmer for 15 minutes.',
          'Add cabbage and cook until tender.',
          'Season and serve warm.',
        ],
      ),

      Recipe(
        name: 'Vegetable Fried Rice',
        category: 'Lunch',
        image: null,
        time: '20 minutes',
        difficulty: 'Easy',
        description:
            'A quick homemade fried rice with colourful vegetables. '
            'Perfect for using leftover rice.',
        ingredients: [
          '1 cup cooked rice',
          '1 egg',
          '1/4 cup diced carrots',
          '1/4 cup peas',
          '2 cloves garlic, minced',
          '1 tablespoon cooking oil',
          '1 tablespoon soy sauce',
        ],
        steps: [
          'Heat oil in a frying pan.',
          'Add garlic and sauté until fragrant.',
          'Add the egg and scramble.',
          'Add carrots and peas.',
          'Add cooked rice and stir well.',
          'Pour in soy sauce and mix evenly.',
          'Cook for another few minutes and serve.',
        ],
      ),

      Recipe(
        name: 'Steamed Fish with Ginger',
        category: 'Dinner',
        image: null,
        time: '25 minutes',
        difficulty: 'Medium',
        description:
            'A simple steamed fish dish with fresh ginger '
            'and light seasoning.',
        ingredients: [
          '1 medium fish fillet',
          '1 tablespoon sliced ginger',
          '1 spring onion',
          '1 tablespoon soy sauce',
          '1 teaspoon sesame oil',
          'A little water',
        ],
        steps: [
          'Clean and prepare the fish fillet.',
          'Place the fish on a heatproof plate.',
          'Arrange ginger slices over the fish.',
          'Prepare a steamer with boiling water.',
          'Steam the fish for 10 to 15 minutes, or until fully cooked.',
          'Add soy sauce and sesame oil.',
          'Garnish with spring onion and serve.',
        ],
      ),

      Recipe(
        name: 'Fresh Fruit Yogurt Bowl',
        category: 'Snacks',
        image: null,
        time: '10 minutes',
        difficulty: 'Easy',
        description:
            'A refreshing snack made with creamy yogurt '
            'and a variety of fresh fruits.',
        ingredients: [
          '1 cup plain yogurt',
          '1/2 banana, sliced',
          '1/4 cup strawberries',
          '1/4 cup diced mango',
          '1 tablespoon rolled oats',
        ],
        steps: [
          'Place yogurt into a serving bowl.',
          'Wash and prepare the fruits.',
          'Arrange banana, strawberries and mango over the yogurt.',
          'Sprinkle rolled oats on top.',
          'Serve immediately.',
        ],
      ),

      Recipe(
        name: 'Baked Sweet Potato',
        category: 'Snacks',
        image: null,
        time: '40 minutes',
        difficulty: 'Easy',
        description:
            'Naturally sweet and tender baked sweet potato. '
            'A simple snack with minimal preparation.',
        ingredients: [
          '1 medium sweet potato',
          '1 teaspoon olive oil',
          'A pinch of cinnamon (optional)',
        ],
        steps: [
          'Preheat the oven to 200°C.',
          'Wash and dry the sweet potato.',
          'Prick the skin several times with a fork.',
          'Rub lightly with olive oil.',
          'Bake for 35 to 40 minutes, or until tender.',
          'Allow to cool slightly before serving.',
        ],
      ),
    ];

    for (final recipe in dummyRecipes) {
      final data = recipe.toMap();
      data.remove('id');

      await db.insert('recipes', data);
    }
  }


  // ==========================================
  // USER PROFILE
  // ==========================================

  static Future<void> saveProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    final db = await database;

    await db.insert(
      'profiles',
      {
        'uid': uid,
        'name': name,
        'email': email,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
