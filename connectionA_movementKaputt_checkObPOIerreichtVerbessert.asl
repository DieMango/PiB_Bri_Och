/*
**Structure**
Initial beliefs and rules
Generated bliefs
Initial goals

*Plans* (the main part xD)
-Syncing agents and server
-Taskwatch (TODO), switching goals
-Communication and mapknowledge
-Movement
	random
	directed
	serversync, reduce path
-Finding POIs
	taskboard
	dispenser
	goal
	TODO Obstacle
-Accepting tasks and finding a Partner to do tasks with
	task accepting
	partner finding & handshake
-Requesting blocks from dispenser
-Rotating blocks
-Submitting tasks

*/

/* Initial beliefs and rules */

currentPosition(0,0).	// current position based on personal starting position
lastDirection(""). //brauchen wir das noch?
//searchFor("taskboard"). //every agent should look for a task
path("").  //starting path
pathgoal(""). //movementgoal
currentIntention("start"). //agents want to move
currentStep(0). //step of the round

// brauchen wir die noch für 2Blocktasks?
//secondBlock().
//currentPartner().
//isSupport().
//bestPartner().

/*	belief get generated when found
dispenser().
taskboard().
goals().
obstacle().
*/

/* Initial goals */



/* Plans */

//syncing actions to the rythm of the server
+step(X) : true <- -+currentStep(X).
//// move in the rythm of the server
+actionID(X) : currentIntention("start") <- !findTaskboard.
+actionID(X) : currentIntention("request") <-	!requestBlock.		
+actionID(X) : currentIntention("attach") <-	!attachBlock.
+actionID(X) : currentIntention("accept") <-	!acceptTask.
+actionID(X) : currentIntention("move") <- 		!delayMovement.	
+actionID(X) : currentIntention("submit") <-	!submit.	
+actionID(X) : currentIntention("choosePartner") <-	!choosePartner.
+lastActionResult(failed) :true <- 
	.print("last action failed").

//singleblock task deadline watch
//TODO 2block ?
+task(TaskID,Deadline,X,[req(XB,YB,D)]) : true <- 
	?currentStep(Step);
	if(Deadline > (Step + 50)){+currentTasks(TaskID,Deadline,1,[req(XB,YB,D)])}.
+task(TaskID,Deadline,X,[req(XB,YB,RB),req(XA,YA,RA)]) : true <-
	?currentStep(Step);
	if(Deadline > (Step + 50)){+currentTasks(TaskID,Deadline,1,[req(XB,YB,RB),req(XA,YA,RA)])}.


//Switching to next next goal when the old one is achieved
//Checking if POI is actually reached
/*+path("") : pathgoal("") <-		 //should never happen, no path and no current goal ---> restart randomMovement
	.print("finished my Movement.. Restart");
	!randomMovement. */
	
+path("") : pathgoal("taskboard") <-	//taskboard
	-+pathgoal("");
	-+path("");
	?currentPosition(X,Y);
	?closestPOI(ClosestX,ClosestY);
	if ((math.abs(X-ClosestX) + math.abs(Y-ClosestY))< 2){
		-+currentIntention("accept");
		.print("reached board");}
	else{
	!findTaskboard;
	.print("failed to reach board");}.
	
+path("") : pathgoal("dispenser") <-	//dispenser
	-+pathgoal("");
	-+path("");
	?currentPosition(X,Y);
	?closestPOI(ClosestX,ClosestY); //TODO storing dispenser type
	?findDispenser(Block);
	if ((math.abs(X-ClosestX) + math.abs(Y-ClosestY))< 1){
		-+currentIntention("request");
		.print("reached dispenser");}
	else{
		!findDispenser(Block);
		.print("failed to reach dispenser");}.

+path("") : pathgoal("goalZone") <-	//Goal
	-+pathgoal("");
	-+path("");
	?currentPosition(X,Y);
	?closestPOI(ClosestX,ClosestY);
	if ((math.abs(X-ClosestX) + math.abs(Y-ClosestY)) =0){
		-+currentIntention("submit");
		.print("reached goal");}
	else{
	!findGoalzone;
	.print("failed to reach goal");}.
//Obstacle avoidance no longer needed?
/*+lastActionResult(failed_path) : ~pathgoal("") <-
	?pathgoal(P);
	
	-+pathgoal("");
	-+searchFor(P). */

//map commuication, agents sending positions of POIs to other agents
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
	//TODO Obstacles
	for(thing(AX,AY,entity,_))
	{
		+agents(AX,AY);
	};
	/*for(obstacle(OX,OY))
	{
		+obstacles(OX,OY);
	};*/
	.abolish(thing(_,_,_,_));
	.abolish(goal(_,_)).
	
	
