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
        output.write(Connector.createMoveMessage(id,direction));
    }
    public void sendAcceptMessage(String id,String taskName) throws IOException
    {
        output.write(Connector.createAcceptMessage(id,taskName));
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
            String[] goal = searchSurroundings("taskboard");
            if (goal == null )
            {
                sendRandomMovement(readActionID());
                return;
            }

            int x = Integer.parseInt(goal[0]);
            int y = Integer.parseInt(goal[1]);

            if (Math.abs(x) + Math.abs(y) <=2)     //is distance to goal >2
            {
                sendAcceptMessage(readActionID(),readTaskID());
            }
            else    // movement towards the taskboard
            {
                if (Math.abs(x) > Math.abs(y) )
                {
                    if(x>0)
                    {
                        sendMoveMessage(readActionID(),"e");
                    }
                    else
                    {
                        sendMoveMessage(readActionID(), "w");
                    }
                }
                else
                {
                    if(y>0)
                    {
                        sendMoveMessage(readActionID(),"s");
                    }
                    else
                    {
                        sendMoveMessage(readActionID(), "n");
                    }
                }
            }





            //sendRandomMovement(readActionID()); // TODO until change movement is random
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

        int idStart = receivedData.indexOf("id\":") + 4;
        int idEnd = receivedData.indexOf(",", idStart);

        String action_id = "";
        if (idStart != -1)
        {
            action_id = receivedData.substring(idStart, idEnd);
            //System.out.println(action_id);
        }
        return action_id;
    }

    private String readTaskID()   // read all the tasks in the percept TODO change!  return first task found and only the ID    need to read deadline and requirements
    {
        String taskID = "";

        int tasksStart = receivedData.indexOf("tasks") + 7;     //start searching

        int taskNameStart = receivedData.indexOf("name",tasksStart) + 7;

        int  taskNameEnd = receivedData.indexOf("\"",taskNameStart);

        //to search for the next taskId start from the last name location

        if (tasksStart != -1)
        {
            taskID = receivedData.substring(taskNameStart, taskNameEnd);
            //System.out.println(taskID)
            return taskID;
        }
        return null;
    }

    private String[] searchSurroundings(String object) // searches the percept for the object given and returns x and y coordinates
    {
        int percStart = receivedData.indexOf("percept\":");

        int thingsStart = receivedData.indexOf("things\":",percStart);

        int objectEnd = receivedData.indexOf(object,thingsStart);

        if (objectEnd != -1)
        {
            String subString = receivedData.substring(thingsStart,objectEnd);

            int coordsStart= subString.lastIndexOf("{");

            int xCoordStart = subString.indexOf("x",coordsStart) + 3;
            int xCoordEnd = subString.indexOf(",",xCoordStart);

            int yCoordStart = subString.indexOf("y",coordsStart) + 3;
            int yCoordEnd = subString.indexOf(",",yCoordStart);

            String xCoordString = subString.substring(xCoordStart,xCoordEnd);
            String yCoordString = subString.substring(yCoordStart,yCoordEnd);

            String [] returnString = new String[2];
            returnString[0] = xCoordString;
            returnString[1] = yCoordString;

            System.out.println(xCoordString + "  " + yCoordString);

            return returnString;

        }
        return null;
    }

    private String searchTaskName()
    {
        return null;
    }






}
