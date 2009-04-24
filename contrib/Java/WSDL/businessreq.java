import net.w5base.mod.AL_TCom.workflow.businesreq.*;
import org.apache.axis.client.Stub;
import org.apache.axis.client.Call;

public class businessreq {
  public static void main(String [] args) throws Exception {

    // define the needed variables
    net.w5base.mod.AL_TCom.workflow.businesreq.W5Base        W5Service;
    net.w5base.mod.AL_TCom.workflow.businesreq.Port          W5Port;
    net.w5base.mod.AL_TCom.workflow.businesreq.WfRec         WfRec;
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
    WfRec.setName("This is a test AL_TCom Business Request");
    WfRec.setDetaildescription("This is the description of my request\n"+
                               "This description can have more than one line");
    WfRec.setAffectedapplication("W5Base/Darwin");

    Inp.setData(WfRec);

    Res=W5Port.storeRecord(Inp);
    if (Res.getExitcode()!=0){
       System.out.println("BUG="+Res.getLastmsg()[0]);
       System.exit(1);
    }
    System.out.println("new WorkflowID="+Res.getIdentifiedBy());
 
    //
    // find an existing workflow
    //
    FInput=new net.w5base.mod.AL_TCom.workflow.businesreq.FindRecordInp();
    Flt=new net.w5base.mod.AL_TCom.workflow.businesreq.Filter();
    Flt.setId(Res.getIdentifiedBy().toString());
    FInput.setFilter(Flt);
    FInput.setView("name,stateid");

    // do the Query
    Result=W5Port.findRecord(FInput);

    // show the Result
    for (net.w5base.mod.AL_TCom.workflow.businesreq.Record rec: 
         Result.getRecords()){
       System.out.println(rec.getName()+" = "+rec.getStateid());
    }


  }
}
