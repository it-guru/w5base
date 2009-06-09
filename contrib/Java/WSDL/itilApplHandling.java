import net.w5base.mod.itil.appl.*;
import org.apache.axis.client.Stub;
import org.apache.axis.client.Call;
import org.apache.log4j.PropertyConfigurator; 
import org.apache.log4j.Logger; 
import java.util.*;
import java.text.*;


public class itilApplHandling {
  public static void main(String [] args) throws Exception {
    PropertyConfigurator.configure("log4j.properties"); 
    // define the needed variables
    net.w5base.mod.itil.appl.W5Base          W5Service;
    net.w5base.mod.itil.appl.Port            W5Port;
    net.w5base.mod.itil.appl.StoreableRec    Record;
    net.w5base.mod.itil.appl.Record          CurRec;
    net.w5base.mod.itil.appl.StoreRecInp     Inp;
    net.w5base.mod.itil.appl.StoreRecOut     Res;
    net.w5base.mod.itil.appl.DeleteRecInp    DInp;
    net.w5base.mod.itil.appl.DeleteRecOut    DRes;
    net.w5base.mod.itil.appl.Filter          Flt;
    net.w5base.mod.itil.appl.FindRecordInp   FInput;
    net.w5base.mod.itil.appl.FindRecordOut   Result;

    // prepare the connection to the dataobject
    W5Service=
      new net.w5base.mod.itil.appl.W5BaseLocator();

    W5Port = W5Service.getW5ItilAppl();

    ((Stub) W5Port)._setProperty(Call.USERNAME_PROPERTY, "dummy/admin");
    ((Stub) W5Port)._setProperty(Call.PASSWORD_PROPERTY, "acache");

    //
    // create an application
    //
    Record=new net.w5base.mod.itil.appl.StoreableRec();
    Inp=new net.w5base.mod.itil.appl.StoreRecInp();
    Record.setName("MyTestApp");
    Record.setCistatusid("4");
    Record.setMandatorid("200");

    Inp.setData(Record);

    Res=W5Port.storeRecord(Inp);
    if (Res.getExitcode()!=0){
       System.out.println(itguru.join(Res.getLastmsg(),"\n"));
       System.exit(1);
    }
    System.out.println("OK, new appl created: W5BaseID="+Res.getIdentifiedBy());
    Thread.sleep(5000);

    //
    // update an application
    //
    Record=new net.w5base.mod.itil.appl.StoreableRec();
    Inp=new net.w5base.mod.itil.appl.StoreRecInp();
    Record.setComments("these are my comments");
    Inp.setData(Record);
    Inp.setIdentifiedBy(Res.getIdentifiedBy());

    Res=W5Port.storeRecord(Inp);
    if (Res.getExitcode()!=0){
       System.out.println(itguru.join(Res.getLastmsg(),"\n"));
       System.exit(1);
    }
    System.out.println("OK, update was successfuly");
    Thread.sleep(5000);

    //
    // update an application to disposed of waste
    //
    Record=new net.w5base.mod.itil.appl.StoreableRec();
    Inp=new net.w5base.mod.itil.appl.StoreRecInp();
    Record.setCistatusid("6");
    Record.setDataboss("Vogler, Hartmut*");
    Inp.setData(Record);
    Inp.setIdentifiedBy(Res.getIdentifiedBy());

    Res=W5Port.storeRecord(Inp);
    if (Res.getExitcode()!=0){
       System.out.println(itguru.join(Res.getLastmsg(),"\n"));
       System.exit(1);
    }
    System.out.println("OK, application is now disposed of waste");
    Thread.sleep(5000);

    //
    // delete application
    //
    DInp=new net.w5base.mod.itil.appl.DeleteRecInp();
    DInp.setIdentifiedBy(Res.getIdentifiedBy());

    DRes=W5Port.deleteRecord(DInp);
    if (DRes.getExitcode()!=0){
       System.out.println(itguru.join(DRes.getLastmsg(),"\n"));
       System.exit(1);
    }
    System.out.println("OK, application is now deleted");
  }
}
