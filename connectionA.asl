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
lastDirection("w"). //brauchen wir das noch?
//searchFor("taskboard"). //every agent should look for a task
path("").  //starting path
pathgoal(""). //movementgoal
currentIntention("move"). //agents want to move
currentStep(0). 
boardSize(50).
//step of the round
//vl(0). //wof?r war das?

// brauchen wir die noch f?r 2Blocktasks?
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

//!findTaskboard. //every agent should look for a task
//!randomMovement. //kann weg?

/* Plans */

//syncing actions to the rythm of the server
+actionID(X) : true <- 
	-isBusy.
//// move in the rythm of the server
+step(X) : currentIntention("request") <-	-+currentStep(X);!requestBlock.		
+step(X) : currentIntention("attach") <-	-+currentStep(X);!attachBlock.
+step(X) : currentIntention("accept") <-	-+currentStep(X);!acceptTask.
+step(X) : currentIntention("move") <- 		-+currentStep(X);!delayMovement.	
+step(X) : currentIntention("submit") <-	-+currentStep(X);!submit.	
+step(X) : currentIntention("choosePartner") <-	-+currentStep(X);!choosePartner.
+step(X) : currentIntention("merge") <-		-+currentStep(X);!mergeBlocks.
+step(X) : currentIntention("check") <-		-+currentStep(X);!check.
+step(X) : currentIntention("waiting") <-	-+currentStep(X);!waiting.
+step(X) : currentIntention("connect") <-	-+currentStep(X);!connect.
+step(X) : currentIntention("unattach") <-	-+currentStep(X);!unattach.

+lastActionResult(failed) :true <- 
	.print("last action failed").

//singleblock task deadline watch
//TODO 2block ?
+task(TaskID,Deadline,X,[req(XB,YB,RB),req(XA,YA,RA)]) : true <-
	?currentStep(Step);
	if(Deadline > (Step + 50)){+currentTasks(TaskID,Deadline,1,[req(XB,YB,RB),req(XA,YA,RA)])}.
+task(TaskID,Deadline,X,[req(XB,YB,D)]) : true <- 
	?currentStep(Step);
	if(Deadline > (Step + 50)){+currentTasks(TaskID,Deadline,1,[req(XB,YB,D)])}.

	
+taskboard(X,Y) : pathgoal("taskboard")<-
	!findTaskboard.
	
+path("") : pathgoal("") <-		 //no path and no current goal ---> restart randomMovement
	.print("finished my Movement.. Restart");
	!findTaskboard.

+path(""): pathgoal("taskboard") | pathgoal("dispenser") |pathgoal("goalZone") | pathgoal("partner")<-
	//.print("double checking");
	-+currentIntention("check").
//Switching to next next goal when the old one is achieved
//Checking if POI is actually reached
+!check : pathgoal("taskboard") <-	//taskboard
	?currentPosition(X,Y);
	?closestPOI(ClosestX,ClosestY);
	if ((math.abs(X-ClosestX) + math.abs(Y-ClosestY))<3)
	{
		-+currentIntention("accept");
		!acceptTask;
		.print("reached board");}
		
	else
	{
		!findTaskboard;
		-+currentIntention("move");
		skip;
		.print("failed to reach board");
	}.
	
+!check : pathgoal("dispenser") <-	//dispenser
	?currentPosition(X,Y);
	?closestPOI(ClosestX,ClosestY); //TODO storing dispenser type
	?blockToFind(Block);
	if ((math.abs(X-ClosestX) + math.abs(Y-ClosestY))<2)
	{
		
		if((math.abs(X-ClosestX) + math.abs(Y-ClosestY))==0)
		{ 
			-+path("e");
			-+currentIntention("move");
		}
		else
		{
			-+currentIntention("request");
			.print("reached dispenser");
			!requestBlock;
		}
	}
	else
	{
		!findDispenser(Block);
		-+currentIntention("move");
		skip;
		.print("failed to reach dispenser, trying again");
	}.

	
