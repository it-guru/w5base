import net.w5base.mod.base.user.*;
import net.w5base.mod.base.grp.*;
import org.apache.axis.client.Stub;
import org.apache.axis.client.Call;
import org.apache.log4j.PropertyConfigurator;
import org.apache.log4j.Logger;


public class showFields {
  public static void main(String [] args) throws Exception {

    PropertyConfigurator.configure("log4j.properties");

    // define the needed variables
    net.w5base.mod.base.user.W5Base        W5Service;
    net.w5base.mod.base.user.Port          W5Port;
    net.w5base.mod.base.user.ShowFieldsInp Input;
    net.w5base.mod.base.user.ShowFieldsOut Result;

    // Make a service
    W5Service = new net.w5base.mod.base.user.W5BaseLocator();

    // Now use the service to get a stub which implements the SDI.
    W5Port = W5Service.getW5BaseUser();

    ((Stub) W5Port)._setProperty(Call.USERNAME_PROPERTY, "dummy/admin");
    ((Stub) W5Port)._setProperty(Call.PASSWORD_PROPERTY, "acache");

    Input=new net.w5base.mod.base.user.ShowFieldsInp();
    Result=W5Port.showFields(Input);

    System.out.println("res of showFields: output:\n========================");
    for (net.w5base.mod.base.user.Field fld: Result.getRecords()){
       System.out.printf("fieldname:%-25s fieldtype:%-20s\n",
                                        fld.getName(),fld.getType());
    }

  }
}
