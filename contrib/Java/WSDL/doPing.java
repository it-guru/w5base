import net.w5base.mod.base.user.*;
import net.w5base.mod.base.grp.*;
import org.apache.axis.client.Stub;
import org.apache.axis.client.Call;


public class doPing {
  public static void main(String [] args) throws Exception {
    // Make a service
    net.w5base.mod.base.user.W5Base service = 
          new net.w5base.mod.base.user.W5BaseLocator();

    // Now use the service to get a stub which implements the SDI.
    net.w5base.mod.base.user.W5BaseUserPort W5Port = service.getW5BaseUser();

    ((Stub) W5Port)._setProperty(Call.USERNAME_PROPERTY, "dummy/admin");
    ((Stub) W5Port)._setProperty(Call.PASSWORD_PROPERTY, "acache");


    net.w5base.mod.base.user.DoPingOutput output=
         W5Port.doPing(new net.w5base.mod.base.user.DoPingInput());

    System.out.println("result of doPiong="+output.getResult()+"\n");
   

  }
}