+!check : pathgoal("goalZone") <-	//Goal
	?currentPosition(X,Y);
	?closestPOI(ClosestX,ClosestY);
	for(goals(GX,GY))
	{
		if(GX == X & GY ==Y){-+isInGoalzone}
	}
	if(isInGoalzone)
	{
		-isInGoalzone;
		if(oneBlockTask(_)){-+currentIntention("submit");}
		else
		{
		-+currentIntention("merge");
		?currentPartner(Partner);
		.send(Partner,tell,partnerIsReady(ClosestX,ClosestY));
		}
		skip;
		.print("reached a GoalZone");}
	else
	{
		!findGoalzone;
		-+currentIntention("move");
		skip;
		.print("failed to reach goal");
	}.
	
+!check : pathgoal("partner") <-
	?currentPosition(X,Y);
	?closestPOI(ClosestX,ClosestY);
	if ((math.abs(X-ClosestX) + math.abs(Y-ClosestY))==0){
		-+currentIntention("merge");
		.print("reached Partner!");
		?currentPartner(Partner);
		.send(Partner,tell,partnerIsReady(0,0));
		}
	else
	{
		!waiting;
		-+currentIntention("move");
		skip;
		.print("failed to reach partner, Trying again");
	}.
	
//Obstacle avoidance no longer needed?
/*+lastActionResult(failed_path) : ~pathgoal("") <-
	?pathgoal(P);
	
	-+pathgoal("");
	-+searchFor(P). */

+lastAction(no_action) :currentIntention("move") <-
	.random(["ss","ww","ee","nn"],RandomDirection);
	?path(Path);
	.concat(RandomDirection,Path,NewPath);
	-+path(NewPath);
	.print("I did nothing? :O").

+!check <-
	-+currentIntention("move");
	!randomMovement.

