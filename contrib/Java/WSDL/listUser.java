import net.w5base.mod.base.user.*;
import org.apache.axis.client.Stub;
import org.apache.axis.client.Call;

public class listUser {
  public static void main(String [] args) throws Exception {

    // define the needed variables
    net.w5base.mod.base.user.W5Base        W5Service;
    net.w5base.mod.base.user.Port          W5Port;
    net.w5base.mod.base.user.Filter        Flt;
    net.w5base.mod.base.user.FindRecordInp FindRecordInput;
    net.w5base.mod.base.user.FindRecordOut Result;

    // prepare the connection to the dataobject
    W5Service = new net.w5base.mod.base.user.W5BaseLocator();

    W5Port = W5Service.getW5BaseUser();

    ((Stub) W5Port)._setProperty(Call.USERNAME_PROPERTY, "dummy/admin");
    ((Stub) W5Port)._setProperty(Call.PASSWORD_PROPERTY, "acache");

    Flt            =new net.w5base.mod.base.user.Filter();
    FindRecordInput=new net.w5base.mod.base.user.FindRecordInp();

    // prepare the query parameters
    Flt.setFullname(args[0]);
    FindRecordInput.setFilter(Flt);
    FindRecordInput.setView("fullname,surname");

    // do the Query
    Result=W5Port.findRecord(FindRecordInput);

    // show the Result
    for (net.w5base.mod.base.user.Record rec: Result.getRecords()){
       System.out.println(rec.getFullname()+" ("+rec.getSurname()+")");
    }
  }
}
