# DinoDengzz

This game is platformer and easy playing game for having fun in your free time and anywhere you want.

You can play DInoDenzz both on your smartphone and your PC.

# Game code and resources

The **lib** folder contains our game files including **main.dart** for starting our game **dinodengzz.dart** , our game system file and Components folder store our components code files.

## Components of our game

*background_tile.dart* : Create the background as Parallax Components to make it scroll down  in the background.

*checkpoint.dart* : Create the checkpoint as Sprite Components. Method onCollisionStart check if player touches the Checkpoint. Method _reachedCheckpoint used for showing the animations of the Checkpoint.

*collision_block.dart* : Create the CollisionBlock as Position Component for making collidable objects.

*custom_hitbox.dart* : Create the hit box for any objects.

*fruit.dart* : Create the Fruit as Sprite Components. Method onCollisionStart check if player touches Fruits. Method collidedWithPlayer used for showing the animations for collecting Fruits.

*jump_button.dart* : Create jump button for smartphone users.

*level.dart* : Create the Level which including player objects and background.

*saw.dart* : Create Saw as Sprite Components. 

*player.dart* : Create Players as Sprite Component. Which you can control and all physic is calculated in this component.

*utils.dart* : Using for checking collisions.




