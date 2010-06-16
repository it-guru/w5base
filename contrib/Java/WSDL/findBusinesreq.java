import net.w5base.mod.AL_TCom.workflow.businesreq.*;
import org.apache.axis.client.Stub;
import org.apache.axis.client.Call;
import org.apache.log4j.PropertyConfigurator;
import org.apache.log4j.Logger;
import java.math.BigInteger;


public class findBusinesreq {
  public static void main(String [] args) throws Exception {

    PropertyConfigurator.configure("log4j.properties");
    // define the needed variables
    net.w5base.mod.AL_TCom.workflow.businesreq.W5Base        W5Service;
    net.w5base.mod.AL_TCom.workflow.businesreq.W5AL_TComWorkflowBusinesreqPort  W5Port;
    net.w5base.mod.AL_TCom.workflow.businesreq.Filter        Flt;
    net.w5base.mod.AL_TCom.workflow.businesreq.FindRecordInp FindRecordInput;
    net.w5base.mod.AL_TCom.workflow.businesreq.FindRecordOut Result;

    // prepare the connection to the dataobject
    W5Service = new net.w5base.mod.AL_TCom.workflow.businesreq.W5BaseLocator();

    W5Port = W5Service.getW5AL_TComWorkflowBusinesreq();

    ((Stub) W5Port)._setProperty(Call.USERNAME_PROPERTY, "dummy/admin");
    ((Stub) W5Port)._setProperty(Call.PASSWORD_PROPERTY, "acache");

    Flt            =new net.w5base.mod.AL_TCom.workflow.businesreq.Filter();
    FindRecordInput=new net.w5base.mod.AL_TCom.workflow.businesreq.FindRecordInp();

    // prepare the query parameters
    Flt.setId(new BigInteger(args[0]));
    FindRecordInput.setFilter(Flt);
    FindRecordInput.setView("id,srcid,name,shortactionlog,additional,"+
                            "affectedapplication,wffields.tcomworktime,"+
                            "relations");

    // do the Query
    Result=W5Port.findRecord(FindRecordInput);
    if (Result.getExitcode()==0){
       // show the Result
       for (net.w5base.mod.AL_TCom.workflow.businesreq.Record rec: 
            Result.getRecords()){
//          System.out.printf("\n");
          System.out.printf("WorkflowID:   %s\n",rec.getId());
          System.out.printf("Anwendung:    %s\n",
                            itguru.join(rec.getAffectedapplication(),", "));
          System.out.printf("Businesreqname:   \"%s\"\n",
                            itguru.limitTo(rec.getName(),60));

          System.out.printf("\nposible Actions:\n");
          for (net.w5base.mod.AL_TCom.workflow.businesreq.WorkflowAction C:
               rec.getShortactionlog()){
             System.out.printf(" - %-28s(%d) : %s\n",
                               C.getName(),C.getEffort(),
                               itguru.limitTo(C.getComments(),45));
          }
          System.out.printf("\nactive Relations:\n");
          for (net.w5base.mod.AL_TCom.workflow.businesreq.WorkflowRelation R:
               rec.getRelations()){
             System.out.printf(" - %-28s : %s -> %s\n",
                               R.getName(),R.getSrcwfid(),R.getDstwfid());
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
