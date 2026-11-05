import 'package:flutter/material.dart';
import 'database.dart';
import 'recipe.dart';

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

  List<Recipe> recipes = [];

  final Set<String> favourites = {};

  String selectedCategory = 'Semua';
  String searchText = '';

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadRecipes();
  }

  // Load recipes from SQLite.
  Future<void> loadRecipes() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = (await DatabaseHelper.getRecipes())
          .map((row) => Recipe.fromMap(row))
          .toList();

      if (!mounted) return;

      setState(() {
        recipes = result;
        isLoading = false;

        // Reset category if it no longer exists.
        final availableCategories =
            result.map((recipe) => recipe.category).toSet();

        if (selectedCategory != 'All' &&
            !availableCategories.contains(selectedCategory)) {
          selectedCategory = 'All';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to load recipes. Please try again.';
      });

      debugPrint('Error loading recipes: $e');
    }
  }

  // Create category list from database recipes.
  List<String> get categories {
    final recipeCategories =
        recipes.map((recipe) => recipe.category).toSet().toList()..sort();

    return ['All', ...recipeCategories];
  }

  // Filter recipes using category and search.
  List<Recipe> get filteredRecipes {
    final query = searchText.toLowerCase().trim();

    return recipes.where((recipe) {
      final matchesCategory =
          selectedCategory == 'All' || recipe.category == selectedCategory;

      final matchesSearch = query.isEmpty ||
          recipe.name.toLowerCase().contains(query) ||
          recipe.category.toLowerCase().contains(query) ||
          recipe.description.toLowerCase().contains(query) ||
          recipe.ingredients.any(
            (ingredient) => ingredient.toLowerCase().contains(query),
          );

      return matchesCategory && matchesSearch;
    }).toList();
  }

  String _recipeKey(Recipe recipe) {
    return recipe.id?.toString() ?? recipe.name;
  }

  void toggleFavourite(Recipe recipe) {
    setState(() {
      final key = _recipeKey(recipe);

      if (!favourites.add(key)) {
        favourites.remove(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayedRecipes = filteredRecipes;

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: rose,
          onRefresh: loadRecipes,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header and search section
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
                                  'ANAK SIHAT ANAK HEBAT  ✿',
                                  style: TextStyle(
                                    color: rose,
                                    fontSize: 11,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 7),
                                Text(
                                  'Resipi Sihat & Sedap',
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
                                    'Makan dengan sihat, rasa dengan baik.',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: ink,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Dapatkan idea resipi yang sihat dan sedap'
                                    'untuk keluarga anda. Dari sarapan hingga makan malam, kami ada semuanya!',
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
                            const Icon(
                              Icons.restaurant_rounded,
                              size: 43,
                              color: rose,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Search
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(0xFFEEEEF0),
                          ),
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              searchText = value;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Cari resipi, bahan, atau kategori',
                            hintStyle: TextStyle(
                              color: muted,
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: rose,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 23),

                      // Categories
                      const Text(
                        'Teroka kategori',
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
                              'Ideas terkini untuk anda',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: ink,
                              ),
                            ),
                          ),
                          Text(
                            '${displayedRecipes.length} recipes',
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

              // Loading indicator
              if (isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: rose,
                    ),
                  ),
                )

              // Error message
              else if (errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Ada yang tidak kena',
                    message: errorMessage!,
                    buttonText: 'Cuba lagi',
                    onPressed: loadRecipes,
                  ),
                )

              // No recipes in database
              else if (recipes.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: 'Tiada resipi tersedia lagi',
                    message: 'Pasukan kami sedang menyiapkan resipi sedap untuk anda. '
                        'Sila periksa semula kemudian.',
                  ),
                )

              // No search results
              else if (displayedRecipes.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No recipes found',
                    message: 'Try another search or category.',
                  ),
                )

              // Recipe grid
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final recipe = displayedRecipes[index];

                        return _RecipeGridCard(
                          recipe: recipe,
                          isFavourite: favourites.contains(
                            _recipeKey(recipe),
                          ),
                          onFavouriteTap: () {
                            toggleFavourite(recipe);
                          },
                        );
                      },
                      childCount: displayedRecipes.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
      ),
    );
  }
}

// ==========================================
// EMPTY AND ERROR STATES
// ==========================================

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onPressed,
  });

  static const Color rose = Color(0xFFE45B64);
  static const Color ink = Color(0xFF25252B);
  static const Color muted = Color(0xFF85858D);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: rose,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: ink,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (buttonText != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: rose,
                  foregroundColor: Colors.white,
                ),
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==========================================
// RECIPE IMAGE
// ==========================================

class _RecipeImage extends StatelessWidget {
  final String? image;
  final double? height;

  const _RecipeImage({
    required this.image,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = image?.trim() ?? '';

    if (imagePath.isEmpty) {
      return _placeholder();
    }

    final uri = Uri.tryParse(imagePath);
    final isNetworkImage =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

    if (isNetworkImage) {
      return Image.network(
        imagePath,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    return Image.asset(
      imagePath,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: height,
      color: const Color(0xFFFFF0F1),
      alignment: Alignment.center,
      child: const Icon(
        Icons.restaurant_rounded,
        color: Color(0xFFE45B64),
        size: 42,
      ),
    );
  }
}

// ==========================================
// RECIPE CARD
// ==========================================

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
                  Positioned.fill(
                    child: _RecipeImage(
                      image: recipe.image,
                    ),
                  ),

                  // Favourite button
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

                  // Category label
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

// ==========================================
// RECIPE DETAILS
// ==========================================

class RecipeDetailPage extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailPage({
    super.key,
    required this.recipe,
  });

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
          // Recipe picture
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _RecipeImage(
              image: recipe.image,
              height: 220,
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

          // Cooking information
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
                Icon(
                  Icons.favorite_border_rounded,
                  color: rose,
                  size: 22,
                ),
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

// ==========================================
// RECIPE INFORMATION BOX
// ==========================================

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