//map commuication, agents sending positions of POIs to other agents
+!updateSurroundings :true <-
	?currentPosition(X,Y);
	for(thing(TX,TY,taskboard,_))
	{
		?boardSize(Board);
		+taskboard(TX+X,TY+Y);	//0
		+taskboard(TX+X-Board,TY+Y-Board);	//top left
		+taskboard(TX+X-0,TY+Y-Board);		// top
		+taskboard(TX+X+Board,TY+Y-Board);	//top right
		+taskboard(TX+X+Board,TY+Y+0);		//right
		+taskboard(TX+X+Board,TY+Y+Board);	//bottom right
		+taskboard(TX+X+0,TY+Y+Board);		//bottom
		+taskboard(TX+X-Board,TY+Y+Board);	//bottom left
		+taskboard(TX+X-Board,TY+Y-0);		//left
		.broadcast(tell,taskboard(TX+X,TY+Y));
		.broadcast(tell,taskboard(TX+X-Board,TY+Y-Board));
		.broadcast(tell,taskboard(TX+X-0,TY+Y-Board));
		.broadcast(tell,taskboard(TX+X+Board,TY+Y-Board));
		.broadcast(tell,taskboard(TX+X+Board,TY+Y+0));
		.broadcast(tell,taskboard(TX+X+Board,TY+Y+Board));
		.broadcast(tell,taskboard(TX+X+0,TY+Y+Board));
		.broadcast(tell,taskboard(TX+X-Board,TY+Y+Board));
		.broadcast(tell,taskboard(TX+X-Board,TY+Y-0));
	};
	for(thing(TX,TY,dispenser,b0))
	{
		//+dispenser(D0X+X,D0Y+Y,"b0");
		//.broadcast(tell,dispenser(D0X+X,D0Y+Y,"b0"));
		
		?boardSize(Board);
		+dispenser(TX+X,TY+Y,"b0");	//0
		+dispenser(TX+X-Board,TY+Y-Board,"b0");	//top left
		+dispenser(TX+X-0,TY+Y-Board,"b0");		// top
		+dispenser(TX+X+Board,TY+Y-Board,"b0");	//top right
		+dispenser(TX+X+Board,TY+Y+0,"b0");		//right
		+dispenser(TX+X+Board,TY+Y+Board,"b0");	//bottom right
		+dispenser(TX+X+0,TY+Y+Board,"b0");		//bottom
		+dispenser(TX+X-Board,TY+Y+Board,"b0");	//bottom left
		+dispenser(TX+X-Board,TY+Y-0,"b0");		//left
		.broadcast(tell,dispenser(TX+X,TY+Y,"b0"));
		.broadcast(tell,dispenser(TX+X-Board,TY+Y-Board,"b0"));
		.broadcast(tell,dispenser(TX+X-0,TY+Y-Board,"b0"));
		.broadcast(tell,dispenser(TX+X+Board,TY+Y-Board,"b0"));
		.broadcast(tell,dispenser(TX+X+Board,TY+Y+0,"b0"));
		.broadcast(tell,dispenser(TX+X+Board,TY+Y+Board,"b0"));
		.broadcast(tell,dispenser(TX+X+0,TY+Y+Board,"b0"));
		.broadcast(tell,dispenser(TX+X-Board,TY+Y+Board,"b0"));
		.broadcast(tell,dispenser(TX+X-Board,TY+Y-0,"b0"));
	};
	for(thing(TX,TY,dispenser,b1))
	{
		//+dispenser(D1X+X,D1Y+Y,"b1");
		//.broadcast(tell,dispenser(D1X+X,D1Y+Y,"b1"));
		
		?boardSize(Board);
		+dispenser(TX+X,TY+Y,"b1");	//0
		+dispenser(TX+X-Board,TY+Y-Board,"b1");	//top left
		+dispenser(TX+X-0,TY+Y-Board,"b1");		// top
		+dispenser(TX+X+Board,TY+Y-Board,"b1");	//top right
		+dispenser(TX+X+Board,TY+Y+0,"b1");		//right
		+dispenser(TX+X+Board,TY+Y+Board,"b1");	//bottom right
		+dispenser(TX+X+0,TY+Y+Board,"b1");		//bottom
		+dispenser(TX+X-Board,TY+Y+Board,"b1");	//bottom left
		+dispenser(TX+X-Board,TY+Y-0,"b1");		//left
		.broadcast(tell,dispenser(TX+X,TY+Y,"b1"));
		.broadcast(tell,dispenser(TX+X-Board,TY+Y-Board,"b1"));
		.broadcast(tell,dispenser(TX+X-0,TY+Y-Board,"b1"));
		.broadcast(tell,dispenser(TX+X+Board,TY+Y-Board,"b1"));
		.broadcast(tell,dispenser(TX+X+Board,TY+Y+0,"b1"));
		.broadcast(tell,dispenser(TX+X+Board,TY+Y+Board,"b1"));
		.broadcast(tell,dispenser(TX+X+0,TY+Y+Board,"b1"));
		.broadcast(tell,dispenser(TX+X-Board,TY+Y+Board,"b1"));
		.broadcast(tell,dispenser(TX+X-Board,TY+Y-0,"b1"));
	};
	for(thing(D1X,D1Y,dispenser,b2))
	{
		//+dispenser(D1X+X,D1Y+Y,"b1");
		//.broadcast(tell,dispenser(D1X+X,D1Y+Y,"b1"));
		
		?boardSize(Board);
		+dispenser(TX+X,TY+Y,"b2");	//0
		+dispenser(TX+X-Board,TY+Y-Board,"b2");	//top left
		+dispenser(TX+X-0,TY+Y-Board,"b2");		// top
		+dispenser(TX+X+Board,TY+Y-Board,"b2");	//top right
		+dispenser(TX+X+Board,TY+Y+0,"b2");		//right
		+dispenser(TX+X+Board,TY+Y+Board,"b2");	//bottom right
		+dispenser(TX+X+0,TY+Y+Board,"b2");		//bottom
		+dispenser(TX+X-Board,TY+Y+Board,"b2");	//bottom left
		+dispenser(TX+X-Board,TY+Y-0,"b2");		//left
		.broadcast(tell,dispenser(TX+X,TY+Y,"b2"));
		.broadcast(tell,dispenser(TX+X-Board,TY+Y-Board,"b2"));
		.broadcast(tell,dispenser(TX+X-0,TY+Y-Board,"b2"));
		.broadcast(tell,dispenser(TX+X+Board,TY+Y-Board,"b2"));
		.broadcast(tell,dispenser(TX+X+Board,TY+Y+0,"b2"));
		.broadcast(tell,dispenser(TX+X+Board,TY+Y+Board,"b2"));
		.broadcast(tell,dispenser(TX+X+0,TY+Y+Board,"b2"));
		.broadcast(tell,dispenser(TX+X-Board,TY+Y+Board,"b2"));
		.broadcast(tell,dispenser(TX+X-Board,TY+Y-0,"b2"));
	};
	for(goal(TX,TY))
	{
		//+goals(GX+X,GY+Y);
		//.broadcast(tell,goals(GX+X,GY+Y));
		
		?boardSize(Board);
		+goals(TX+X,TY+Y);	//0
		+goals(TX+X-Board,TY+Y-Board);	//top left
		+goals(TX+X-0,TY+Y-Board);		// top
		+goals(TX+X+Board,TY+Y-Board);	//top right
		+goals(TX+X+Board,TY+Y+0);		//right
		+goals(TX+X+Board,TY+Y+Board);	//bottom right
		+goals(TX+X+0,TY+Y+Board);		//bottom
		+goals(TX+X-Board,TY+Y+Board);	//bottom left
		+goals(TX+X-Board,TY+Y-0);		//left
		.broadcast(tell,goals(TX+X,TY+Y));
		.broadcast(tell,goals(TX+X-Board,TY+Y-Board));
		.broadcast(tell,goals(TX+X-0,TY+Y-Board));
		.broadcast(tell,goals(TX+X+Board,TY+Y-Board));
		.broadcast(tell,goals(TX+X+Board,TY+Y+0));
		.broadcast(tell,goals(TX+X+Board,TY+Y+Board));
		.broadcast(tell,goals(TX+X+0,TY+Y+Board));
		.broadcast(tell,goals(TX+X-Board,TY+Y+Board));
		.broadcast(tell,goals(TX+X-Board,TY+Y-0));
	};
	//TODO Obstacles
	for(thing(AX,AY,entity,_))
	{
		+obstacles(AX,AY);
	};
	for(obstacle(OX,OY))
	{
		+obstacles(OX,OY);
	};
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
	-+pathgoal("");
	.random([[0,5],[5,0],[0,-5],[-5,0]],Direction);
	.nth(0,Direction,X);
	.nth(1,Direction,Y);
	.abolish(moveTowards(_,_));
	-+closestPOI(X,Y);
	!moveTowards(X,Y).
