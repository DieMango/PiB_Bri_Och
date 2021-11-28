package test;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.Socket;
import java.util.Random;

public class Agent
{
    private int number;
    private String agentName;
    private String password = "1";
    private Socket socket;
    private OutputStream output;
    private InputStream input;
    private InputStreamReader reader;
    private StringBuilder receivedData = new StringBuilder();

    public Agent(int nbm)
    {
        number = nbm;
        agentName = "agentA"+ String.valueOf(number);
    }

    public void sendAuthMessage() throws IOException
    {
        output.write(Connector.createAuthMessage(agentName,password));
    }
    public void sendMoveMessage(String id,String direction) throws IOException
    {
        output.write(Connector.createMoveMessage(agentName,direction));
    }
    public void setSocket(String host,int port) throws IOException
    {
        socket = new Socket(host,port);
        output = socket.getOutputStream();
        input = socket.getInputStream();
        reader = new InputStreamReader(input);
    }
    public void receiveData() throws IOException
    {
        int character;
        receivedData = new StringBuilder();
        while ((character = reader.read()) != 0)     // receive data out of the InputStream
        {
            receivedData.append((char) character);
        }
    }

    public void reactToInput() throws IOException  // either communicate with other agents or instantly send move command
    {
        //1.
        System.out.println(receivedData);
        if(receivedData.indexOf("request-action")!= -1)
        {
            sendRandomMovement(readActionID()); // TODO until change movement is random
        }

        //??
        //profit
    }
    private void sendRandomMovement(String id) throws IOException
    {
        Random randomDirection = new Random();
        String moveDirection = "n";

        switch (randomDirection.nextInt(4))//random Direction generation
        {
            case 0: moveDirection = "n"; break;
            case 1: moveDirection = "e"; break;
            case 2: moveDirection = "s"; break;
            case 3: moveDirection = "w"; break;
        }

        output.write(Connector.createMoveMessage(id,moveDirection));
    }
    private String readActionID()   // get id for Action out of the request string
    {

        // search for "id"  until the

        int idStart = receivedData.indexOf("id\":");
        idStart += 4;
        int idEnd = receivedData.indexOf(",", idStart);

        String action_id = "";
        if (idStart != -1)
        {
            action_id = receivedData.substring(idStart, idEnd);
            //System.out.println(action_id);
        }

        System.out.println(action_id);
        return action_id;
    }




}
