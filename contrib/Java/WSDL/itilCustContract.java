import net.w5base.mod.base.user.*;
import org.apache.axis.client.Stub;
import org.apache.axis.client.Call;

public class itilCustContract {
  public static void main(String [] args) throws Exception {

    // define the needed variables
    net.w5base.mod.AL_TCom.custcontract.W5Base        W5Service;
    net.w5base.mod.AL_TCom.custcontract.Port          W5Port;
    net.w5base.mod.AL_TCom.custcontract.Filter        Flt;
    net.w5base.mod.AL_TCom.custcontract.FindRecordInp FindRecordInput;
    net.w5base.mod.AL_TCom.custcontract.FindRecordOut Result;

    // prepare the connection to the dataobject
    W5Service = new net.w5base.mod.AL_TCom.custcontract.W5BaseLocator();

    W5Port = W5Service.getW5AL_TComCustcontract();

    ((Stub) W5Port)._setProperty(Call.USERNAME_PROPERTY, "dummy/admin");
    ((Stub) W5Port)._setProperty(Call.PASSWORD_PROPERTY, "acache");

    Flt            =new net.w5base.mod.AL_TCom.custcontract.Filter();
    FindRecordInput=new net.w5base.mod.AL_TCom.custcontract.FindRecordInp();

    // prepare the query parameters
    Flt.setCistatusid("4");
    FindRecordInput.setFilter(Flt);
    FindRecordInput.setView("name,fullname,customer,p800opmode");

    // do the Query
    Result=W5Port.findRecord(FindRecordInput);

    // show the Result
    for (net.w5base.mod.AL_TCom.custcontract.Record rec: Result.getRecords()){
       System.out.printf("%-15s %-40s %-15s\n",
                         rec.getName(),
                         itguru.limitTo(rec.getFullname(),39),
                         rec.getP800Opmode());
       System.out.printf("%-15s %-40s %-15s\n",
                         "",
                         rec.getCustomer(),"");
       System.out.printf("\n");
    }
  }
}
