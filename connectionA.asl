// Agent bob in project MAPC2018.mas2j

/* Initial beliefs and rules */

currentPosition(0,0).	// current position based on personal starting position

lastDirection("w").
searchFor("taskboard").
path("").
pathgoal("").
currentIntention("move").
currentStep(0).
vl(0).

/*	belief get generated when found
dispenser().
taskboard().
goals().
obstacle().
*/

/* Initial goals */

!findTaskboard.
//!randomMovement.

/* Plans */


+!randomMovement : path("")<-		// chose a random destination inside of the percept range
	.random([[0,5],[5,0],[0,-5],[-5,0]],Direction);
	.nth(0,Direction,X);
	.nth(1,Direction,Y);
	.abolish(moveTowards(_,_));
	!moveTowards(X,Y).
+!randomMovement <- !randomMovement.
+!updateSurroundings :true <-
	?currentPosition(X,Y);
	for(thing(TX,TY,taskboard,_))
	{
		+taskboard(TX+X,TY+Y);
		.broadcast(tell,taskboard(TX+X,TY+Y));
	};
	for(thing(D0X,D0Y,dispenser,b0))
	{
		+dispenser(D0X+X,D0Y+Y,"b0");
		.broadcast(tell,dispenser(D0X+X,D0Y+Y,"b0"));
	};
	for(thing(D1X,D1Y,dispenser,b1))
	{
		+dispenser(D1X+X,D1Y+Y,"b1");
		.broadcast(tell,dispenser(D1X+X,D1Y+Y,"b1"));
	};
	for(goal(GX,GY))
	{
		+goals(GX+X,GY+Y);
		.broadcast(tell,goals(GX+X,GY+Y));
	};
	/*for(obstacle(OX,OY))
	{
		+obstacles(OX+X,OY+Y);
	};*/
	.abolish(thing(_,_,_,_));
	.abolish(goal(_,_));
	.abolish(obstacle(_,_)).
	

+thing(A,B,C,D) :true <- +thing(A,B,C,D).	//write percepts into belief system ,which get put into the "map" after updating the currentPosition
+goal(X,Y) : true <- +goal(X,Y).
+obstalce(X,Y) :true <- +obstalce(X,Y).
+position(X,Y) :true <-
	-+currentPosition(X,Y);
	!updateSurroundings.

+!findTaskboard : taskboard(X,Y) <-
	.drop_intention(randomMovement);
	.suspend(delayMovement);
	-+pathgoal("temp");
	-+path("");
	-+pathgoal("taskboard");
	?currentPosition(PX,PY);
	.abolish(moveTowards(_,_));
	!moveTowards(X-PX,Y-PY);		//reference self back to world center and then towards the point to get the "distance" to object
	!reducePathBy(2);
	.resume(delayMovement).		//resume Movement Intention
+!findTaskboard <- !findTaskboard.
-!findTaskboard <-
	.print("find Taskboardfailed").
	
+!findDispenser_1 : dispenser(X,Y,"b1") <-
	.drop_intention(randomMovement);
	.suspend(delayMovement);
	-+pathgoal("temp");
	-+path("");
	-+pathgoal("dispenser");
	?currentPosition(PX,PY);
	.abolish(moveTowards(_,_));
	!moveTowards(X-PX,Y-PY);		//reference self back to world center and then towards the point to get the "distance" to object
	!reducePathBy(1);
	.resume(delayMovement).		//resume Movement Intention
-!findDispenser_1 <-
	.print("find Dispenser1 failed").

+!findDispenser_0 : dispenser(X,Y,"b0") <-
	.drop_intention(randomMovement);
	.suspend(delayMovement);
	-+pathgoal("temp");
	-+path("");
	-+pathgoal("dispenser");
	?currentPosition(PX,PY);
	.abolish(moveTowards(_,_));
	!moveTowards(X-PX,Y-PY);		//reference self back to world center and then towards the point to get the "distance" to object
	!reducePathBy(1);
	.resume(delayMovement).		//resume Movement Intention
-!findDispenser_0 <-
	.print("find Dispenser0 failed").	
	

+!findGoalzone : goals(X,Y) <-
	.drop_intention(randomMovement);
	.suspend(delayMovement);
	-+pathgoal("temp");
	-+path("");
	-+pathgoal("goalZone");
	?currentPosition(PX,PY);
	.abolish(moveTowards(_,_));
	!moveTowards(X-PX,Y-PY);		//reference self back to world center and then towards the point to get the "distance" to object
	//!reducePathBy(1);
	.resume(delayMovement).		//resume Movement Intention
-!findGoalzone <-
	.print("find Goalzone failed").	
	

+step(X) : true <- -+currentStep(X).
	
+actionID(X) : currentIntention("request") <-	!requestBlock.		// restart the Moement Goal with every "beat" send by the server
+actionID(X) : currentIntention("attach") <-	!attachBlock.
+actionID(X) : currentIntention("accept") <-	!acceptTask.
+actionID(X) : currentIntention("move") <-		!delayMovement.		// instead of instantly moving, give the Agent time to react to surroundings and calculate the next moves
+actionID(X) : currentIntention("submit") <-	!submit.

+lastActionResult(failed) :true <- 
	.print("last action failed").
	
+task(TaskID,Deadline,X,[req(XB,YB,D)]) : true <- 
	?currentStep(Step);
	if(Deadline > (Step + 50)){+currentTasks(TaskID,Deadline,1,[req(XB,YB,D)])}.
	
+path("") : pathgoal("") <-		 //no path and no current goal ---> restart randomMovement
	.print("finished my Movement.. Restart");
	!randomMovement.

+path("") : pathgoal("taskboard") <-	//TODO
	-+pathgoal("");
	.print("reached board");
	-+currentIntention("accept").
	
+path("") : pathgoal("dispenser") <-	//TODO
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
		if(Deadline<(Step+50) | acceptedTask(TaskID) ){!acceptTask}
		else
		{
			-+taskID(TaskID);
			accept(TaskID);
			.broadcast(tell,acceptedTask(TaskID));
			-+pathgoal("");
			-+taskAccepted(true);
			//.print(Requirements);
			if(.substring("b0",D)){!findDispenser_0;}
			else{!findDispenser_1;}
			-+currentIntention("move");
		}.
	
	
+!acceptTask <- !acceptTask.
-!acceptTask <-
	.print("failed accept Task");
	-+currentIntention("move");
	!findTaskboard;
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
	.print("in MT ",P);
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
	!findGoalzone.
	
	
+!submit : grabDirection("n") <-	rotate("cw");	-+grabDirection("e").
+!submit : grabDirection("e") <-	rotate("cw");	-+grabDirection("s").
+!submit : grabDirection("w") <-	rotate("ccw");	-+grabDirection("s").
	
+!submit : grabDirection("s") <-
	?taskID(TaskID);
	submit(TaskID);
	
	
	-taskID;
	-+currentIntention("move");
	!findTaskboard;
	-taskAccepted.
	
