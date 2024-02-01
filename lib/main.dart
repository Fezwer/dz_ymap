import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:geolocator/geolocator.dart';

class PlacemarkMapObject {
  final MapObjectId mapId;
  final Point point;
  final double opacity;
  final double direction;
  final bool isDraggable;
  final PlacemarkIcon icon;

  PlacemarkMapObject({
    required this.mapId,
    required this.point,
    required this.opacity,
    required this.direction,
    required this.isDraggable,
    required this.icon,
  });

  factory PlacemarkMapObject.fromObject({
    required MapObjectId mapId,
    required Point point,
    required double opacity,
    required double direction,
    required bool isDraggable,
    required PlacemarkIcon icon,
  }) =>
      PlacemarkMapObject(
        mapId: mapId,
        point: point,
        opacity: opacity,
        direction: direction,
        isDraggable: isDraggable,
        icon: icon,
      );
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _MapScreenState(),
    );
  }
}

class _MapScreenState extends StatefulWidget {
  @override
  __MapScreenStateState createState() => __MapScreenStateState();
}

class __MapScreenStateState extends State<_MapScreenState> {
  late YandexMapController controller;
  final List<MapObject> mapObjects = [];
  final MapObjectId targetMapObjectId = const MapObjectId('target_placemark');
  late Position _currentPosition;
  final animation =
      const MapAnimation(type: MapAnimationType.smooth, duration: 2.0);
  double zoomLevel = 2;
  final MapObjectId mapObjectId = const MapObjectId('normal_icon_placemark');

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Обработка случая, когда службы геолокации отключены
      print('РАСПИЛИ МЕНЯ БОЛГАРКОЙ');
      return;
    }

    try {
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        // Обработка случая, когда пользователь навсегда отклонил доступ к геолокации
        print('КИНА НЕ БУДЕТ');
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          // Обработка случая, когда пользователь отказал в доступе к геолокации
          print('ПРОБКИ ВЫБИЛО');
          return;
        }
      }
    } catch (e) {
      print('Ошибка при запросе разрешений: $e');
    }
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        print(Point(
            latitude: _currentPosition.latitude,
            longitude: _currentPosition.longitude));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error occurred: $e'),
        ),
      );
    }
  }

  void _onMapTap(Point point) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Нажатие по карте: $point'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: YandexMap(
        zoomGesturesEnabled: true,
        onMapCreated: (YandexMapController newController) {
          setState(() {
            controller =
                newController; // Инициализация контроллера при создании карты
          });
        },
        onMapTap: (Point point) {
          _onMapTap(point);
        },
        mapObjects: mapObjects,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            onPressed: () {
              setState(() {
                zoomLevel++;
                controller.moveCamera(CameraUpdate.zoomTo(zoomLevel),
                    animation: animation);
              });
            },
            child: Icon(Icons.add),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                zoomLevel--;
                controller.moveCamera(CameraUpdate.zoomTo(zoomLevel),
                    animation: animation);
              });
            },
            child: Icon(Icons.remove),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () async {
              _getCurrentLocation();
              final newCameraPosition = CameraPosition(
                  target: Point(
                      latitude: _currentPosition.latitude,
                      longitude: _currentPosition.longitude),
                  zoom: 15);
              zoomLevel = 15;
              await controller.moveCamera(
                  CameraUpdate.newCameraPosition(newCameraPosition),
                  animation: animation);

              final mapObject = PlacemarkMapObject(
                mapId: mapObjectId,
                point: Point(
                    latitude: _currentPosition.latitude,
                    longitude: _currentPosition.longitude),
                opacity: 0.7,
                direction: 90,
                isDraggable: true,
                icon: PlacemarkIcon.single(PlacemarkIconStyle(
                    image: BitmapDescriptor.fromAssetImage(
                        'lib/assets/route_start.png'),
                    rotationType: RotationType.noRotation)),
              );

              setState(() {
                mapObjects.add(mapObject as MapObject);
              });
            },
            child: Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}
