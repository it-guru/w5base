import net.w5base.webservice.mod.base.user.*;
import net.w5base.webservice.mod.base.grp.*;
import org.apache.axis.client.Stub;
import org.apache.axis.client.Call;


public class PingTest {
  public static void main(String [] args) throws Exception {
    // Make a service
    net.w5base.webservice.mod.base.user.W5Base service = 
          new net.w5base.webservice.mod.base.user.W5BaseLocator();

    // Now use the service to get a stub which implements the SDI.
    net.w5base.webservice.mod.base.user.W5BaseUserPort W5Kernel = service.getW5BaseUser();

    ((Stub) W5Kernel)._setProperty(Call.USERNAME_PROPERTY, "dummy/admin");
    ((Stub) W5Kernel)._setProperty(Call.PASSWORD_PROPERTY, "acache");


    net.w5base.webservice.mod.base.user.DoPingOutput output=
         W5Kernel.doPing(new net.w5base.webservice.mod.base.user.DoPingInput());

    System.out.println("result of doPiong="+output.getResult()+"\n");
   
    net.w5base.webservice.mod.base.user.ShowFieldsOutput fld=
        W5Kernel.showFields(new net.w5base.webservice.mod.base.user.ShowFieldsInput());
    System.out.println("res of showFields: output:\n========================");
    for (net.w5base.webservice.mod.base.user.Field f: fld.getRecords()){
       System.out.println("fieldname="+f.getName()+" fieldtype="+f.getType());
    }

  }
}