+!randomMovement <- !randomMovement.

// instead of instantly moving, give the Agent time to react to surroundings and calculate the next moves	
+!delayMovement : not (path("")) <-
	?path(MovePath); 
	.nth(0,MovePath,Direction);
	?closestPOI(ClosestX,ClosestY);
	for(obstacles(OX,OY))
	{
		if(OX == 0 & OY==-1){+blockedNorth}
		if(OX == 1 & OY== 0){+blockedEast}
		if(OX == 0 & OY== 1){+blockedSouth}
		if(OX ==-1 & OY== 0){+blockedWest}
	};
	if(Direction == "n")
	{
		if(blockedNorth & blockedEast & blockedWest){.random(["se","sw"],PaddedDirection);.concat(PaddedDirection,MovePath,NewPath);}
		elif(blockedNorth & blockedEast ) {.random(["w","ww","www"],PaddedDirection);.concat(PaddedDirection,MovePath,NewPath);}
		elif(blockedNorth & blockedWest ) {.random(["e","ee","eee"],PaddedDirection);.concat(PaddedDirection,MovePath,NewPath);}
		elif(blockedNorth){.random(["e","w"],PaddedDirection);.concat(PaddedDirection,MovePath,NewPath);.print("blocked north")}
		else{.concat("",MovePath,NewPath);}
		
	}
	elif(Direction == "e")
	{
		if(blockedEast & blockedNorth & blockedSouth){.random(["ws","wn"],PaddedDirection);.concat(PaddedDirection,MovePath,NewPath)}
		elif(blockedEast & blockedNorth ) {.random(["s","ss","sss"],PaddedDirection);.concat(PaddedDirection,MovePath,NewPath)}
		elif(blockedEast & blockedSouth ) {.random(["n","nn","nnn"],PaddedDirection);.concat(PaddedDirection,MovePath,NewPath)}
		elif(blockedEast){.random(["n","s"],PaddedDirection);.concat(PaddedDirection,MovePath,NewPath);.print("blocked east")}
		else{.concat("",MovePath,NewPath);}
	}
	elif(Direction == "s")
	{
		if(blockedSouth & blockedEast & blockedWest){.random(["ne","nw"],PaddedDirection);.concat(PaddedDirection,MovePath,NewPath)}
		elif(blockedSouth & blockedEast ) {.random(["w","ww","www"],PaddedDirection);.concat(PaddedDirection,MovePath,NewPath)}
		elif(blockedSouth & blockedWest ) {.random(["e","ee","eee"],PaddedDirection);.concat(PaddedDirection,MovePath,NewPath)}
		elif(blockedSouth){.random(["e","w"],PaddedDirection);.concat(PaddedDirection,MovePath,NewPath);.print("blocked south")}
		else{.concat("",MovePath,NewPath);}
	}
	elif(Direction == "w")
	{
		if(blockedWest & blockedSouth & blockedNorth){.random(["es","en"],PaddedDirection);.concat(PaddedDirection,MovePath,NewPath)}
		elif(blockedWest & blockedSouth ) {.random(["n","nn","nn"],PaddedDirection);.concat(PaddedDirection,MovePath,NewPath)}
		elif(blockedWest & blockedNorth ) {.random(["s","ss","sss"],PaddedDirection);.concat(PaddedDirection,MovePath,NewPath)}
		elif(blockedWest){.random(["s","n"],PaddedDirection);.concat(PaddedDirection,MovePath,NewPath);.print("blocked west")}
		else{.concat("",MovePath,NewPath);}
	}
	
	.nth(0,NewPath,NewDirection);
	.abolish(obstacles(_,_));
	.abolish(obstacle(_,_));
	-blockedNorth;
	-blockedEast;
	-blockedSouth;
	-blockedWest;
	
	//!delayMovement.
	.delete(0,NewPath,P);
	move(NewDirection);
	?currentPosition(X,Y);
	-+believePosition(X,Y);
	-+lastDirection(NewDirection);
	-+path(P).
	
