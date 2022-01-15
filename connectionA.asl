// Agent bob in project MAPC2018.mas2j

/* Initial beliefs and rules */

currentPosition(0,0).	// current position based on personal starting position
globalPosition(0,0). // global position will be centered around agent1 personal start point

lastDirection("w").
taskAccepted(false).
searchFor("taskboard").
path("").
currentIntention("move").
pathgoal("").
currentStep(0).
vl(0).
/* Initial goals */

!randomMovement.

/* Plans */


+!randomMovement : true<-		// chose a random destination inside of the percept range
	.random([[0,5],[5,0],[0,-5],[-5,0]],Direction);
	.nth(0,Direction,X);
	.nth(1,Direction,Y);
	!moveTowards(X,Y).
+!randomMovement <- !randomMovement.

+position(X,Y) :true <-
	-+currentPosition(X,Y).

+thing(X,Y,taskboard,_) : searchFor("taskboard") <-
	-+searchFor("");
	.print("Found taskboard! at:",X,":",Y);
	.suspend(delayMovement);
	-+pathgoal("temp");
	-+path("");
	-+pathgoal("taskboard");
	!moveTowards(X,Y);
	!reducePathBy(2);
	
	.print ("move to Taskboard");

	.resume(delayMovement).		//resume Movement Intention

+thing(X,Y,dispenser,b0) : ~searchFor("dispenser_b0") <-	
	?currentPosition(X).

+thing(X,Y,dispenser,b0) : searchFor("dispenser_b0") <-	
	-+searchFor("");
	.print("Found dispenser_b0! at:",X,":",Y);
	.suspend(delayMovement);
	-+pathgoal("temp");
	-+path("");
	-+pathgoal("dispenser_b0");
	!moveTowards(X,Y);
	!reducePathBy(1);
	
	.print ("move to dispenser");

	.resume(delayMovement).		//resume Movement Intention

+thing(X,Y,dispenser,b1) : searchFor("dispenser_b1") <-
	-+searchFor("");
	.print("Found dispenser_b1! at:",X,":",Y);
	.suspend(delayMovement);
	-+pathgoal("temp");
	-+path("");
	-+pathgoal("dispenser_b1");
	!moveTowards(X,Y);
	!reducePathBy(1);
	.print ("move to dispenser");

	.resume(delayMovement).		//resume Movement Intention

+goal(X,Y) : searchFor("goalZone") <-	
	-+searchFor("");
	.print("Found goalZone! at:",X,":",Y);
	.suspend(delayMovement);
	-+pathgoal("temp");
	-+path("");
	-+pathgoal("goalZone");
	!moveTowards(X,Y);
	//!reducePathBy(0);
	
	.print ("move to dispenser");

	.resume(delayMovement).		//resume Movement Intention	
	
+step(X) : true <- -+currentStep(X).
	
+actionID(X) : currentIntention("request") <-	!requestBlock.		// restart the Moement Goal with every "beat" send by the server
+actionID(X) : currentIntention("attach") <-	!attachBlock.
+actionID(X) : currentIntention("accept") <-	!acceptTask.
+actionID(X) : currentIntention("move") <-		!delayMovement.
+actionID(X) : currentIntention("submit") <-	!submit.
// instead of instantly moving, give the Agent time to react to surroundings and calculate the next moves
	
+task(TaskID,Deadline,X,[req(XB,YB,D)]) : true <- 
	?currentStep(Step);
	if(Deadline > (Step + 50)){+currentTasks(TaskID,Deadline,1,[req(XB,YB,D)])}.
	


+path("") : pathgoal("") <-		 //no path and no current goal ---> restart randomMovement
	!randomMovement.

+path("") : pathgoal("taskboard") <-	//TODO
	-+pathgoal("");
	.print("reached board");
	-+currentIntention("accept").
	
+path("") : pathgoal("dispenser_b0") <-	//TODO
	-+pathgoal("");
	.print("reached dispenser");
	-+currentIntention("request").
	
+path("") : pathgoal("dispenser_b1") <-	//TODO
	-+pathgoal("");
	.print("reached dispenser");
	-+currentIntention("request").

+path("") : pathgoal("goalZone") <-	//TODO
	-+pathgoal("");
	.print("reached goal");
	-+currentIntention("submit").

/*+lastActionResult(failed_path) : ~pathgoal("") <-
	?pathgoal(P);
	
	-+pathgoal("");
	-+searchFor(P). */
	
	

+!acceptTask : true <-
		?currentStep(Step);
		?currentTasks(TaskID,Deadline,Y,[req(XB,YB,D)]);
		.abolish(currentTasks(TaskID,_,_,_));
		if(Deadline<(Step+50)){!acceptTask}
		else
		{
			-+taskID(TaskID);
			accept(TaskID);
			-+pathgoal("");
			-+taskAccepted(true);
			//.print(Requirements);
			if(.substring("b0",D)){-+searchFor("dispenser_b0");}
			else{-+searchFor("dispenser_b1");}
			!randomMovement;
			-+currentIntention("move");
			?searchFor(X);
			.print(X)
		}.
	
	
+!acceptTask <- !acceptTask.
-!acceptTask <-
	.print("failed accept Task");
	skip.
	

+!delayMovement : not (path("")) <-						// move in the rythm of the server
	?path(MovePath); 
	.nth(0,MovePath,Direction);
	.delete(0,MovePath,P);
	move(Direction);
	-+lastDirection(Direction);
	-+path(P).
	

	
+!delayMovement : path("") <-
	 .wait(0).
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
		.nth(0,R,Grab);
		-+grabDirection(Grab);
		.delete(0,X,R,A);
		.reverse(A,B);	//Reverse again
		-+path(B);
	}.
	

+!reducePathBy(X) <- !reducePathBy(X).
		
+!requestBlock : true <-
	?grabDirection(Direction);
	request(Direction);
	.print("requested block!");
	-+currentIntention("attach").
	
+!attachBlock :true <-
	?grabDirection(Direction);
	attach(Direction);
	.print("grabbed block!");
	-+currentIntention("move");
	!randomMovement;
	-+searchFor("goalZone").
	
	
+!submit : grabDirection("n") <-	rotate("cw");	-+grabDirection("e").
+!submit : grabDirection("e") <-	rotate("cw");	-+grabDirection("s").
+!submit : grabDirection("w") <-	rotate("ccw");	-+grabDirection("s").
	
+!submit : grabDirection("s") <-
	?taskID(TaskID);
	submit(TaskID).
	
