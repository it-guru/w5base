import net.w5base.mod.AL_TCom.workflow.change.*;
import org.apache.axis.client.Stub;
import org.apache.axis.client.Call;
import org.apache.log4j.PropertyConfigurator;
import org.apache.log4j.Logger;


public class findChange {
  public static void main(String [] args) throws Exception {

    PropertyConfigurator.configure("log4j.properties");
    // define the needed variables
    net.w5base.mod.AL_TCom.workflow.change.W5Base        W5Service;
    net.w5base.mod.AL_TCom.workflow.change.W5AL_TComWorkflowChangePort  W5Port;
    net.w5base.mod.AL_TCom.workflow.change.Filter        Flt;
    net.w5base.mod.AL_TCom.workflow.change.FindRecordInp FindRecordInput;
    net.w5base.mod.AL_TCom.workflow.change.FindRecordOut Result;

    // prepare the connection to the dataobject
    W5Service = new net.w5base.mod.AL_TCom.workflow.change.W5BaseLocator();

    W5Port = W5Service.getW5AL_TComWorkflowChange();

    ((Stub) W5Port)._setProperty(Call.USERNAME_PROPERTY, "dummy/admin");
    ((Stub) W5Port)._setProperty(Call.PASSWORD_PROPERTY, "acache");

    Flt            =new net.w5base.mod.AL_TCom.workflow.change.Filter();
    FindRecordInput=new net.w5base.mod.AL_TCom.workflow.change.FindRecordInp();

    // prepare the query parameters
    Flt.setSrcid(args[0]);
    FindRecordInput.setFilter(Flt);
    FindRecordInput.setView("id,srcid,name,additional,affectedapplication,"+
                            "wffields.changedescription");

    // do the Query
    Result=W5Port.findRecord(FindRecordInput);
    if (Result.getExitcode()==0){
       // show the Result
       for (net.w5base.mod.AL_TCom.workflow.change.Record rec: 
            Result.getRecords()){
          System.out.printf("\n");
          System.out.printf("WorkflowID:   %s\n",rec.getId());
          System.out.printf("Changenumber: %s\n",rec.getSrcid());
          System.out.printf("Anwendung:    %s\n",
                            itguru.join(rec.getAffectedapplication(),", "));
          System.out.printf("Changename:   \"%s\"\n",
                            itguru.limitTo(rec.getName(),60));
          System.out.printf("\n");

          for (net.w5base.mod.AL_TCom.workflow.change.CItem C:
               rec.getAdditional()){
             System.out.printf(" - %-28s : %s\n",
                               C.getName(),itguru.limitTo(C.getValue(),45));
          }
          System.out.printf("\n");
       }
    }
    else{
       System.out.println(itguru.join(Result.getLastmsg(),"\n"));
       System.exit(1);
    }
  }
}