+!delayMovement : path("") <-
	-+currentIntention("check");
	skip.
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
	?currentPosition(PX,PY);
	-+closestPOI(TX,TY);
	.findall(taskboardPos(X,Y),taskboard(X,Y),List); 
	for(taskboard(NewX,NewY)) //determinating which tasboard is the nearest
	{
		?closestPOI(ClosestX,ClosestY);
		lib.findBestPartner(PX,PY,ClosestX,ClosestY,NewX,NewY,Conclusion); //bestpartner function umbenennen?
		if(Conclusion ==new){-+closestPOI(NewX,NewY)};
	};
	
	?closestPOI(CX,CY); //bewegung zum taskboard inizialisieren
	.drop_intention(randomMovement);
	//.suspend(delayMovement);
	-+pathgoal("temp");
	-+path("");
	-+pathgoal("taskboard");
	
	.abolish(moveTowards(_,_));
	!moveTowards(CX-PX,CY-PY);		//reference self back to world center and then towards the point to get the "distance" to object
	!reducePathBy(2). //agents can accepts tasks within a range of 2 blocks from taskboard
	//.resume(delayMovement).		//resume Movement Intention
	
+!findTaskboard <- !randomMovement.
-!findTaskboard <- //for debug
	.print("find Taskboard failed").

