import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/services/shop_service.dart';
import '../../models/shop_model.dart';

class ReportShopSelectScreen extends StatefulWidget {
  const ReportShopSelectScreen({super.key});

  @override
  State<ReportShopSelectScreen> createState() => _ReportShopSelectScreenState();
}

class _ReportShopSelectScreenState extends State<ReportShopSelectScreen> {
  List<ShopModel> _shops = [];
  bool _isLoading = true;
  String? _selectedShopId;
  double? _lat;
  double? _lng;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shops.isEmpty) {
      final extra = GoRouterState.of(context).extra;
      if (extra is Map<String, dynamic>) {
        _lat = extra['lat'] as double?;
        _lng = extra['lng'] as double?;
        _loadNearbyShops();
      }
    }
  }

  Future<void> _loadNearbyShops() async {
    if (_lat == null || _lng == null) return;

    try {
      final shopService = Provider.of<ShopService>(context, listen: false);
      final shops = await shopService.getNearbyShops(
        lat: _lat!,
        lng: _lng!,
        radiusMeters: 5.0,
        limit: 5,
      );
      setState(() {
        _shops = shops;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('가게 조회 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('가게 선택'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('주변 가게를 선택해주세요'),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _shops.isEmpty
                    ? const Center(child: Text('주변에 가게가 없습니다.'))
                    : ListView.builder(
                        itemCount: _shops.length,
                        itemBuilder: (context, index) {
                          final shop = _shops[index];
                          return ListTile(
                            title: Text(shop.name),
                            subtitle: shop.address != null ? Text(shop.address!) : null,
                            leading: shop.repImageUrl != null
                                ? Image.network(shop.repImageUrl!, width: 50, height: 50)
                                : const Icon(Icons.store),
                            selected: _selectedShopId == shop.id,
                            onTap: () {
                              setState(() {
                                _selectedShopId = shop.id;
                              });
                            },
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _selectedShopId == null
                  ? null
                  : () {
                      context.push('/report/complete', extra: _selectedShopId);
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('선택 완료'),
            ),
          ),
        ],
      ),
    );
  }
}

