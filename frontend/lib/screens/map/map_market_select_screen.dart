import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../services/market_service.dart';
import '../../models/market_model.dart';

class MapMarketSelectScreen extends StatefulWidget {
  const MapMarketSelectScreen({super.key});

  @override
  State<MapMarketSelectScreen> createState() => _MapMarketSelectScreenState();
}

class _MapMarketSelectScreenState extends State<MapMarketSelectScreen> {
  List<MarketModel> _markets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMarkets();
  }

  Future<void> _loadMarkets() async {
    try {
      final marketService = Provider.of<MarketService>(context, listen: false);
      final markets = await marketService.getMarkets();
      setState(() {
        _markets = markets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('시장 목록 로드 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('시장 선택'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // 검색 화면으로 이동
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 지도 영역 (임시)
          Container(
            height: 300,
            color: Colors.grey[300],
            child: const Center(child: Text('지도 영역')),
          ),
          // 시장 리스트
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _markets.length,
                    itemBuilder: (context, index) {
                      final market = _markets[index];
                      return ListTile(
                        title: Text(market.name),
                        subtitle: market.description != null ? Text(market.description!) : null,
                        trailing: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        onTap: () {
                          context.push('/map/market/${market.id}');
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }
}