//finding dispenser 1&0
+!findDispenser(Block) : dispenser(DX,DY,Block) <-
	-+blockToFind(Block);
	//Find closest of the Item to search
	?currentPosition(PX,PY);
	-+closestPOI(DX,DY);
	for(dispenser(NewX,NewY,Block))
	{
		?closestPOI(ClosestX,ClosestY);
		lib.findBestPartner(PX,PY,ClosestX,ClosestY,NewX,NewY,Conclusion);
		if(Conclusion ==new){-+closestPOI(NewX,NewY)};
	};
	?closestPOI(CX,CY);
	if(CX== PX & CY == PY){!check}
	else{
		.drop_intention(randomMovement);
		.suspend(delayMovement);
		-+pathgoal("temp");
		-+path("");
		-+pathgoal("dispenser");
		.abolish(moveTowards(_,_));
		!moveTowards(CX-PX,CY-PY);		//reference self back to world center and then towards the point to get the "distance" to object
		!reducePathBy(1);	//request block from an adjecent tile
		.resume(delayMovement)		//resume Movement Intention
	}.

+!findDispenser(Block) : true <-
	-+blockToFind(Block);
	?boardSize(Board);
	-+closestPOI(0,0);
	-+currentIntention("move");
	-+pathgoal("dispenser");
	!moveTowards(Board/2,Board/2).
	
-!findDispenser <-
	.print("find Dispenser1 failed").


//finding goalzones
+!findGoalzone : goals(GX,GY) <-
	//Find closest of the Item to search
	?currentPosition(PX,PY);
	-+closestPOI(GX,GY);
	for(goals(NewX,NewY))
	{
		?closestPOI(ClosestX,ClosestY);
		lib.findBestPartner(PX,PY,ClosestX,ClosestY,NewX,NewY,Conclusion);
		if(Conclusion ==new){-+closestPOI(NewX,NewY)};
	};
	?closestPOI(X,Y);
	if(X==PX & Y==PY){!check}
	else
	{
		.drop_intention(randomMovement);
		.suspend(delayMovement);
		-+pathgoal("temp");
		-+path("");
		-+pathgoal("goalZone");
		.abolish(moveTowards(_,_));
		!moveTowards(X-PX,Y-PY);		//reference self back to world center and then towards the point to get the "distance" to object
		//!reducePathBy(1);
		.resume(delayMovement)	//resume Movement Intention
	}.
	
-!findGoalzone <-
	.print("find Goalzone failed").	

//accpeting tasks and finding an available agent to complete a 2Block task with
//accepting tasks
+!acceptTask : true <-
		?currentStep(Step);
		.random([1,1,1,2],NumberOfBlocks);
		if(NumberOfBlocks == 1)
		{
			?currentTasks(TaskID,Deadline,Y,[req(XB,YB,RB)]);	//1-Block Tasks
			-currentTasks(TaskID,_,_,_);		
			if((Deadline<(Step+50)) | acceptedTask(TaskID) ){!acceptTask;.print("not accepting",TaskID)} //only accept tasks that have a chance to be completed, a task can only be accepted by one agent of the team
			else
			{
				.broadcast(tell,acceptedTask(TaskID)); //tell other agents that this task is taken
				accept(TaskID);
				-+oneBlockTask(true);
				-+taskID(TaskID);
				-+pathgoal("");
				-+taskAccepted(true);
				if(.substring("b0",RB)){!findDispenser("b0");}
				elif(.substring("b1",RB)){!findDispenser("b1");}
				elif(.substring("b2",RB)){!findDispenser("b2");}
				-+currentIntention("move");	//only for 1-Block Tasks
			}
		}
		else
		{
			?currentTasks(TaskID,Deadline,Y,[req(XB,YB,RB),req(XA,YA,RA)]);	//2-Block Tasks
			-currentTasks(TaskID,_,_,_);		
			if((Deadline<(Step+50)) | acceptedTask(TaskID) ){!acceptTask;.print("not accepting",TaskID)} //only accept tasks that have a chance to be completed, a task can only be accepted by one agent of the team
			else
			{
				.broadcast(tell,acceptedTask(TaskID)); //tell other agents that this task is taken
				accept(TaskID);
				-+taskID(TaskID);
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
			}
			
		
		}.
	
