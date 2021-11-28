package test;

import java.net.*;
import java.nio.charset.StandardCharsets;
import java.io.*;
import java.util.Random;
import java.util.random.*;



public class Connector 
{

	public static void main(String[] args)
	{
		String hostname = "localhost";
		int port = 12300;

		Agent agents[] = new Agent[15];// create Array that contains each agent to loop through

		for(int i=1;i<=15;i++)	// loop through every Agent once to receive, calculate and send messages
		{
			try
			{
				agents[i-1] = new Agent(i);
				agents[i-1].setSocket(hostname,port);	// conncet to server via Socket
				agents[i-1].sendAuthMessage();		// send Authentification Message to start communication
			}
			catch (IOException e)
			{
				e.printStackTrace();
			}
		}

		while(true) //infite loop for the all the game
		{
			for(int i=1;i<=15;i++)	// loop through every Agent once to receive, calculate and send messages
			{
				try
				{
					agents[i-1].receiveData();
					agents[i-1].reactToInput();

				} catch (IOException e)
				{
					e.printStackTrace();
				}


			}


		}

	}



	public static byte[] createMoveMessage(String id,String direction)	//creates Move Message from id and direction given
	{
		String JsonMoveString = "{'type': 'action','content': {'id': " + id +",'type': 'move','p': ['"+ direction +"']}}0";

		return convertMessage(JsonMoveString);
	}
	public static byte[] createAuthMessage(String agent,String password) // creates Authentication Message from agent-number and password given
	{
		String jsonAuthData = "{'type': 'auth-request','content': {'user': '" + agent + "','pw': '"+ password +  "'}}0";

		return	convertMessage(jsonAuthData);
	}
	public static byte[] convertMessage(String message) // converts message from a String into a sendable Json-Byte-String
	{
		byte[] convertedString = message.getBytes(StandardCharsets.UTF_8);
		convertedString[convertedString.length-1] = (byte)0;		// add a 0 in byte form as an "end" bit

		return convertedString;
	}


}
