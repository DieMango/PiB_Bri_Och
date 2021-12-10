// Agent bob in project MAPC2018.mas2j

/* Initial beliefs and rules */

currentPosition(0,0).		// current position based on personal starting position
globalPosition(0,0). // global position will be centered around agent1 personal start point

taskAccepted(false).
wantToMove(true).

/* Initial goals */

!randomMovement.
/* Plans */


+!randomMovement : canSendAction(true) <-
	.random(["n","e","s","w"],Direction);
	move(Direction);
	//.abolish(canSendAction);
	!randomMovement.
+!randomMovement <- !randomMovement.

+thing(X,Y,taskboard,_) : true <-
	.print("Found taskboard! at:",X,":",Y);
	!moveTowards(X,Y);
	succed_goal(randomMovement).
	
+actionID(X) : true <-
	+canSendAction(true).
	
	
+!moveTowards(X,Y) : taskAccepted(false) & canSendAction(true) <- 
	//.abolish(canSendAction);	
	move("n").
	
+!moveTowards(X,Y) <- !moveTowards(X,Y).
	
	
/*
+lastActionParams(X) : lastAction(move) & lastActionResult(success) <-
	.print(X[0]);
	.abolish(wantToMove(_)). */


		