//write percepts into belief system ,which get put into the "map" after updating the currentPosition
+thing(A,B,C,D) :true <- +thing(A,B,C,D).	
+goal(X,Y) : true <- +goal(X,Y).
+obstacle(X,Y) :true <- +obstacle(X,Y).
+position(X,Y) :true <-
/*	?believePosition(BX,BY);
	if((BX==X & BY==Y)){!reorientate;.print("way lost");}	// if they get stuck do this */
	-+currentPosition(X,Y);
	!updateSurroundings.

+!reorientate :true <-
	skip;
	.print("I will wait").

//untargeted movement, for the gents to explore the map
// chose a random destination on the edge of the percept range and move to that location
+!randomMovement : path("")<-		
	.random([[0,5],[5,0],[0,-5],[-5,0]],Direction);
	.nth(0,Direction,X);
	.nth(1,Direction,Y);
	.abolish(moveTowards(_,_));
	!moveTowards(X,Y).
+!randomMovement <- !randomMovement.

// instead of instantly moving, give the Agent time to react to surroundings and calculate the next moves	
+!delayMovement : not (path("")) <-
	?path(MovePath); 
	.nth(0,MovePath,Direction);
	?closestPOI(ClosestX,ClosestY);
	for(obstacle(OX,OY))
	{
		if ((ClosestX < OX) & (ClosestY <OY)){ //POI between agent and obstacle
			.print("no obstacle to avoid");//continue as intended, cause obstacle is not an issue
			}//problem: obstacles in 2-3 directions
		else{
			if((Direction == "n" & OY == -1)|(Direction == "s" & OY == 1)){
				.print("avoid obstacle in ", Direction);
				if (ClosestX <0){
					.concat("www",MovePath,NewPath);
					-+path(NewPath);}
				else{
					.concat("eee",MovePath,NewPath);
					-+path(NewPath);}}
			elif((Direction == "e" & OX == 1)|(Direction == "w" & OX == -1)){
				if (ClosestY <0){
					.concat("nnn",MovePath,NewPath);
					-+path(NewPath);}
				else{
					.concat("sss",MovePath,NewPath);
					-+path(NewPath);}}
		};
	};
	.abolish(obstacle(_,_));
	.delete(0,MovePath,P);
	move(Direction);
	?currentPosition(X,Y);
	-+believePosition(X,Y);
	-+lastDirection(Direction);
	-+path(P);
	!delayMovement.
	
+!delayMovement : path("") <-
	 .wait(0).
-!delayMovement <- !delayMovement.

//directed movement
// create a list of directions towards a certain destination
+!moveTowards(X,Y) : true <- 		
	lib.findPath(X,Y,Path);	//findPath java method returns a string of Directions to follow
	.term2string(Path,P);
	-+path(P).
	
+!moveTowards(X,Y) <- !moveTowards(X,Y).
-!moveTowards(X,Y) <-
	.print("this failed?").

//instead of going directly to a given spot, stop X steps before to be able to interact with something
//eg stopping in front of a dispenser or when a taskboard is in "acceptence range"
+!reducePathBy(X) : true <-		
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

//Finding POIs: Taskboard, Dispenser, Goalzones, TODO Obstacles, Taskpartners
//looking for the nearest taskboard inside the beliefbase
+!findTaskboard : taskboard(TX,TY) <-
	//Find closest of the Item to search
	-+pathgoal("taskboard");
	-+currentIntention("move");
	?currentPosition(PX,PY);
	-+closestPOI(TX,TY);
	.findall(taskboardPos(X,Y),taskboard(X,Y),List); 
	for(.member(i(NewX,NewY),List)) //determinating which tasboard is the nearest
	{
		?closestPOI(ClosestX,ClosestY); 
		lib.findBestPartner(PX,PY,ClosestX,ClosestY,NewX,NewY,Conclusion); //bestpartner function umbenennen?
		if(Conclusion =="new"){-+closestPOI(NewX,NewY)};
	};
	?closestPOI(ClosestX,ClosestY); //bewegung zum taskboard inizialisieren
	.drop_intention(randomMovement);
	.suspend(delayMovement);
	//-+pathgoal("temp");
	-+path("");
	
	.abolish(moveTowards(_,_));
	!moveTowards(ClosestX-PX,ClosestY-PY);		//reference self back to world center and then towards the point to get the "distance" to object
	!reducePathBy(2); //agents can accepts tasks within a range of 2 blocks from taskboard
	.resume(delayMovement).		//resume Movement Intention
	
