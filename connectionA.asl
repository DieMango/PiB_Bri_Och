// Agent bob in project MAPC2018.mas2j

/* Initial beliefs and rules */

personalPosition(0,0,0).	
globalPosition(_,_,_). // global position will be centered around agent1 personal start point

taskAccepted (false).
/* Initial goals */

!randomMovement.

/* Plans */

+actionID(X) : true <- 
	+canSendAction(true).
	
+!randomMovement : canSendAction(true) <-
		.random(["n","e","s","w"],Direction);
		move(Direction);
		.abolish(canSendAction);
		!randomMovement.
		
+!randomMovement <- !randomMovement.

+thing(X,Y,taskboard,_) : true <-
	.print("Found taskboard! at:",X,":",Y);
	!moveTowards(X,Y); 
	.succeed_goal(randomMovement).
	
+!moveTowards(X,Y) : canSendAction(true) <-
	.abolish(canSendAction);
	if( ((0<= Y)&(Y<= X)) | ((0>= Y)&(Y>= X))|((0<= Y)&(Y<= -X)) | ((0>= Y)&(Y>= -X)))
    	{
        	if(X>0){move("w");}
       		elif(X<0){move("e");}
		}
    elif(((0<= X)&(X<= Y)) | ((0 >=X)&(X>= Y))|((0<= X)&(X<= -Y)) | ((0 >=X)&(X>= -Y)))
    	{
        	if(Y>0){move("s");}
			elif(Y<0){move("n");}
		}
	else {.print("move failed" ,X,Y);}.
	
