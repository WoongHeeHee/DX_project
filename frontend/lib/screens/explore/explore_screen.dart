import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../data/services/recommendation_service.dart';
import '../../data/services/market_service.dart';
import '../../data/models/menu_models.dart';
import '../../data/models/market_models.dart';
import '../../models/enums.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<MenuItemModel> _trendingMenus = [];
  List<MenuItemModel> _personalRecommendations = [];
  List<MenuItemModel> _categoryMenus = [];
  List<MarketModel> _markets = [];
  MenuCategory _selectedCategory = MenuCategory.meals;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final recommendationService =
          Provider.of<RecommendationService>(context, listen: false);
      final marketService = Provider.of<MarketService>(context, listen: false);

      final results = await Future.wait([
        recommendationService.getRecommendations(limit: 3),
        recommendationService.getTrendingMenus(limit: 3),
        recommendationService.getRecommendations(
            category: _selectedCategory.value, limit: 10),
        marketService.getMarkets(),
      ]);

      setState(() {
        _personalRecommendations = results[0] as List<MenuItemModel>;
        _trendingMenus = results[1] as List<MenuItemModel>;
        _categoryMenus = results[2] as List<MenuItemModel>;
        _markets = results[3] as List<MarketModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 실패: $e')),
        );
      }
    }
  }

  Future<void> _loadCategoryMenus() async {
    try {
      final recommendationService =
          Provider.of<RecommendationService>(context, listen: false);
      final menus = await recommendationService.getRecommendations(
          category: _selectedCategory.value, limit: 10);
      setState(() {
        _categoryMenus = menus;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카테고리 메뉴 로드 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('탐색'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 국적-나이 별 트렌드 메뉴
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '국적-나이 별 트렌드 메뉴',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _trendingMenus.length,
                      itemBuilder: (context, index) {
                        final menu = _trendingMenus[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(menu.name),
                                // 이미지 추가 가능
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 개인 맞춤 추천
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '개인 맞춤 추천',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _personalRecommendations.length,
                      itemBuilder: (context, index) {
                        final menu = _personalRecommendations[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(menu.name),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Korean Street Food
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Korean Street Food',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // 카테고리 선택
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: MenuCategory.values.length,
                      itemBuilder: (context, index) {
                        final category = MenuCategory.values[index];
                        return ChoiceChip(
                          label: Text(category.displayName),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                              _loadCategoryMenus();
                            }
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categoryMenus.length,
                      itemBuilder: (context, index) {
                        final menu = _categoryMenus[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Text(menu.name),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Discover 시장
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Discover 시장',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _markets.length,
                    itemBuilder: (context, index) {
                      final market = _markets[index];
                      return ListTile(
                        title: Text(market.name),
                        subtitle: market.description != null
                            ? Text(market.description!)
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 0),
    );
  }
}
