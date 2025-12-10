// lib/core/widgets/google_map_widget.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Google Maps 위젯
/// 
/// 주소 또는 좌표를 받아서 지도를 표시합니다.
class GoogleMapWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? placeName;
  final double height;
  final Set<Marker>? markers;
  final Function(GoogleMapController)? onMapCreated;
  final double? zoom;

  const GoogleMapWidget({
    Key? key,
    this.latitude,
    this.longitude,
    this.address,
    this.placeName,
    required this.height,
    this.markers,
    this.onMapCreated,
    this.zoom,
  }) : super(key: key);

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  GoogleMapController? _mapController;
  LatLng? _center;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    // 좌표가 직접 제공된 경우
    if (widget.latitude != null && widget.longitude != null) {
      setState(() {
        _center = LatLng(widget.latitude!, widget.longitude!);
        _isLoading = false;
      });
      return;
    }

    // 주소만 제공된 경우 - 좌표 변환 필요
    // TODO: Geocoding API를 사용하여 주소를 좌표로 변환
    // 현재는 기본값(서울) 사용
    if (widget.address != null) {
      // 임시로 서울 좌표 사용
      setState(() {
        _center = const LatLng(37.5665, 126.9780);
        _isLoading = false;
      });
    } else {
      // 좌표도 주소도 없는 경우 기본값
      setState(() {
        _center = const LatLng(37.5665, 126.9780);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _center == null) {
      return Container(
        height: widget.height,
        color: const Color(0xFFF7F7F8),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _center!,
        zoom: widget.zoom ?? 15.0,
      ),
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        if (widget.onMapCreated != null) {
          widget.onMapCreated!(controller);
        }
      },
      markers: widget.markers ?? _createDefaultMarkers(),
      mapType: MapType.normal,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  Set<Marker> _createDefaultMarkers() {
    if (_center == null) return {};
    
    return {
      Marker(
        markerId: const MarkerId('location'),
        position: _center!,
        infoWindow: InfoWindow(
          title: widget.placeName ?? '위치',
          snippet: widget.address,
        ),
      ),
    };
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

