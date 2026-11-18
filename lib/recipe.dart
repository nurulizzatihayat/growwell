import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color recipeOrange = Color(0xFFE45B64);
const Color recipeAmber = Color.fromARGB(255, 255, 159, 165);
const Color recipePanel = Color(0xFFF4F6FB);
const Color recipeChip = Color(0xFFEEF1F8);
const Color recipeText = Color(0xFF1F2430);
const Color recipeMuted = Color(0xFF8A94A6);

class Recipe {
  final String name;
  final String category;
  final String description;
  final String time;
  final String difficulty;
  final String emoji;
  final Color color;
  final List<String> ingredients;
  final List<String> steps;

  const Recipe({
    required this.name,
    required this.category,
    required this.description,
    required this.time,
    required this.difficulty,
    required this.emoji,
    required this.color,
    required this.ingredients,
    required this.steps,
  });
}

const List<Recipe> sampleRecipes = [
  Recipe(
    name: 'Yogurt Beri Segar',
    category: 'Sarapan',
    description: 'Yogurt berkrim dengan beri dan sedikit rangup.',
    time: '10 min',
    difficulty: 'Mudah',
    emoji: '🫐',
    color: Color(0xFFE8E5FA),
    ingredients: [
      '1 cawan greek yogurt',
      '1/2 cawan beri campuran (strawberi, blueberry, raspberry)',
      '2 sudu makan granola',
      '1 sudu teh honey (opsional)',
    ],
    steps: [
      'Masukkan yogurt ke dalam mangkuk.',
      'Cuci dan tambahkan beri campuran.',
      'Taburkan granola di atasnya.',
      'Tuangkan madu jika suka, lalu nikmati.',
    ],
  ),
  Recipe(
    name: 'Roti bakar Avocado',
    category: 'Sarapan',
    description: 'Toast sederhana dengan avocado krim.',
    time: '10 min',
    difficulty: 'Mudah',
    emoji: '🥑',
    color: Color(0xFFE2F0D9),
    ingredients: [
      '2 keping roti bakar',
      '1 avocado matang',
      'Sedikit lemon',
      'Garam dan lada secukupnya',
    ],
    steps: [
      'Bakar roti hingga keemasan.',
      'Hancurkan avocado dengan jus lemon.',
      'Oleskan avocado di atas toast.',
      'Bumbui dengan garam dan lada.',
    ],
  ),
  Recipe(
    name: 'Nasi Sayur Segar',
    category: 'Makan Siang',
    description: 'Sayuran berwarna-warni disajikan dengan nasi hangat.',
    time: '20 min',
    difficulty: 'Mudah',
    emoji: '🥗',
    color: Color(0xFFFFE9CF),
    ingredients: [
      '1 cawan nasi dimasak',
      '1/2 cawan timun dipotong dadu',
      '1/2 cawan lobak diiris halus',
      '1/2 cawan protein yang dimasak',
      'Sos kesukaan anda',
    ],
    steps: [
      'Letakkan nasi hangat dalam mangkuk.',
      'Susun sayuran dan protein di atasnya.',
      'Tambahkan sos kesukaan anda.',
      'Kocok semua bahan sebelum dimakan.',
    ],
  ),
  Recipe(
    name: 'Pasta Tomato berkrim',
    category: 'Makan Malam',
    description: 'Pasta yang mengenyangkan dengan saus tomat yang lembut.',
    time: '25 min',
    difficulty: 'Sederhana',
    emoji: '🍝',
    color: Color(0xFFF8DDE0),
    ingredients: [
      '150 g pasta',
      '1 cawan tomat dipotong',
      '1 siung bawang putih, dihaluskan',
      '2 sudu makan krim memasak',
      'Garam, lada dan herba',
    ],
    steps: [
      'Masak pasta mengikut arahan dalam bungkusan.',
      'Masak bawang putih dan tomat dalam sebuah kuali.',
      'Tambahkan krim dan perisa sesuai selera.',
      'Tambahkan pasta yang telah ditiriskan dan aduk rata.',
    ],
  ),
  Recipe(
    name: 'Bites Pisang & Oat',
    category: 'Jajan',
    description: 'Sedikit bites yang sihat dan manis untuk kudapan.',
    time: '18 min',
    difficulty: 'Mudah',
    emoji: '🍌',
    color: Color(0xFFFFF0C9),
    ingredients: [
      '1 pisang matang',
      '3/4 cawan rolled oats',
      'Seujud garam cinnamon',
      '1 sudu makan cebik coklat (pilihan)',
    ],
    steps: [
      'Panaskan ketuhar pada suhu 180°C.',
      'Hancurkan pisang di dalam mangkuk.',
      'Campurkan bijirin, serbuk kayu manis dan cebik coklat.',
      'Bentuk menjadi benda kecil dan panggang selama 12–15 minit.',
    ],
  ),
];

