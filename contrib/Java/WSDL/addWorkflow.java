import net.w5base.mod.AL_TCom.workflow.businesreq.*;
import org.apache.axis.client.Stub;
import org.apache.axis.client.Call;

public class addWorkflow {
  public static void main(String [] args) throws Exception {

    // define the needed variables
    net.w5base.mod.AL_TCom.workflow.businesreq.W5Base      W5Service;
    net.w5base.mod.AL_TCom.workflow.businesreq.Port        W5Port;
    net.w5base.mod.AL_TCom.workflow.businesreq.WfRec       WfRec;
    net.w5base.mod.AL_TCom.workflow.businesreq.StoreRecInp Inp;
    net.w5base.mod.AL_TCom.workflow.businesreq.StoreRecOut Res;

    // prepare the connection to the dataobject
    W5Service=
      new net.w5base.mod.AL_TCom.workflow.businesreq.W5BaseLocator();

    W5Port = W5Service.getW5AL_TComWorkflowBusinesreq();

    ((Stub) W5Port)._setProperty(Call.USERNAME_PROPERTY, "dummy/admin");
    ((Stub) W5Port)._setProperty(Call.PASSWORD_PROPERTY, "acache");

    WfRec=new net.w5base.mod.AL_TCom.workflow.businesreq.WfRec();
    Inp=new net.w5base.mod.AL_TCom.workflow.businesreq.StoreRecInp();
    WfRec.setName("Hallo mein JavaTest");
    WfRec.setDetaildescription("This is the long text");
    WfRec.setAffectedapplication("W5Base/Darwin");

    Inp.setData(WfRec);

    Res=W5Port.storeRecord(Inp);
    if (Res.getExitcode()!=0){
       System.out.println("BUG="+Res.getLastmsg()[0]);
       System.exit(1);
    }
    System.out.println("new WorkflowID="+Res.getIdentifiedBy());
  }
}
