import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:geolocator/geolocator.dart';

class LocationRepository {
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Обработка случая, когда службы геолокации отключены
      throw LocationServiceDisabledException('Службы геолокации отключены');
    }

    try {
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        // Обработка случая, когда пользователь навсегда отклонил доступ к геолокации
        throw LocationPermissionException(
            'Доступ к геолокации навсегда отклонен');
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          // Обработка случая, когда пользователь отказал в доступе к геолокации
          throw LocationPermissionException('Доступ к геолокации отклонен');
        }
      }
    } catch (e) {
      throw LocationPermissionException('Ошибка при запросе разрешений: $e');
    }

    try {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      throw LocationServiceException(
          'Произошла ошибка при получении местоположения: $e');
    }
  }
}

class LocationServiceDisabledException implements Exception {
  final String message;
  LocationServiceDisabledException(this.message);
}

class LocationPermissionException implements Exception {
  final String message;
  LocationPermissionException(this.message);
}

class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);
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
  final LocationRepository _locationRepository = LocationRepository();
  final MapObjectId targetMapObjectId = const MapObjectId('target_placemark');
  late Position _currentPosition;
  final animation =
      const MapAnimation(type: MapAnimationType.smooth, duration: 2.0);
  double zoomLevel = 2;
  final MapObjectId mapObjectId = const MapObjectId('normal_icon_placemark');

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
              Position _currentPosition =
                  await _locationRepository.getCurrentLocation();
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
                mapObjects.add(mapObject);
              });
            },
            child: Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}
