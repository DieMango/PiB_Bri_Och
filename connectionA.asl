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
	.abolish(canSendAction);
	!randomMovement.
+!randomMovement <- !randomMovement.

+thing(X,Y,taskboard,_) : true <-
	if (taskAccepted(false) )
	{
		!moveTowards(X,Y);
		.suspend(randomMovement);
	}
	.print("Found taskboard! at:",X,":",Y).
	
+actionID(X) : true <-
	+canSendAction(true).
	
	
+!moveTowards(X,Y) : canSendAction(true) <- 
	if((( ((0<= Y)&(Y<= X)) | (((X<= Y)&(Y<= 0)))) | ((0<= Y)&(Y<= -X)) | (((-X<= Y)&(Y<= 0)))) )
	{	
		if(X>0){move("e");}
		elif(X<0){move("w");}
		else{skip;}
	}
	elif(((((0<= X)&(X< Y)) | ((0 >=X)&(X> Y))) | ((0<= X)&(X< -Y)) | ((0 >=X)&(X> -Y))))
	{	
		if(Y>0){move("s");}
		elif(Y<0){move("n");}
		else{skip;}
	}
	else
	{
		.print(" move failed",X,Y);
		skip;
	}
	.abolish(canSendAction).
	
+!moveTowards(X,Y) <- !moveTowards(X,Y).
	
	
/*
+lastActionParams(X) : lastAction(move) & lastActionResult(success) <-
	.print(X[0]);
	.abolish(wantToMove(_)). */


		
