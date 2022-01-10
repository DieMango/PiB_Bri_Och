// Agent bob in project MAPC2018.mas2j

/* Initial beliefs and rules */

currentPosition(0,0).	// current position based on personal starting position
globalPosition(0,0). // global position will be centered around agent1 personal start point

lastDirection("w").
taskAccepted(false).
path("").

pathgoal("").

/* Initial goals */

!randomMovement.

/* Plans */


+!randomMovement : path("")  & pathgoal("")<-		// chose a random destination inside of the percept range
	.random([[0,5],[5,0],[0,-5],[-5,0]],Direction);
	.nth(0,Direction,X);
	.nth(1,Direction,Y);
	!moveTowards(X,Y).
+!randomMovement <- !randomMovement.

+thing(X,Y,taskboard,_) : not pathgoal("taskboard") <-
	.print("Found taskboard! at:",X,":",Y);
	.drop_intention(delayMovement);	//drop Intention and suspend intention to stop the Agent from moving in a random direction
	.suspend(delayMovement);
	if (taskAccepted(false) )
	{
		-+pathgoal("taskboard");
		-+path("");
		!moveTowards(X,Y);
		!reducePathBy(2);
		
		.print ("move to Taskboard");
	}
	.resume(delayMovement);		//resume Movement Intention
	!delayMovement.
	

+actionID(X) : true <-			// restart the Moement Goal with every "beat" send by the server
	!delayMovement.				// instead of instantly moving, give the Agent time to react to surroundings and calculate the next moves
	
+path("") : pathgoal("") <-		 //no path and no current goal ---> restart randomMovement
	!randomMovement.

+!delayMovement : not (path("")) <-						// move in the rythm of the server
	?path(MovePath);
	.nth(0,MovePath,Direction);
	.delete(0,MovePath,P);
	-+path(P);
	move(Direction).
	
+!delayMovement  : path("") & pathgoal("taskboard")<-	//TODO
	//move("s");
	move("").
	//.print("near Taskboard").	
	
+!delayMovement <- !delayMovement.
-!delayMovement <- !delayMovement.

+!moveTowards(X,Y) : true <- 		// create a list of Movements towards a certain destination
	lib.findPath(X,Y,Path);	//findPath java method returns a string of Directions to follow
	.term2string(Path,P);
	-+path(P).
	
+!moveTowards(X,Y) <- !moveTowards(X,Y).
-!moveTowards(X,Y) <-
	.print("this failed?").


+!reducePathBy(X) : true <-		//instead of going directly to a given spot, stop X steps before to be able to interact with something
	?path(P);
	.print("before:  ",P);
	.reverse(P,R);	// Reverse P into R to ignore any length of the path
	.length(P,L);
	if(X >= L)
	{
		-+path("");
		.print("after:  empty");
	}
	else
	{
		.delete(0,X,R,A);
		.reverse(A,B);	//Reverse again
		-+path(B);
		.print("after:  ",B);
	}.
	

+!reducePathBy(X) <- !reducePathBy(X).
		
