import net.w5base.mod.AL_TCom.workflow.businesreq.*;
import org.apache.axis.client.Stub;
import org.apache.axis.client.Call;
import org.apache.log4j.PropertyConfigurator; 
import org.apache.log4j.Logger; 
import java.util.*;
import java.text.*;


public class businessreq2 {
  public static void main(String [] args) throws Exception {
    PropertyConfigurator.configure("log4j.properties"); 
    // define the needed variables
    net.w5base.mod.AL_TCom.workflow.businesreq.W5Base        W5Service;
    net.w5base.mod.AL_TCom.workflow.businesreq.W5AL_TComWorkflowBusinesreqPort          W5Port;
    net.w5base.mod.AL_TCom.workflow.businesreq.WfRec         WfRec;
    net.w5base.mod.AL_TCom.workflow.businesreq.Record        CurRec;
    net.w5base.mod.AL_TCom.workflow.businesreq.StoreRecInp   Inp;
    net.w5base.mod.AL_TCom.workflow.businesreq.StoreRecOut   Res;
    net.w5base.mod.AL_TCom.workflow.businesreq.Filter        Flt;
    net.w5base.mod.AL_TCom.workflow.businesreq.FindRecordInp FInput;
    net.w5base.mod.AL_TCom.workflow.businesreq.FindRecordOut Result;

    // prepare the connection to the dataobject
    W5Service=
      new net.w5base.mod.AL_TCom.workflow.businesreq.W5BaseLocator();

    W5Port = W5Service.getW5AL_TComWorkflowBusinesreq();

    ((Stub) W5Port)._setProperty(Call.USERNAME_PROPERTY, "dummy/admin");
    ((Stub) W5Port)._setProperty(Call.PASSWORD_PROPERTY, "acache");

    //
    // create a new workflow
    //
    WfRec=new net.w5base.mod.AL_TCom.workflow.businesreq.WfRec();
    Inp=new net.w5base.mod.AL_TCom.workflow.businesreq.StoreRecInp();
    WfRec.setName("This is a test AL_TCom הצü Business Request");
    WfRec.setDetaildescription("This is the description of my request\n"+
                               "This \\n description can \\\\n have more than one line");
    WfRec.setNoautoassign(true);
    WfRec.setAffectedapplication("W5Base/Darwin");
    WfRec.setCustomerrefno("INETWORK:112233");
    WfRec.setReqnature("appl.base.base");
    WfRec.setReqdesdate("yesterday would be best");
    WfRec.setSrcsys("Plasma");

    Inp.setData(WfRec);
    Inp.setLang("de");

    Res=W5Port.storeRecord(Inp);
    if (Res.getExitcode()!=0){
       System.out.println(itguru.join(Res.getLastmsg(),"\n"));
       System.exit(1);
    }
    System.out.println("new WorkflowID="+Res.getIdentifiedBy());
 
  }
}
