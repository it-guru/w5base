public class itguru {

   public static String limitTo(String l,int n)
   {
      if (l.length()>n){
         l=l.substring(0,n-3)+"...";
      }
      return(l);
   }
   public static String join(String[] l,String sep)
   {
      String res="";
     
      for(int c=0;c<l.length;c++){
         if (c>0){
            res+=sep;
         }
         res+=l[c];
      }
      return(res);
   }

   public static Boolean exitsIn(String[] l,String chk)
   {
      String res="";
     
      for(int c=0;c<l.length;c++){
         if (l[c].equals(chk)){
            return(true);
         }
      }
      return(false);
   }


}
