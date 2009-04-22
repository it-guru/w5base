import net.w5base.webservice.mod.base.user.*;
import org.apache.axis.client.Stub;
import org.apache.axis.client.Call;

public class ListUser {
  public static void main(String [] args) throws Exception {

    // define the needed variables
    net.w5base.webservice.mod.base.user.W5Base           W5Service;
    net.w5base.webservice.mod.base.user.W5BaseUserPort   W5BaseUser;
    net.w5base.webservice.mod.base.user.Filter           Flt;
    net.w5base.webservice.mod.base.user.FindRecordInput  FindRecordInput;
    net.w5base.webservice.mod.base.user.FindRecordOutput Result;

    // prepare the connection to the dataobject
    W5Service = new net.w5base.webservice.mod.base.user.W5BaseLocator();

    W5BaseUser = W5Service.getW5BaseUser();

    ((Stub) W5BaseUser)._setProperty(Call.USERNAME_PROPERTY, "dummy/admin");
    ((Stub) W5BaseUser)._setProperty(Call.PASSWORD_PROPERTY, "acache");

    Flt            =new net.w5base.webservice.mod.base.user.Filter();
    FindRecordInput=new net.w5base.webservice.mod.base.user.FindRecordInput();

    // prepare the query parameters
    Flt.setFullname(args[0]);
    FindRecordInput.setFilter(Flt);
    FindRecordInput.setView("fullname,surname");

    // do the Query
    Result=W5BaseUser.findRecord(FindRecordInput);

    // show the Result
    for (net.w5base.webservice.mod.base.user.Record rec: Result.getRecords()){
       System.out.println(rec.getFullname()+" ("+rec.getSurname()+")");
    }
  }
}
