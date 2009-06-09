import net.w5base.mod.base.user.*;
import org.apache.axis.client.Stub;
import org.apache.axis.client.Call;
import org.apache.log4j.PropertyConfigurator;
import org.apache.log4j.Logger;


public class baseFiles {
  public static void main(String [] args) throws Exception {

    PropertyConfigurator.configure("log4j.properties");

    // define the needed variables
    net.w5base.mod.base.filemgmt.W5Base        W5Service;
    net.w5base.mod.base.filemgmt.Port          W5Port;
    net.w5base.mod.base.filemgmt.Filter        Flt;
    net.w5base.mod.base.filemgmt.FindRecordInp FindRecordInput;
    net.w5base.mod.base.filemgmt.FindRecordOut Result;

    // prepare the connection to the dataobject
    W5Service = new net.w5base.mod.base.filemgmt.W5BaseLocator();

    W5Port = W5Service.getW5BaseFilemgmt();

    ((Stub) W5Port)._setProperty(Call.USERNAME_PROPERTY, "dummy/admin");
    ((Stub) W5Port)._setProperty(Call.PASSWORD_PROPERTY, "acache");

    Flt            =new net.w5base.mod.base.filemgmt.Filter();
    FindRecordInput=new net.w5base.mod.base.filemgmt.FindRecordInp();

    // prepare the query parameters
    Flt.setParentid("[NULL]");
    FindRecordInput.setFilter(Flt);
    FindRecordInput.setView("fullname");

    // do the Query
    Result=W5Port.findRecord(FindRecordInput);

    // show the Result
    for (net.w5base.mod.base.filemgmt.Record rec: Result.getRecords()){
       System.out.printf("%s\n",
                         itguru.limitTo(rec.getFullname(),39));
       System.out.printf("\n");
    }
  }
}
