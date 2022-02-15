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

            int xDistanceBest = Math.abs(myxCoord - bestxCoord);
            int yDistanceBest = Math.abs(myyCoord - bestyCoord); 
            int xDistanceNew = Math.abs(myxCoord - newxCoord);
            int yDistanceNew = Math.abs(myyCoord - newyCoord);

            int xDBest = xDistanceBest;
            int yDBest = yDistanceBest;
            int xDNew = xDistanceNew;
            int yDNew = yDistanceNew;

            if (Math.abs(xDistanceBest -50) < xDistanceBest)
            {
                xDBest = Math.abs(xDistanceBest -50);
            }
            if (Math.abs(yDistanceBest -50) < yDistanceBest)
            {
                yDBest = Math.abs(yDistanceBest -50);
            }

            

            if (Math.abs(xDistanceNew -50) < xDistanceNew)
            {
                xDNew = Math.abs(xDistanceNew -50);
            }
            if (Math.abs(yDistanceNew -50) < yDistanceNew)
            {
                yDNew = Math.abs(yDistanceNew -50);
            } 


            int bestDistance = xDBest + yDBest;
            int newDistance = xDNew + yDNew;

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

