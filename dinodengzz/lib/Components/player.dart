// ignore_for_file: use_super_parameters
import 'dart:async';

import 'package:dinodengzz/Components/checkpoint.dart';
import 'package:dinodengzz/Components/saw.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:dinodengzz/Components/collision_block.dart';
import 'package:dinodengzz/Components/custom_hitbox.dart';
import 'package:dinodengzz/Components/utils.dart';
import 'package:dinodengzz/dinodengzz.dart';

enum PlayerState {
  idle,
  running,
  jumping,
  falling,
  hit,
  appearing,
  dissappering
}

class Player extends SpriteAnimationGroupComponent
    with HasGameRef<DinoDengzz>, KeyboardHandler, CollisionCallbacks {
  String character;

  Player({this.character = 'Ninja Frog', position}) : super(position: position);

  final double stepTime = 0.025;
  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation fallingAnimation;
  late final SpriteAnimation hitAnimation;
  late final SpriteAnimation appearingAnimation;
  late final SpriteAnimation dissappearingAnimation;

  final double _gravity = 9.82;
  final double _jumpForce = 460;
  final double _terminalVelocity = 300;
  Vector2 startingPos = Vector2.zero();
  double horizontalMovement = 0;
  double movespeed = 100;
  Vector2 velocity = Vector2.zero();
  bool isOnGround = false;
  bool hasJumped = false;
  bool gotHit = false;
  bool reachedCheckpoint = false;
  bool noodleCollected = false;
  List<CollisionBlock> collisionBlocks = [];
  CustomHitBox hitbox = CustomHitBox(
    offsetX: 10,
    offsetY: 4,
    width: 14,
    height: 28,
  );
  double fixedDeltaTime = 1 / 60;
  double accumulatedTime = 0;

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimation();
    //debugMode = true;
    priority = 10;
    startingPos = Vector2(position.x, position.y);
    add(RectangleHitbox(
      position: Vector2(hitbox.offsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height),
    ));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    accumulatedTime += dt;
    while (accumulatedTime >= fixedDeltaTime) {
      if (!gotHit && !reachedCheckpoint) {
        _updatePlayerState();
        _updatePlayerMovement(fixedDeltaTime);
        _checkHorizontalCollisions();
        _applyGravity(fixedDeltaTime);
        _checkVerticalCollisions();
      }
      accumulatedTime -= fixedDeltaTime;
    }
    super.update(dt);
  }

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight);

    horizontalMovement += isLeftKeyPressed ? -1 : 0;
    horizontalMovement += isRightKeyPressed ? 1 : 0;

    hasJumped = keysPressed.contains(LogicalKeyboardKey.space) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp);

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!reachedCheckpoint) {
      if (other is Saw) _respawn();
      if (other is Checkpoint && noodleCollected) _reachCheckpoint();
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  void _loadAllAnimation() {
    idleAnimation = _spriteAnimation('Idle', 11);
    runningAnimation = _spriteAnimation('Run', 12);
    jumpingAnimation = _spriteAnimation('Jump', 1);
    fallingAnimation = _spriteAnimation('Fall', 1);
    hitAnimation = _spriteAnimation('Hit', 7)..loop = false;
    appearingAnimation = _speacialspriteAnimation('Appearing', 7);
    dissappearingAnimation = _speacialspriteAnimation('Desappearing', 7);

    //list of all animation
    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.jumping: jumpingAnimation,
      PlayerState.falling: fallingAnimation,
      PlayerState.hit: hitAnimation,
      PlayerState.appearing: appearingAnimation,
      PlayerState.dissappering: dissappearingAnimation,
    };

    //Set current animation
    current = PlayerState.idle;
  }

  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
        gameRef.images
            .fromCache('Main Characters/$character/$state (32x32).png'),
        SpriteAnimationData.sequenced(
            amount: amount, stepTime: stepTime, textureSize: Vector2.all(32)));
  }

  SpriteAnimation _speacialspriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      gameRef.images.fromCache('Main Characters/$state (96x96).png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2.all(96),
        loop: false,
      ),
    );
  }

  void _updatePlayerMovement(double dt) {
    if (hasJumped && isOnGround) _playerJump(dt);

    if (velocity.y > _gravity) isOnGround = false;
    velocity.x = horizontalMovement * movespeed;
    position.x += velocity.x * dt;
  }

  void _playerJump(double dt) {
    if (game.playSounds) {
      FlameAudio.play('Deng_Suu.wav', volume: game.soundVolume);
    }
    velocity.y = -_jumpForce;
    position.y += velocity.y * dt;
    isOnGround = false;
    hasJumped = false;
  }

  void _updatePlayerState() {
    PlayerState playerState = PlayerState.idle;

    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

    //checking running
    if (velocity.x > 0 || velocity.x < 0) playerState = PlayerState.running;

    //checking falling
    if (velocity.y > 0) playerState = PlayerState.falling;

    //checking jumping
    if (velocity.y < 0) playerState = PlayerState.jumping;

    current = playerState;
  }

  void _checkHorizontalCollisions() {
    for (final block in collisionBlocks) {
      if (!block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.x > 0) {
            velocity.x = 0;
            position.x = block.x - hitbox.offsetX - hitbox.width;
            break;
          }
          if (velocity.x < 0) {
            velocity.x = 0;
            position.x = block.x + block.width + hitbox.width + hitbox.offsetX;
            break;
          }
        }
      }
    }
  }

  void _applyGravity(double dt) {
    velocity.y += _gravity;
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
    position.y += velocity.y * dt;
  }

  void _checkVerticalCollisions() {
    for (final block in collisionBlocks) {
      if (block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
        }
      } else {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
          if (velocity.y < 0) {
            velocity.y = 0;
            position.y = block.y + hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
        }
      }
    }
  }

  void _respawn() async {
    const moveDelay = Duration(milliseconds: 350);

    gotHit = true;
    current = PlayerState.hit;

    await animationTicker?.completed;
    animationTicker?.reset();

    scale.x = 1;
    position = startingPos - Vector2.all(32);
    current = PlayerState.appearing;

    await animationTicker?.completed;
    animationTicker?.reset();

    velocity = Vector2.zero();
    position = startingPos;
    _updatePlayerState();
    Future.delayed(moveDelay, () => gotHit = false);
  }

  void _reachCheckpoint() async {
    reachedCheckpoint = true;
    if (scale.x > 0) {
      position = position - Vector2.all(32);
    } else if (scale.x < 0) {
      position = position - Vector2(-32, 32);
    }
    current = PlayerState.dissappering;

    await animationTicker?.completed;
    animationTicker?.reset();

    reachedCheckpoint = false;
    noodleCollected = false;
    position = Vector2.all(-640);

    const waitToChangeDuration = Duration(seconds: 3);
    Future.delayed(waitToChangeDuration, () {
      game.loadNextLevel();
    });
  }

  void gotNoodle() {
    noodleCollected = true;
  }
}
