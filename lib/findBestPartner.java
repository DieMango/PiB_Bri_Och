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



public class findBestPartner extends DefaultInternalAction
{

    @Override

    public Object execute(TransitionSystem ts, Unifier un, Term[] terms) throws Exception
    {
        try
        {
            int myxCoord = (int)( (NumberTerm)terms[0] ).solve();
            int myyCoord = (int)( (NumberTerm)terms[1] ).solve();

            int bestxCoord = (int)( (NumberTerm)terms[2] ).solve();
            int bestyCoord = (int)( (NumberTerm)terms[3] ).solve();

            int newxCoord = (int)( (NumberTerm)terms[4] ).solve();
            int newyCoord = (int)( (NumberTerm)terms[5] ).solve();


            int bestDistance = Math.abs(myxCoord - bestxCoord) + Math.abs(myyCoord - bestyCoord);
            int newDistance = Math.abs(myxCoord - newxCoord) + Math.abs(myyCoord - newyCoord);

            if(bestDistance-newDistance > 0)
            {
                return un.unifies( new Atom("new") ,terms [6]);
            }
            else
            {
                return un.unifies( new Atom("stay") ,terms [6]);
            }

        }
        catch (Throwable e)
        {
            e.printStackTrace();
            return false;
        }

    }


}

