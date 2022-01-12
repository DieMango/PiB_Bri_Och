// Agent bob in project MAPC2018.mas2j

/* Initial beliefs and rules */

currentPosition(0,0).	// current position based on personal starting position
globalPosition(0,0). // global position will be centered around agent1 personal start point

lastDirection("w").
taskAccepted(false).
searchFor("taskboard").
path("").

pathgoal("").

/* Initial goals */

!randomMovement.

/* Plans */


+!randomMovement : true<-		// chose a random destination inside of the percept range
	.random([[0,5],[5,0],[0,-5],[-5,0]],Direction);
	.nth(0,Direction,X);
	.nth(1,Direction,Y);
	!moveTowards(X,Y).
+!randomMovement <- !randomMovement.

+thing(X,Y,taskboard,_) : searchFor("taskboard") <-
	-+searchFor("");
	.print("Found taskboard! at:",X,":",Y);
	.suspend(delayMovement);

	-+path("");
	!moveTowards(X,Y);
	!reducePathBy(2);
	-+pathgoal("taskboard");
	.print ("move to Taskboard");

	.resume(delayMovement).		//resume Movement Intention


+thing(X,Y,dispenser,b0) : searchFor("dispenser_b0") <-	
	.print("hi").
+thing(X,Y,dispenser,b1) : searchFor("dispenser_b1") <-
	.print("hi").

+actionID(X) : true <-			// restart the Moement Goal with every "beat" send by the server
	!delayMovement.				// instead of instantly moving, give the Agent time to react to surroundings and calculate the next moves
	
+path("") : pathgoal("") <-		 //no path and no current goal ---> restart randomMovement
	!randomMovement.

+path("") : pathgoal("taskboard") <-	//TODO
	.print("reached board");
	!acceptTask.
	

+!acceptTask : true <-
	//.count(task(_,_,_,_),T);
	//if(T==0){move("");}
	//else
	{
		.print("even before");
		//?task(T,_,_,Requirements);
		.findall(T,task(T,_,_,_),L);
		.random(L,Peep);
		.print(Peep);
		.print("before");
		//accept(T);
		accept("task5");
		.print("after");
		-+pathgoal("");
		-+taskAccepted(true);
		//.print(Requirements);
		//.term2string(Requirements,TEMP1);
		//.substring("b0","b0",TEMP2);
		if(true){-+searchFor("dispenser_b0");}
		else{-+searchFor("dispenser_b1");}
		!randomMovement;
		?searchFor(X);
		.print(X);
	}.
	
	
+!acceptTask <- !acceptTask.
-!acceptTask <-
	.print("failed accept Task");
	move("");
	!acceptTask.
	

+!delayMovement : not (path("")) <-						// move in the rythm of the server
	?path(MovePath); 
	.nth(0,MovePath,Direction);
	.delete(0,MovePath,P);
	move(Direction);
	-+path(P).
	

	
+!delayMovement <- .print("").
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
	.reverse(P,R);	// Reverse P into R to ignore any length of the path
	.length(P,L);
	if(X >= L)
	{
		-+path("");
	}
	else
	{
		.delete(0,X,R,A);
		.reverse(A,B);	//Reverse again
		-+path(B);
	}.
	

+!reducePathBy(X) <- !reducePathBy(X).
		
