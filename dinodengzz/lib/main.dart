import 'package:dinodengzz/dinodengzz.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();

  DinoDengzz game = DinoDengzz();
  runApp(GameWidget(game: kDebugMode ? DinoDengzz() : game));
}