+!acceptTask <- !acceptTask.
-!acceptTask <-
	//.print("failed accept Task");
	skip.
	
//answering to finding a partner for 2-block tasks	
+!partnersearch(AgentName) : true <-
	.print(AgentName,"wants help");
	?currentPosition(X,Y);
	.my_name(MyName);
	if(taskAccepted | isBusy) //agent has a task already
	{
		.print(MyName ,"I am busy");
	}
	else //agent is available
	{
		+isBusy;
		.suspend(acceptTask);
		.drop_intention(acceptTask);
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
		if(Conclusion == new)
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
	skip;
	.send(AgentName,achieve,chosenAsSupport(MyName,BX,BY,Block)).

+!choosePartner : true <-
	.print("got no replies");
	skip.
	
//chosen support agent updates its belief and starts his part of the task
+!chosenAsSupport(AgentName,X,Y,SupportBlock) : true <-
	-+currentPartner(AgentName);
	-+isSupport(true);
	-+taskAccepted(true);
	.suspend(acceptTask);
	.drop_intention(acceptTask);
	-+bringBlockTo(X,Y);	//Block location to connect onto
	.term2string(SupportBlock,Block);
	.print("search for this Block as Sup",Block);
	if("b0"==Block){!findDispenser("b0")}
	elif("b1"==Block){!findDispenser("b1")}
	elif("b2"==Block){!findDispenser("b2")}
	-+currentIntention("move").	

//requesting block from dispenser 
+!requestBlock : true <-
	?grabDirection(Direction);
	request(Direction);
	.print("requested block!");
	-+currentIntention("attach").

//attaching a requested block and storing the direction in which the block is attached to the agent
+!attachBlock : oneBlockTask(X) <-
	?grabDirection(Direction);
	attach(Direction);
	.print("grabbed block all by myself!");
	!findGoalzone;
	-+currentIntention("move").

+!attachBlock : true <-
	?grabDirection(Direction);
	attach(Direction);
	.print("grabbed block!");
	
	?currentPartner(AgentName);
	?currentPosition(X,Y);
	if(isSupport(true))
	{
	-+pathgoal("random");
	.random([[0,5],[5,0],[0,-5],[-5,0]],RandomDirection);
	.nth(0,RandomDirection,MoveX);
	.nth(1,RandomDirection,MoveY);
	.abolish(moveTowards(_,_));
	-+closestPOI(MoveX,MoveY);
	!moveTowards(MoveX,MoveY);
	-+currentIntention("waiting");
	}
	else{!findGoalzone;-+currentIntention("move");}.

+!waiting : partnerIsReady(PartnerX,PartnerY)  & bringBlockTo(-1,Y) <-
	-+pathgoal("partner");
	-+currentIntention("move");
	?currentPosition(PX,PY);
	.print("partner told me to go somewhere");
	-+closestPOI(PartnerX-1,PartnerY+2);
	!moveTowards(PartnerX-1-PX,PartnerY+2-PY).
	
+!waiting : partnerIsReady(PartnerX,PartnerY)  & bringBlockTo(0,Y)	<-
	-+pathgoal("partner");
	-+currentIntention("move");
	?currentPosition(PX,PY);
	.print("partner told me to go somewhere");
	-+closestPOI(PartnerX-1,PartnerY+2);
	!moveTowards(PartnerX-1-PX,PartnerY+2-PY).
+!waiting : partnerIsReady(PartnerX,PartnerY)  & bringBlockTo(1,Y)<-
	-+pathgoal("partner");
	-+currentIntention("move");
	?currentPosition(PX,PY);
	.print("partner told me to go somewhere");
	-+closestPOI(PartnerX+1,PartnerY+2);
	!moveTowards(PartnerX+1-PX,PartnerY+2-PY).
+!waiting : path("") <-
	skip.
+!waiting : true <-
	!delayMovement.

	
	
+!mergeBlocks : isSupport(true) & partnerIsReady(X,Y) <-
		?bringBlockTo(X,Y);
		?currentPartner(Agent);
		if(Y==1)//rotate to point north
		{
			if(grabDirection("s")){rotate("cw");-+grabDirection("w")}
			elif(grabDirection("e")){rotate("ccw");-+grabDirection("n");.send(Agent,tell,readyToSupport("n"));-+currentIntention("connect")}
			elif(grabDirection("w")){rotate("cw");-+grabDirection("n");.send(Agent,tell,readyToSupport("n"));-+currentIntention("connect")}
			else{.send(Agent,tell,readyToSupport("n"));-+currentIntention("connect")}
		}
		else //point east
		{
			if(grabDirection("s")){rotate("ccw");-+grabDirection("e");.send(Agent,tell,readyToSupport("e"));-+currentIntention("connect")}
			elif(grabDirection("n")){rotate("cw");-+grabDirection("e");.send(Agent,tell,readyToSupport("e"));-+currentIntention("connect")}
			elif(grabDirection("w")){rotate("cw");-+grabDirection("n")}
			else{.send(Agent,tell,readyToSupport("n"));-+currentIntention("connect")}
		}
		.print("start merge").
		
+!mergeBlocks : ~isSupport(true)& partnerIsReady(X,Y) <-
	?currentPartner(Agent);
	if(grabDirection("n")){rotate("cw");-+grabDirection("e")}
	elif(grabDirection("e")){rotate("cw");-+grabDirection("s");.send(Agent,tell,readyToConnect("s"));-+currentIntention("connect")}
	elif(grabDirection("w")){rotate("ccw");-+grabDirection("s");.send(Agent,tell,readyToConnect("s"));-+currentIntention("connect")}
	else{.send(Agent,tell,readyToConnect("s"));-+currentIntention("connect")}
	.print("start merge").
		
+!mergeBlocks :true <-
	.print("waiting for Partner");
	skip.

-!mergeBlocks <-
	skip.

+!connect : readyToSupport(SupportGrab) <-
	?currentPartner(Agent);
	?grabDirection(GrabDir);
	connect(Agent,0,1);
	-+currentIntention("submit").
+!connect : readyToConnect(MainGrabber) <-
	?currentPartner(Agent);
	?grabDirection(GrabDir);
	if(GrabDir == "n"){connect(Agent,0,-1)}
	elif(GrabDir == "e"){connect(Agent,1,0)}
	-currentPartner;
	-taskID;
	-taskAccepted;
	-+currentIntention("move");
	!findTaskboard.
	
//submitting a task, deleting the task from the beliefbase

+!submit : grabDirection("n") <-	rotate("cw");	-+grabDirection("e").
+!submit : grabDirection("e") <-	rotate("cw");	-+grabDirection("s").
+!submit : grabDirection("w") <-	rotate("ccw");	-+grabDirection("s").

+!submit : true <-
	?taskID(TaskID);
	submit(TaskID);
	-taskID;
	-+currentIntention("unattach");
	!findTaskboard;
	.print("I DID IT!");
	-taskAccepted.
	//todo? telling other agents that the task is finished, maybe usefull for pvp
-!submit : true <-
	skip.

+!unattach : clearCounter(3) <- //detach oneself from earthly bounds aka explosions
	-+currentIntention("move");
	skip;
	-clearCounter(_).
+!unattach : clearCounter(X) <- //detach oneself from earthly bounds aka explosions
	clear(0,1);
	-+clearCounter(X+1).

+!unattach : true <- //detach oneself from earthly bounds aka explosions
	clear(0,1);
	-+clearCounter(1).
	