+!findTaskboard <- !findTaskboard.
-!findTaskboard <- //for debug
	.print("find Taskboard failed").

//finding dispenser 1&0
+!findDispenser_1 : dispenser(DX,DY,"b1") <-
	//Find closest of the Item to search
	?currentPosition(PX,PY);
	-+closestPOI(DX,DY);
	.findall(dispenserPos(X,Y),dispenser(X,Y,"b1"),List);
	for(.member(i(NewX,NewY),List))
	{
		?closestPOI(ClosestX,ClosestY);
		lib.findBestPartner(PX,PY,ClosestX,ClosestY,NewX,NewY,Conclusion);
		if(Conclusion =="new"){-+closestPOI(NewX,NewY)};
	};
	?closestPOI(ClosestX,ClosestY);
	.drop_intention(randomMovement);
	.suspend(delayMovement);
	-+pathgoal("temp");
	-+path("");
	-+pathgoal("dispenser");
	.abolish(moveTowards(_,_));
	!moveTowards(ClosestX-PX,ClosestY-PY);		//reference self back to world center and then towards the point to get the "distance" to object
	!reducePathBy(1);	//request block from an adjecent tile
	.resume(delayMovement).		//resume Movement Intention
	
-!findDispenser_1 <-
	.print("find Dispenser1 failed").
	
//analog zu dispenser_1
+!findDispenser_0 : dispenser(DX,DY,"b0") <-
	//Find closest of the Item to search
	?currentPosition(PX,PY);
	-+closestPOI(DX,DY);
	.findall(dispenserPos(X,Y),dispenser(X,Y,"b1"),List);
	for(.member(i(NewX,NewY),List))
	{
		?closestPOI(ClosestX,ClosestY);
		lib.findBestPartner(PX,PY,ClosestX,ClosestY,NewX,NewY,Conclusion);
		if(Conclusion =="new"){-+closestPOI(NewX,NewY)};
	};
	?closestPOI(ClosestX,ClosestY);
	.drop_intention(randomMovement);
	.suspend(delayMovement);
	-+pathgoal("temp");
	-+path("");
	-+pathgoal("dispenser");
	.abolish(moveTowards(_,_));
	!moveTowards(ClosestX-PX,ClosestY-PY);		//reference self back to world center and then towards the point to get the "distance" to object
	!reducePathBy(1);
	.resume(delayMovement).		//resume Movement Intention
	
-!findDispenser_0 <-
	.print("find Dispenser0 failed").	
	
//finding goalzones
+!findGoalzone : goals(GX,GY) <-
	//Find closest of the Item to search
	?currentPosition(PX,PY);
	-+closestPOI(GX,GY);
	.findall(goalPos(X,Y),goals(X,Y),List);
	for(.member(i(NewX,NewY),List))
	{
		?closestPOI(ClosestX,ClosestY);
		lib.findBestPartner(PX,PY,ClosestX,ClosestY,NewX,NewY,Conclusion);
		if(Conclusion =="new"){-+closestPOI(NewX,NewY)};
	};
	?closestPOI(ClosestX,ClosestY);
	.drop_intention(randomMovement);
	.suspend(delayMovement);
	-+pathgoal("temp");
	-+path("");
	-+pathgoal("goalZone");
	.abolish(moveTowards(_,_));
	!moveTowards(ClosestX-PX,ClosestY-PY);		//reference self back to world center and then towards the point to get the "distance" to object
	//!reducePathBy(1);
	.resume(delayMovement).		//resume Movement Intention
	
-!findGoalzone <-
	.print("find Goalzone failed").	

//accpeting tasks and finding an available agent to complete a 2Block task with
//accepting tasks
+!acceptTask : true <-
		?currentStep(Step);
		//?currentTasks(TaskID,Deadline,Y,[req(XB,YB,RB)]);	//1- Block tasks
		?currentTasks(TaskID,Deadline,Y,[req(XB,YB,RB),req(XA,YA,RA)]);	//2-Block Tasks
		.abolish(currentTasks(TaskID,_,_,_));		
		if(Deadline<(Step+50) | acceptedTask(TaskID) ){!acceptTask} //only accept tasks that have a chance to be completed, a task can only be accepted by one agent of the team
		else
		{
			accept(TaskID);
			-+taskID(TaskID);
			.broadcast(tell,acceptedTask(TaskID)); //tell other agents that this task is taken
			-+pathgoal("");
			-+taskAccepted(true);
			
			if(XB == 0 & YB ==1)
			{
				-+secondBlock(XA,YA,RA); // 2-Block tasks only
				if(.substring("b0",RB)){!findDispenser("b0");}
				elif(.substring("b1",RB)){!findDispenser("b1");}
				elif(.substring("b2",RB)){!findDispenser("b2");}
			}
			else
			{
				-+secondBlock(XB,YB,RB); // 2-Block tasks only
				if(.substring("b0",RA)){!findDispenser("b0");}
				elif(.substring("b1",RA)){!findDispenser("b1");}
				elif(.substring("b2",RA)){!findDispenser("b2");}
			}
			//-+currentIntention("move");	//only for 1-Block Tasks
			
			//Start search for Partner for 2-Block tasks
			.my_name(MyName);
			.print("looking for a DancePartner");
			.broadcast(achieve,partnersearch(MyName));
			-+currentIntention("choosePartner");
		}.
	
