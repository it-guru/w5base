import net.w5base.mod.AL_TCom.workflow.change.*;
import org.apache.axis.client.Stub;
import org.apache.axis.client.Call;
import org.apache.log4j.PropertyConfigurator; 
import org.apache.log4j.Logger; 
import java.util.*;
import java.text.*;


public class changefollowup {
  public static void main(String [] args) throws Exception {
    PropertyConfigurator.configure("log4j.properties"); 
    // define the needed variables
    net.w5base.mod.AL_TCom.workflow.change.W5Base        W5Service;
    net.w5base.mod.AL_TCom.workflow.change.W5AL_TComWorkflowChangePort          W5Port;
    net.w5base.mod.AL_TCom.workflow.change.WfRec         WfRec;
    net.w5base.mod.AL_TCom.workflow.change.Record        CurRec;
    net.w5base.mod.AL_TCom.workflow.change.StoreRecInp   Inp;
    net.w5base.mod.AL_TCom.workflow.change.StoreRecOut   Res;
    net.w5base.mod.AL_TCom.workflow.change.Filter        Flt;
    net.w5base.mod.AL_TCom.workflow.change.FindRecordInp FInput;
    net.w5base.mod.AL_TCom.workflow.change.FindRecordOut Result;

    // prepare the connection to the dataobject
    W5Service=
      new net.w5base.mod.AL_TCom.workflow.change.W5BaseLocator();

    W5Port = W5Service.getW5AL_TComWorkflowChange();

    ((Stub) W5Port)._setProperty(Call.USERNAME_PROPERTY, "dummy/admin");
    ((Stub) W5Port)._setProperty(Call.PASSWORD_PROPERTY, "acache");

    Inp=new net.w5base.mod.AL_TCom.workflow.change.StoreRecInp(); 
    //
    // find an existing workflow
    //
    FInput=new net.w5base.mod.AL_TCom.workflow.change.FindRecordInp();
    Flt=new net.w5base.mod.AL_TCom.workflow.change.Filter();
    Flt.setSrcid("T-CHM00516586");
    FInput.setFilter(Flt);
    FInput.setView("posibleactions,id,detaildescription,mdate,name,stateid,step");

    // do the Query
    Result=W5Port.findRecord(FInput);
    if (Result.getExitcode()!=0){
       System.out.println(itguru.join(Result.getLastmsg(),"\n"));
       System.exit(1);
    }


    // show the Result
    CurRec=null;
    for (net.w5base.mod.AL_TCom.workflow.change.Record rec: 
         Result.getRecords()){
       CurRec=rec;
    }
    if (CurRec!=null){
       System.out.println(CurRec.getName()+" = "+CurRec.getStateid());
       SimpleDateFormat df = new SimpleDateFormat( "dd.MM.yyyy HH:mm:ss" );
       System.out.println("step = "+CurRec.getStep());
       System.out.println("mdate = "+df.format(CurRec.getMdate().getTime()));
       System.out.println("posible actions= "+
                    itguru.join(CurRec.getPosibleactions(),", "));
     
       if (itguru.exitsIn(CurRec.getPosibleactions(),"wffollowup")){
          System.out.printf("try to send a followup note\n");
          WfRec=new net.w5base.mod.AL_TCom.workflow.change.WfRec();
          WfRec.setAction("wffollowup");
          WfRec.setNote("This is a note, whitch should be send to the\n"+
                        "current user, to witch the workflow is forwared");
          Inp.setData(WfRec);
          Inp.setLang("de");
          Inp.setIdentifiedBy(CurRec.getId());
          Res=W5Port.storeRecord(Inp);
          if (Res.getExitcode()==0){
             System.out.printf("note has been successfuly send\n");
          }
          else{
             System.out.println(itguru.join(Res.getLastmsg(),"\n"));
          }
       }
    }
  }
}
