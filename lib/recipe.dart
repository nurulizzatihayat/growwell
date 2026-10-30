import 'package:flutter/material.dart';

class Recipe {
  final String name;
  final String category;
  final List<String> ingredients;
  final Color color;
  final String emoji;
  final String time;
  final String description;
  final String difficulty;
  final List<String> steps;

  const Recipe({
    required this.name,
    required this.category,
    required this.ingredients,
    required this.color,
    required this.emoji,
    required this.time,
    required this.description,
    required this.difficulty,
    required this.steps,
  });
}

const List<String> categories = [
  'All',
  'Breakfast',
  'Lunch',
  'Dinner',
  'Snacks',
];

const List<Recipe> sampleRecipes = [
  Recipe(
    name: 'Berry Overnight Oats',
    category: 'Breakfast',
    ingredients: ['Rolled oats', 'Milk', 'Greek yogurt', 'Mixed berries'],
    color: Color(0xFFFFE6E8),
    emoji: '🥣',
    time: '10 min + chill',
    description: 'A creamy, make-ahead breakfast with fresh berries.',
    difficulty: 'Easy',
    steps: [
      'Combine the oats, milk, and yogurt in a jar.',
      'Stir well, cover, and refrigerate overnight.',
      'Top with mixed berries before serving.',
    ],
  ),
  Recipe(
    name: 'Avocado Toast',
    category: 'Breakfast',
    ingredients: ['Whole-grain bread', 'Ripe avocado', 'Lemon juice', 'Pepper'],
    color: Color(0xFFE5F0DC),
    emoji: '🥑',
    time: '10 min',
    description: 'Crisp toast topped with creamy, citrusy avocado.',
    difficulty: 'Easy',
    steps: [
      'Toast the bread until golden.',
      'Mash avocado with lemon juice and pepper.',
      'Spread over toast and serve immediately.',
    ],
  ),
  Recipe(
    name: 'Rainbow Quinoa Salad',
    category: 'Lunch',
    ingredients: ['Quinoa', 'Cucumber', 'Cherry tomatoes', 'Lemon dressing'],
    color: Color(0xFFFFF0D8),
    emoji: '🥗',
    time: '25 min',
    description: 'A colorful, nourishing salad with a bright lemon dressing.',
    difficulty: 'Easy',
    steps: [
      'Cook the quinoa according to the package directions and cool.',
      'Chop the cucumber and halve the cherry tomatoes.',
      'Toss everything with lemon dressing and serve.',
    ],
  ),
  Recipe(
    name: 'Creamy Tomato Pasta',
    category: 'Dinner',
    ingredients: ['Pasta', 'Tomatoes', 'Cream', 'Fresh basil'],
    color: Color(0xFFFFE5D9),
    emoji: '🍝',
    time: '30 min',
    description: 'Comforting pasta in a simple tomato and basil sauce.',
    difficulty: 'Easy',
    steps: [
      'Cook the pasta in salted water until tender.',
      'Simmer tomatoes, then stir in cream and chopped basil.',
      'Toss the sauce with drained pasta and serve.',
    ],
  ),
  Recipe(
    name: 'Apple Peanut Butter Bites',
    category: 'Snacks',
    ingredients: ['Apple', 'Peanut butter', 'Rolled oats', 'Cinnamon'],
    color: Color(0xFFFFF1D6),
    emoji: '🍎',
    time: '10 min',
    description: 'A quick sweet-and-crunchy snack for any time of day.',
    difficulty: 'Easy',
    steps: [
      'Slice the apple into bite-sized wedges.',
      'Spread each wedge with a little peanut butter.',
      'Sprinkle with oats and cinnamon.',
    ],
  ),
];

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  static const Color rose = Color(0xFFE45B64);
  static const Color lightRose = Color(0xFFFFF0F1);
  static const Color ink = Color(0xFF25252B);
  static const Color muted = Color(0xFF85858D);
  static const Color pageBg = Color(0xFFF9F9FA);

  String selectedCategory = 'All';
  String searchText = '';
  final Set<String> favourites = {};

  @override
  Widget build(BuildContext context) {
    final filteredRecipes = sampleRecipes.where((recipe) {
      final matchesCategory =
          selectedCategory == 'All' || recipe.category == selectedCategory;

      final query = searchText.toLowerCase().trim();

      final matchesSearch = recipe.name.toLowerCase().contains(query) ||
          recipe.category.toLowerCase().contains(query) ||
          recipe.ingredients.any(
            (item) => item.toLowerCase().contains(query),
          );

      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'GROWWELL  ✿',
                                style: TextStyle(
                                  color: rose,
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 7),
                              Text(
                                'Recipes',
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: lightRose,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.restaurant_menu_rounded,
                            color: rose,
                            size: 25,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Intro banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: lightRose,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Eat well, feel well.',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: ink,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Discover simple and delicious ideas '
                                  'for your everyday meals.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                    color: muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('🥗', style: TextStyle(fontSize: 48)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Search
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFFEEEEF0)),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() => searchText = value);
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search recipes or ingredients',
                          hintStyle: TextStyle(
                            color: muted,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: rose,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 23),

                    // Categories
                    const Text(
                      'Explore categories',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = category == selectedCategory;

                          return ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            showCheckmark: false,
                            selectedColor: rose,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color:
                                  isSelected ? rose : const Color(0xFFEEEEF0),
                            ),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) {
                              setState(() {
                                selectedCategory = category;
                              });
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 23),

                    // Recipe heading
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Fresh ideas for you',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ink,
                            ),
                          ),
                        ),
                        Text(
                          '${filteredRecipes.length} recipes',
                          style: const TextStyle(
                            color: muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // Recipe grid
            if (filteredRecipes.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🍽️', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text(
                        'No recipes found',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: ink,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Try another search or category.',
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final recipe = filteredRecipes[index];

                      return _RecipeGridCard(
                        recipe: recipe,
                        isFavourite: favourites.contains(recipe.name),
                        onFavouriteTap: () {
                          setState(() {
                            if (!favourites.add(recipe.name)) {
                              favourites.remove(recipe.name);
                            }
                          });
                        },
                      );
                    },
                    childCount: filteredRecipes.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.68,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Recipe card
class _RecipeGridCard extends StatelessWidget {
  final Recipe recipe;
  final bool isFavourite;
  final VoidCallback onFavouriteTap;

  const _RecipeGridCard({
    required this.recipe,
    required this.isFavourite,
    required this.onFavouriteTap,
  });

  static const Color rose = Color(0xFFE45B64);
  static const Color ink = Color(0xFF25252B);
  static const Color muted = Color(0xFF85858D);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RecipeDetailPage(recipe: recipe),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: recipe.color,
                    alignment: Alignment.center,
                    child: Text(
                      recipe.emoji,
                      style: const TextStyle(fontSize: 55),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onFavouriteTap,
                        child: Padding(
                          padding: const EdgeInsets.all(7),
                          child: Icon(
                            isFavourite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavourite ? rose : muted,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 9,
                    left: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        recipe.category,
                        style: const TextStyle(
                          color: rose,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 11, 11, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: rose,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          recipe.time,
                          style: const TextStyle(
                            fontSize: 10,
                            color: muted,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: rose,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recipe details
class RecipeDetailPage extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  static const Color rose = Color(0xFFE45B64);
  static const Color lightRose = Color(0xFFFFF0F1);
  static const Color ink = Color(0xFF25252B);
  static const Color muted = Color(0xFF85858D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: ink,
        elevation: 0,
        title: const Text(
          'Recipe details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          // Recipe illustration
          Container(
            height: 210,
            decoration: BoxDecoration(
              color: recipe.color,
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: Text(
              recipe.emoji,
              style: const TextStyle(fontSize: 95),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            recipe.category.toUpperCase(),
            style: const TextStyle(
              color: rose,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            recipe.name,
            style: const TextStyle(
              color: ink,
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            recipe.description,
            style: const TextStyle(
              color: muted,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 18),

          // Recipe information
          Row(
            children: [
              Expanded(
                child: _RecipeInfoBox(
                  icon: Icons.schedule_rounded,
                  title: 'Cooking time',
                  value: recipe.time,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RecipeInfoBox(
                  icon: Icons.signal_cellular_alt_rounded,
                  title: 'Difficulty',
                  value: recipe.difficulty,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          const Text(
            'Ingredients',
            style: TextStyle(
              color: ink,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 13),

          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: recipe.ingredients.map((ingredient) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: rose,
                        size: 19,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          ingredient,
                          style: const TextStyle(
                            color: ink,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 27),

          const Text(
            'Preparation',
            style: TextStyle(
              color: ink,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          ...List.generate(recipe.steps.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 17),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: lightRose,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: rose,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        recipe.steps[index],
                        style: const TextStyle(
                          color: ink,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: lightRose,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('♡', style: TextStyle(color: rose, fontSize: 22)),
                SizedBox(width: 9),
                Text(
                  'Enjoy your meal!',
                  style: TextStyle(
                    color: rose,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small information boxes
class _RecipeInfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _RecipeInfoBox({
    required this.icon,
    required this.title,
    required this.value,
  });

  static const Color rose = Color(0xFFE45B64);
  static const Color ink = Color(0xFF25252B);
  static const Color muted = Color(0xFF85858D);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: rose, size: 20),
          const SizedBox(height: 9),
          Text(
            title,
            style: const TextStyle(
              color: muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: ink,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
