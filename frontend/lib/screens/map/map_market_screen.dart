import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../services/market_photos_service.dart';
import '../../services/shop_service.dart';
import '../../models/shop_model.dart';

class MapMarketScreen extends StatefulWidget {
  final String marketId;

  const MapMarketScreen({super.key, required this.marketId});

  @override
  State<MapMarketScreen> createState() => _MapMarketScreenState();
}

class _MapMarketScreenState extends State<MapMarketScreen> {
  List<Map<String, dynamic>> _recentPhotos = [];
  List<Map<String, dynamic>> _bestsellingMenus = [];
  List<ShopModel> _pinnedShops = [];
  bool _isLoading = true;
  String _selectedCategory = '전체보기';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final marketPhotosService = Provider.of<MarketPhotosService>(context, listen: false);
      final shopService = Provider.of<ShopService>(context, listen: false);

      final results = await Future.wait([
        marketPhotosService.getMarketRecentPhotos(marketId: widget.marketId, limit: 10),
        marketPhotosService.getMarketBestsellingMenus(marketId: widget.marketId, limit: 3),
        shopService.getPinnedShops(marketId: widget.marketId),
      ]);

      setState(() {
        _recentPhotos = results[0] as List<Map<String, dynamic>>;
        _bestsellingMenus = results[1] as List<Map<String, dynamic>>;
        _pinnedShops = results[2] as List<ShopModel>;
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

  Future<void> _loadRecentPhotos() async {
    try {
      final marketPhotosService = Provider.of<MarketPhotosService>(context, listen: false);
      final category = _selectedCategory == '전체보기' ? null : _selectedCategory;
      final photos = await marketPhotosService.getMarketRecentPhotos(
        marketId: widget.marketId,
        category: category,
        limit: 10,
      );
      setState(() {
        _recentPhotos = photos;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 로드 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.marketId),
      ),
      body: Column(
        children: [
          // 지도 영역
          Container(
            height: 300,
            color: Colors.grey[300],
            child: const Center(child: Text('지도 영역')),
          ),
          // 바텀시트
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Now'),
                      Tab(text: 'Saved'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Now 탭
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'Bestselling 3',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 150,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _bestsellingMenus.length,
                                        itemBuilder: (context, index) {
                                          final menu = _bestsellingMenus[index];
                                          return Card(
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Column(
                                                children: [
                                                  Text(menu['name'] ?? ''),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        '실시간 업데이트 now',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    // 카테고리 버튼
                                    SizedBox(
                                      height: 50,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: ['전체보기', '식사', '간식', '디저트', '음료수'].length,
                                        itemBuilder: (context, index) {
                                          final category = ['전체보기', '식사', '간식', '디저트', '음료수'][index];
                                          return ChoiceChip(
                                            label: Text(category),
                                            selected: _selectedCategory == category,
                                            onSelected: (selected) {
                                              if (selected) {
                                                setState(() {
                                                  _selectedCategory = category;
                                                });
                                                _loadRecentPhotos();
                                              }
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    // 사진 리스트
                                    SizedBox(
                                      height: 200,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _recentPhotos.length,
                                        itemBuilder: (context, index) {
                                          final photo = _recentPhotos[index];
                                          return Card(
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Column(
                                                children: [
                                                  Text(photo['menu_name'] ?? ''),
                                                  // 이미지 추가 가능
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        // Saved 탭
                        _pinnedShops.isEmpty
                            ? const Center(child: Text('핀한 가게가 없습니다.'))
                            : ListView.builder(
                                itemCount: _pinnedShops.length,
                                itemBuilder: (context, index) {
                                  final shop = _pinnedShops[index];
                                  return ListTile(
                                    title: Text(shop.name),
                                    subtitle: shop.address != null ? Text(shop.address!) : null,
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }
}

