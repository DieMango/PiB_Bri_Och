// Agent bob in project MAPC2018.mas2j

/* Initial beliefs and rules */

personalPosition(0,0,0).	
globalPosition(_,_,_). // global position will be centered around agent1 personal start point
/* Initial goals */

!start.

!moveTowards.

/* Plans */

+!start : true <- 
	.print("hello massim world.").

+step(X) : true <-
	.print("Received step percept.").
	
+actionID(X) : true <- 
		.random(["n","e","s","w"],Direction);
		move(Direction).

+thing(X,Y,taskboard,_) : true <-
	.print("Found taskboard! at:",X,":",Y).
	
	

		
