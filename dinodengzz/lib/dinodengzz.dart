import 'dart:async';

import 'package:dinodengzz/Components/jump_button.dart';
import 'package:dinodengzz/Components/player.dart';
import 'package:dinodengzz/Components/level.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

class DinoDengzz extends FlameGame
    with HasKeyboardHandlerComponents, DragCallbacks, HasCollisionDetection {
  @override
  Color backgroundColor() => const Color.fromARGB(255, 160, 71, 64);
  late CameraComponent cam;
  Player player = Player(character: 'Ninja Frog');
  late JoystickComponent joystick;
  bool showControls = false;
  bool playSounds = false;
  double soundVolume = 1.0;
  List<String> levelNames = ['Level-01', 'Level-02'];
  int currentLevelIndex = 0;

  @override
  FutureOr<void> onLoad() async {
    //load all images in to cache
    await images.loadAllImages();
    _loadLevel();

    if (showControls) {
      addJoystick();
      add(JumpButton());
    }

    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (showControls) {
      updateJoystick();
    }
    super.update(dt);
  }

  void addJoystick() {
    joystick = JoystickComponent(
        knob: SpriteComponent(sprite: Sprite(images.fromCache('HUD/Knob.png'))),
        background: SpriteComponent(
            sprite: Sprite(images.fromCache('HUD/Joystick.png'))),
        margin: const EdgeInsets.only(left: 32, bottom: 32));
    add(joystick);
  }

  void updateJoystick() {
    switch (joystick.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        player.horizontalMovement = -1;
        break;
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        player.horizontalMovement = 1;
        break;
      default:
        player.horizontalMovement = 0;
        break;
    }
  }

  void loadNextLevel() {
    removeWhere((component) => component is Level);
    if (currentLevelIndex < levelNames.length - 1) {
      currentLevelIndex++;
      _loadLevel();
    } else {
      //menu or endgame
      currentLevelIndex = 0;
      _loadLevel();
    }
  }

  void _loadLevel() {
    Future.delayed(const Duration(seconds: 1), () {
      Level world = Level(
        levelName: levelNames[currentLevelIndex],
        player: player,
      );

      cam = CameraComponent.withFixedResolution(
        world: world,
        width: 640,
        height: 320,
      );
      cam.viewfinder.anchor = Anchor.topLeft;

      addAll([cam, world]);
    });
  }
}
