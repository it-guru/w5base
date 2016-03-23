<?php
require_once 'Net/DNS2.php';

header("Content-Type: text/plain");
$name=$_GET['q'];
printf("query: %s\n\n",$name);
if ($name!=""){
   $resolver = new Net_DNS2_Resolver();
   try{
      $resp = $resolver->query($name, 'A');
   }
   catch(Net_DNS2_Exception $e){
      echo "fail: ", $e->getMessage(), "\n";
      exit(1);
   }
   printf("response:\n");
   foreach($resp->answer as $arec){
      if (property_exists($arec,"address")){
         printf("%s A %s\n", $arec->name, $arec->address);
      }
   }
}
?>
