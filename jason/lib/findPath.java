/* Code skeleton used from jason example gold-miner */

package lib;

import jason.asSemantics.DefaultInternalAction;
import jason.asSemantics.TransitionSystem;
import jason.asSemantics.Unifier;
import jason.asSyntax.Atom;
import jason.asSyntax.NumberTerm;
import jason.asSyntax.Term;

import java.util.Random;

import java.lang.Math.*;



public class findPath extends DefaultInternalAction
{

    @Override

    public Object execute(TransitionSystem ts, Unifier un, Term[] terms) throws Exception
    {
        try
        {
            String moveSet = "";

            int xCoord = (int)( (NumberTerm)terms[0] ).solve();
            int yCoord = (int)( (NumberTerm)terms[1] ).solve();


            // TODO actual pathfinding
            //currently moves along the longest axis first with a priority of X

            while(! (xCoord == 0 & yCoord == 0) )        //when 0;0 is reached the path is complete
            {
                if (Math.abs(xCoord) >= Math.abs(yCoord))
                {
                    if (xCoord > 0) {moveSet += "e"; xCoord += -1;}
                    if (xCoord < 0) {moveSet += "w"; xCoord +=  1;}
                }
                else if (Math.abs(yCoord) > Math.abs(xCoord))
                {
                    if (yCoord > 0) {moveSet += "s"; yCoord += -1;}
                    if (yCoord < 0) {moveSet += "n"; yCoord +=  1;}
                }
            }
            return un.unifies( new Atom(moveSet) ,terms [2]);
            //return moveSet;
        }
        catch (Throwable e)
        {
            e.printStackTrace();
            return false;
        }

    }


}

