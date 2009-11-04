import net.w5base.mod.base.MyW5Base.wfmyjobs.*;
import org.apache.axis.client.Stub;
import org.apache.axis.client.Call;
import org.apache.log4j.PropertyConfigurator;
import org.apache.log4j.Logger;


public class wfmyjobs {
  public static void main(String [] args) throws Exception {

    PropertyConfigurator.configure("log4j.properties");

    // define the needed variables
    net.w5base.mod.base.MyW5Base.wfmyjobs.W5Base        W5Service;
    net.w5base.mod.base.MyW5Base.wfmyjobs.W5BaseMyW5BaseWfmyjobsPort
    W5Port;
    net.w5base.mod.base.MyW5Base.wfmyjobs.Filter        Flt;
    net.w5base.mod.base.MyW5Base.wfmyjobs.FindRecordOut Result;
    net.w5base.mod.base.MyW5Base.wfmyjobs.FindRecordInp FindRecordInput;

    // Make a service
    W5Service = new net.w5base.mod.base.MyW5Base.wfmyjobs.W5BaseLocator();

    // Now use the service to get a stub which implements the SDI.
    W5Port = W5Service.getW5BaseMyW5BaseWfmyjobs();

    ((Stub) W5Port)._setProperty(Call.USERNAME_PROPERTY, "dummy/admin");
    ((Stub) W5Port)._setProperty(Call.PASSWORD_PROPERTY, "acache");


    Flt            =new net.w5base.mod.base.MyW5Base.wfmyjobs.Filter();
    FindRecordInput=new net.w5base.mod.base.MyW5Base.wfmyjobs.FindRecordInp();

    // prepare the query parameters
    net.w5base.mod.base.MyW5Base.wfmyjobs.Viewstate     vs;
    vs=net.w5base.mod.base.MyW5Base.wfmyjobs.Viewstate.fromString(
           "HIDEUNNECESSARY");

    Flt.setViewstate(vs);
    FindRecordInput.setFilter(Flt);
    FindRecordInput.setView("id,name");

    // do the Query
    Result=W5Port.findRecord(FindRecordInput);

    // show the Result
    Integer c=0;
    for (net.w5base.mod.base.MyW5Base.wfmyjobs.Record rec: Result.getRecords()){
       c++;
       System.out.printf("%-3d %15s %s\n",c,rec.getId(),rec.getName());
    }


  }
}