const List<String> recipeCategories = [
  'Semua',
  'Sarapan',
  'Makan Siang',
  'Makan Malam',
  'Jajan',
];

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  String _selectedCategory = 'Semua';
  String _searchText = '';
  final Set<String> _favourites = {};

  List<Recipe> get _filteredRecipes {
    final query = _searchText.toLowerCase().trim();

    return sampleRecipes.where((recipe) {
      final matchesCategory =
          _selectedCategory == 'Semua' || recipe.category == _selectedCategory;

      final matchesSearch =
          query.isEmpty ||
          recipe.name.toLowerCase().contains(query) ||
          recipe.category.toLowerCase().contains(query) ||
          recipe.ingredients.any(
            (ingredient) => ingredient.toLowerCase().contains(query),
          );

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        color: recipeOrange,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Container(
                  color: recipePanel,
                  child: Column(
                    children: [
                      _buildSearchAndCategories(),
                      Expanded(child: _buildRecipeList()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(Icons.restaurant_menu_rounded, color: recipeOrange),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resipi Sihat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Resipi sihat untuk kesihatan anak anda',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndCategories() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchText = value),
            decoration: InputDecoration(
              hintText: 'Cari resepi atau bahan...',
              hintStyle: const TextStyle(color: recipeMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: recipeMuted),
              filled: true,
              fillColor: recipeChip,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: recipeOrange, width: 1.3),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recipeCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = recipeCategories[index];
                final selected = category == _selectedCategory;

                return ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: recipeAmber,
                  backgroundColor: recipeChip,
                  side: BorderSide.none,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : recipeText,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) {
                    setState(() => _selectedCategory = category);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeList() {
    final recipes = _filteredRecipes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            Text(
              '${recipes.length} resepi',
              style: const TextStyle(color: recipeMuted, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recipes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48, horizontal: 20),
            child: Text(
              'Tiada resepi ditemui. Cuba carian lain ♡',
              textAlign: TextAlign.center,
              style: TextStyle(color: recipeMuted, fontSize: 15),
            ),
          )
        else
          for (final recipe in recipes)
            RecipeCard(
              recipe: recipe,
              isFavourite: _favourites.contains(recipe.name),
              onFavouriteTap: () {
                setState(() {
                  if (!_favourites.add(recipe.name)) {
                    _favourites.remove(recipe.name);
                  }
                });
              },
            ),
      ],
    );
  }
}

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool isFavourite;
  final VoidCallback onFavouriteTap;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.isFavourite,
    required this.onFavouriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: recipeChip,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  recipe.category,
                  style: const TextStyle(
                    color: recipeOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: isFavourite
                    ? 'Buang dari kegemaran'
                    : 'Tambah ke kegemaran',
                onPressed: onFavouriteTap,
                icon: Icon(
                  isFavourite ? Icons.favorite : Icons.favorite_border,
                  color: isFavourite ? Colors.redAccent : recipeMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 104,
                  height: 100,
                  color: recipe.color,
                  alignment: Alignment.center,
                  child: Text(
                    recipe.emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        color: recipeText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      recipe.description,
                      style: const TextStyle(
                        color: recipeMuted,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: recipeOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe.time,
                          style: const TextStyle(
                            color: recipeText,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.signal_cellular_alt_rounded,
                          size: 15,
                          color: recipeOrange,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            recipe.difficulty,
                            style: const TextStyle(
                              color: recipeText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: recipeOrange,
                side: const BorderSide(color: recipeAmber),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RecipeDetailPage(recipe: recipe),
                  ),
                );
              },
              child: const Text(
                'Lihat resipi  →',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecipeDetailPage extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailPage({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: recipeOrange,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 18),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Maklumat Resipi',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Container(
                  color: recipePanel,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                    children: [
                      Container(
                        height: 190,
                        decoration: BoxDecoration(
                          color: recipe.color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          recipe.emoji,
                          style: const TextStyle(fontSize: 88),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        recipe.name,
                        style: const TextStyle(
                          color: recipeText,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recipe.description,
                        style: const TextStyle(
                          color: recipeMuted,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _RecipeInfoPill(
                            icon: Icons.schedule_rounded,
                            text: recipe.time,
                          ),
                          _RecipeInfoPill(
                            icon: Icons.signal_cellular_alt_rounded,
                            text: recipe.difficulty,
                          ),
                          _RecipeInfoPill(
                            icon: Icons.sell_outlined,
                            text: recipe.category,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Bahan-bahan',
                        style: TextStyle(
                          color: recipeText,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...recipe.ingredients.map(
                        (ingredient) => Padding(
                          padding: const EdgeInsets.only(bottom: 11),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: recipeOrange,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  ingredient,
                                  style: const TextStyle(
                                    color: recipeText,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Mari kita buat!',
                        style: TextStyle(
                          color: recipeText,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(recipe.steps.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: recipeAmber,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(
                                    recipe.steps[index],
                                    style: const TextStyle(
                                      color: recipeText,
                                      fontSize: 14,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      const Text(
                        'Nikmati makanan anda!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: recipeOrange,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeInfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RecipeInfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: recipeOrange),
      label: Text(text),
      backgroundColor: Colors.white,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      labelStyle: const TextStyle(color: recipeText, fontSize: 12),
    );
  }
}