+!acceptTask <- !acceptTask.
-!acceptTask <-
	.print("failed accept Task");
	skip.
	
//answering to finding a partner for 2-block tasks	
+!partnersearch(AgentName) : true <-
	.print(AgentName,"wants help");
	?currentPosition(X,Y);
	.my_name(MyName);
	if(taskAccepted(true)) //agent has a task already
	{
		.print(MyName ,"I am busy");
	}
	else //agent is available
	{
		.send(AgentName,achieve,partnerResponse(MyName,X,Y));
	}.
	
-!partnersearch(AgentName) :true <-
	.print(AgentName,"failed again").

//finding the nearest available angent
+!partnerResponse(AgentName,X,Y) : true <-
	if(bestPartner)
	{
		?bestPartner(PName,PX,PY);
		?currentPosition(MyX,MyY);
		lib.findBestPartner(MyX,MyY,PX,PY,X,Y,Conclusion);
		if(Conclusion == "new")
		{
			-+bestPartner(AgentName,X,Y)
		}
	}
	else{
		-+bestPartner(AgentName,X,Y)
	}.

//choosing the nearest available agent as partner and telling it that
+!choosePartner : bestPartner(AgentName,X,Y) <-
	.print(AgentName,", I chose you!");
	.my_name(MyName);
	?secondBlock(BX,BY,Block);
	-+currentPartner(AgentName);
	-+currentIntention("move");
	.send(AgentName,achieve,chosenAsSupport(MyName,BX,BY,Block)).

+!choosePartner : true <-
	.print("got no replies").
	
//chosen support agent updates its belief and starts his part of the task
+!chosenAsSupport(AgentName,X,Y,Block) : true <-
	-+currentPartner(AgentName);
	-+isSupport(true);
	-+taskAccepted(true);
	if(.substring("b0",Block)){!findDispenser_0;}
			else{!findDispenser_1;}
	-+currentIntention("move").	

//requesting block from dispenser 
+!requestBlock : true <-
	?grabDirection(Direction);
	request(Direction);
	.print("requested block!");
	-+currentIntention("attach").

//attaching a requested block and storing the direction in which the block is attached to the agent
+!attachBlock : true <-
	?grabDirection(Direction);
	attach(Direction);
	.print("grabbed block!");
	-+currentIntention("move");
	?currentPartner(AgentName);
	?currentPosition(X,Y);
	.send(AgentName,tell,partnerIsReady(X,Y));
	//!findGoalzone.
	!mergeBlocks.
	
+!mergeBlocks : isSupport(true) & parterIsReady(X,Y)<-
		.print("start merge");
		// move towards the partner
		//calculate middle Point
		?currentPosition(MyX,MyY);
		!moveTowards((MyX-X)/2,(MyY-Y)/2);
		!reducePath(2).
		
		
+!mergeBlocks : ~isSupport(true)& parterIsReady(X,Y) <-
		.print("start merge");
		// move towards the partner
		//calculate middle Point
		?currentPosition(MyX,MyY);
		!moveTowards((MyX-X)/2,(MyY-Y)/2);
		!reducePath(0).
		
+!mergeBlocks :true <-
	.print("waiting for Partner");
	skip.

	
//rotating the attached block 
//todo unabhängig von submit machen
+!submit : grabDirection("n") <-	rotate("cw");	-+grabDirection("e").
+!submit : grabDirection("e") <-	rotate("cw");	-+grabDirection("s").
+!submit : grabDirection("w") <-	rotate("ccw");	-+grabDirection("s").

//submitting a task, deleting the task from the beliefbase
+!submit : grabDirection("s") <-
	?taskID(TaskID);
	submit(TaskID);
	-taskID;
	-+currentIntention("move");
	!findTaskboard;
	-taskAccepted.
	//todo? telling other agents that the task is finished, maybe usefull for pvp

	

	


