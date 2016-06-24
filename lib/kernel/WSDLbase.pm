package kernel::WSDLbase;
#  W5Base Framework
#  Copyright (C) 2006  Hartmut Vogler (it@guru.de)
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
use strict;
use kernel;

#######################################################################
# WSDL integration
#######################################################################
sub WSDLcommon
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $module=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;

   $$XMLtypes.="<xsd:complexType name=\"ArrayOfString\">";
   $$XMLtypes.="<xsd:complexContent>";
   $$XMLtypes.="<xsd:restriction base=\"soapenc:Array\">";
   $$XMLtypes.="<xsd:attribute ".
               "ref=\"soapenc:arrayType\" arrayType=\"xsd:string[]\"/>";
   $$XMLtypes.="</xsd:restriction>";
   $$XMLtypes.="</xsd:complexContent>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="\n";


   $$XMLtypes.="<xsd:complexType name=\"ArrayOfStringItems\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"unbounded\" ".
               "name=\"item\" type=\"xsd:string\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="\n";

   $$XMLtypes.="<xsd:complexType name=\"SubListRecordArray\">"; # dummy type
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="\n";


   $$XMLtypes.="<xsd:complexType name=\"CItem\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"name\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"value\" type=\"xsd:string\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="\n";

   $$XMLtypes.="<xsd:complexType name=\"Container\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"unbounded\" ".
               "name=\"item\" type=\"$ns:CItem\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="\n";

   $$XMLtypes.="<xsd:complexType name=\"Contacts\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"unbounded\" ".
               "name=\"item\" type=\"$ns:ContactLnk\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="\n";

   $$XMLtypes.="<xsd:complexType name=\"ContactLnk\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"roles\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"targetname\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"target\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"targetid\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"nativroles\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"comments\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"id\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"mdate\" type=\"xsd:dateTime\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="\n";

   $self->WSDLdoPing($uri,$ns,$fp,$module,
                     $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);
   $self->WSDLshowFields($uri,$ns,$fp,$module,
                         $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);
   $self->WSDLfindRecord($uri,$ns,$fp,$module,
                         $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);
   $self->WSDLfindRecordRecord($uri,$ns,$fp,$module,
                         $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);
   $self->WSDLfindRecordFilter($uri,$ns,$fp,$module,
                         $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);
   $self->WSDLstoreRecord($uri,$ns,$fp,$module,
                         $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);
   $self->WSDLdeleteRecord($uri,$ns,$fp,$module,
                         $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);

}

sub WSDLsimple
{
   my $self=shift;
   my $fp=shift;
   my $ns=shift;
   my $func=shift;
   my $soapaction=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;
   my %param=@_;

   $$XMLbinding.="<operation name=\"$func\">";
   $$XMLbinding.="<SOAP:operation ".
                "soapAction=\"http://w5base.net/mod/${fp}".
                "#$soapaction\" style=\"document\" />";
   $$XMLbinding.="<input><SOAP:body use=\"literal\" /></input>";
   $$XMLbinding.="<output><SOAP:body use=\"literal\" /></output>";
   $$XMLbinding.="</operation>";


   $$XMLportType.="<operation name=\"$func\">";
   $$XMLportType.="<input message=\"${ns}:${func}InpParameter\" />";
   $$XMLportType.="<output message=\"${ns}:${func}OutParameter\" />";
   $$XMLportType.="</operation>";

   $$XMLmessage.="<message name=\"${func}InpParameter\">";
   $$XMLmessage.="<part name=\"parameters\" ".
                 "element=\"${ns}:${func}\" />";
   $$XMLmessage.="</message>";
   $$XMLmessage.="<message name=\"${func}OutParameter\">";
   $$XMLmessage.="<part name=\"parameters\" ".
                 "element=\"${ns}:${func}Response\" />";
   $$XMLmessage.="</message>";

   $$XMLtypes.="<xsd:element name=\"${func}\">";
   $$XMLtypes.="<xsd:complexType>";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"input\" ".
              "type=\"${ns}:${func}Input\" />";
              "minOccurs=\"1\" maxOccurs=\"1\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="</xsd:element>";

   $$XMLtypes.="<xsd:element name=\"${func}Response\">";
   $$XMLtypes.="<xsd:complexType>";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"output\" ".
              "type=\"${ns}:${func}Output\" />";
              "minOccurs=\"1\" maxOccurs=\"1\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="</xsd:element>";

   $$XMLtypes.="<xsd:complexType name=\"${func}Output\">";
   $$XMLtypes.="<xsd:sequence>";
   my @l=@{$param{'out'}};
   while(my $varname=shift(@l)){
      my $p=shift(@l);
      if (ref($p) eq "HASH"){
         $$XMLtypes.="<xsd:element name=\"$varname\"";
         foreach my $k (keys(%$p)){
            $$XMLtypes.=" $k=\"$p->{$k}\"";
         }
         $$XMLtypes.=" />";
      }
   }
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

   $$XMLtypes.="<xsd:complexType name=\"${func}Input\">";
   $$XMLtypes.="<xsd:sequence>";
   my $subbuffer;
   my @l=@{$param{'in'}};
   while(my $varname=shift(@l)){
      my $p=shift(@l);
      if (ref($p) eq "HASH"){
         if (exists($p->{default})){
            $varname="___STORE_TAG_AT_${varname}_$p->{default}_PARAM___";
            delete($p->{default});
         }
         $$XMLtypes.="<xsd:element name=\"$varname\"";
         foreach my $k (keys(%$p)){
            $$XMLtypes.=" $k=\"$p->{$k}\"";
         }
         $$XMLtypes.=" />";
      }
      if (ref($p) eq "ARRAY"){
         my $usevarname=$varname;
         $usevarname=~s/(^[a-z])/uc($1)/e;
         $$XMLtypes.="<xsd:element name=\"${varname}\" ".
                    "type=\"${ns}:${func}${usevarname}\" />";
                    "minOccurs=\"1\" maxOccurs=\"1\" />";
         $subbuffer.="<xsd:complexType name=\"${func}${usevarname}\">";
         $subbuffer.="<xsd:sequence>";
         my @subl=@$p;
         while(my $subvarname=shift(@subl)){
            my $subp=shift(@subl);
            if (exists($subp->{default})){
               $varname="___STORE_TAG_AT_${varname}_$subp->{default}_PARAM___";
               delete($subp->{default});
            }
            $subbuffer.="<xsd:element name=\"$subvarname\"";
            foreach my $subk (keys(%$subp)){
               $subbuffer.=" $subk=\"$subp->{$subk}\"";
            }
            $subbuffer.=" />";
         }
         $subbuffer.="</xsd:sequence>";
         $subbuffer.="</xsd:complexType>";
      }
   }
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>".$subbuffer;
}

sub WSDLdoPing
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $module=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;

   $$XMLbinding.="<!-- doPing() checks the connection to the w5base object ".
                 " --> ";
   $self->WSDLsimple($fp,$ns,"doPing","doPing",
                     $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes,
                     in =>[
                            lang            =>{type=>'xsd:string',
                                               minOccurs=>'1',
                                               maxOccurs=>'1',
                                               nillable=>'true'},
                            action          =>{type=>'xsd:string',
                                               minOccurs=>'1',
                                               maxOccurs=>'1',
                                               default=>'ActionCheck',
                                               nillable=>'true'}
                          ],
                     out=>[
                            userid          =>{type=>'xsd:integer',
                                               minOccurs=>'0',
                                               maxOccurs=>'1' },
                            exitcode        =>{type=>'xsd:int',
                                               minOccurs=>'1',
                                               maxOccurs=>'1' },
                            result          =>{type=>'xsd:int',
                                               minOccurs=>'1',
                                               maxOccurs=>'1' }
                     ]);
}

sub WSDLshowFields
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $module=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;

   $$XMLbinding.="<!-- showFields() gives you access to the field definitions ".
                 "of the dataobject -->";
   $$XMLbinding.="<operation name=\"showFields\">";
   $$XMLbinding.="<SOAP:operation ".
                "soapAction=\"http://w5base.net/mod/${fp}".
                "#showFields\" style=\"document\" />";
   $$XMLbinding.="<input><SOAP:body use=\"literal\" /></input>";
   $$XMLbinding.="<output><SOAP:body use=\"literal\" /></output>";
   $$XMLbinding.="</operation>";


   $$XMLportType.="<operation name=\"showFields\">";
   $$XMLportType.="<input message=\"${ns}:showFieldsInpParameter\" />";
   $$XMLportType.="<output message=\"${ns}:showFieldsOutParameter\" />";
   $$XMLportType.="</operation>";

   $$XMLmessage.="<message name=\"showFieldsInpParameter\">";
   $$XMLmessage.="<part name=\"parameters\" ".
                 "element=\"${ns}:showFields\" />";
   $$XMLmessage.="</message>";
   $$XMLmessage.="<message name=\"showFieldsOutParameter\">";
   $$XMLmessage.="<part name=\"parameters\" ".
                 "element=\"${ns}:showFieldsResponse\" />";
   $$XMLmessage.="</message>";

   $$XMLtypes.="<xsd:element name=\"showFields\">";
   $$XMLtypes.="<xsd:complexType>";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"input\" ".
              "type=\"${ns}:showFieldsInp\" />";
              "minOccurs=\"1\" maxOccurs=\"1\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="</xsd:element>";

   $$XMLtypes.="<xsd:element name=\"showFieldsResponse\">";
   $$XMLtypes.="<xsd:complexType>";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"output\" ".
              "type=\"${ns}:showFieldsOut\" />";
              "minOccurs=\"1\" maxOccurs=\"1\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="</xsd:element>";

   $$XMLtypes.="<xsd:complexType name=\"showFieldsOut\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element minOccurs=\"1\" maxOccurs=\"1\" ".
              "name=\"exitcode\" type=\"xsd:int\" />";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
              "name=\"lastmsg\" type=\"${ns}:ArrayOfStringItems\" />";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
              "name=\"records\" type=\"${ns}:FieldList\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

   $$XMLtypes.="<xsd:complexType name=\"FieldList\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"unbounded\" ".
               "name=\"item\" type=\"${ns}:Field\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

   $$XMLtypes.="<xsd:complexType name=\"Field\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"type\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"longtype\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"name\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"is_vjoin\" type=\"xsd:string\" />";
   $$XMLtypes.="<xsd:element name=\"group\" type=\"${ns}:ArrayOfString\" />";
   $$XMLtypes.="<xsd:element name=\"primarykey\" ".
               "minOccurs=\"0\" maxOccurs=\"1\" type=\"xsd:int\"  />";
   $$XMLtypes.="<xsd:element name=\"sourceobj\" ".
               "minOccurs=\"0\" maxOccurs=\"1\" type=\"xsd:string\"  />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

   $$XMLtypes.="<xsd:complexType name=\"showFieldsInp\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"lang\" ".
              "type=\"xsd:string\" nillable=\"true\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
}




sub WSDLstoreRecord
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $module=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;
   my @flist;

   my $recordname="StoreableRec";
   if ($o->Self() eq "base::workflow"){
      $recordname="WfRec";
   }

   $$XMLbinding.="<!-- the storeRecord() method allows to access all data -->";
   $$XMLbinding.="<operation name=\"storeRecord\">";
   $$XMLbinding.="<SOAP:operation ".
                "soapAction=\"http://w5base.net/mod/${fp}".
                "#storeRecord\" style=\"document\" />";
   $$XMLbinding.="<input><SOAP:body use=\"literal\" /></input>";
   $$XMLbinding.="<output><SOAP:body use=\"literal\" /></output>";
   $$XMLbinding.="</operation>";


   $$XMLportType.="<operation name=\"storeRecord\">";
   $$XMLportType.="<input message=\"${ns}:storeRecordInpParameter\" />";
   $$XMLportType.="<output message=\"${ns}:storeRecordOutParameter\" />";
   $$XMLportType.="</operation>";

   $$XMLmessage.="<message name=\"storeRecordInpParameter\">";
   $$XMLmessage.="<part name=\"parameters\" ".
                 "element=\"${ns}:storeRecord\" />";
   $$XMLmessage.="</message>";

   $$XMLmessage.="<message name=\"storeRecordOutParameter\">";
   $$XMLmessage.="<part name=\"parameters\" ".
                 "element=\"${ns}:storeRecordResponse\" />";
   $$XMLmessage.="</message>";

   $$XMLtypes.="<xsd:element name=\"storeRecord\">";
   $$XMLtypes.="<xsd:complexType>";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"input\" ".
              "type=\"${ns}:storeRecInp\" />";
              "minOccurs=\"1\" maxOccurs=\"1\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="</xsd:element>";

   $$XMLtypes.="<xsd:complexType name=\"storeRecInp\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"lang\" ".
               "type=\"xsd:string\" nillable=\"true\" />";
   $$XMLtypes.="<xsd:element name=\"IdentifiedBy\" ".
               "minOccurs=\"0\" maxOccurs=\"1\" ".
               "type=\"xsd:integer\" nillable=\"true\" />";
   $$XMLtypes.="<xsd:element name=\"data\" ".
              "type=\"${ns}:$recordname\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

   $$XMLtypes.="<xsd:element name=\"storeRecordResponse\">";
   $$XMLtypes.="<xsd:complexType>";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"output\" ".
              "type=\"${ns}:storeRecOut\" />";
              "minOccurs=\"1\" maxOccurs=\"1\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="</xsd:element>";

   $$XMLtypes.="<xsd:complexType name=\"storeRecOut\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element minOccurs=\"1\" maxOccurs=\"1\" ".
              "name=\"exitcode\" type=\"xsd:int\" />";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
              "name=\"IdentifiedBy\" type=\"xsd:integer\" />";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
              "name=\"lastmsg\" type=\"${ns}:ArrayOfStringItems\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

   $$XMLtypes.="<xsd:complexType name=\"$recordname\">";
   $$XMLtypes.="<xsd:sequence>";
   $self->WSDLfieldList($uri,$ns,$fp,$module,"store",
                         $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
}

sub WSDLdeleteRecord
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $module=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;
   my @flist;


   $$XMLbinding.="<!-- the deleteRecord() method delete a record -->";
   $$XMLbinding.="<operation name=\"deleteRecord\">";
   $$XMLbinding.="<SOAP:operation ".
                "soapAction=\"http://w5base.net/mod/${fp}".
                "#deleteRecord\" style=\"document\" />";
   $$XMLbinding.="<input><SOAP:body use=\"literal\" /></input>";
   $$XMLbinding.="<output><SOAP:body use=\"literal\" /></output>";
   $$XMLbinding.="</operation>";


   $$XMLportType.="<operation name=\"deleteRecord\">";
   $$XMLportType.="<input message=\"${ns}:deleteRecordInpParameter\" />";
   $$XMLportType.="<output message=\"${ns}:deleteRecordOutParameter\" />";
   $$XMLportType.="</operation>";

   $$XMLmessage.="<message name=\"deleteRecordInpParameter\">";
   $$XMLmessage.="<part name=\"parameters\" ".
                 "element=\"${ns}:deleteRecord\" />";
   $$XMLmessage.="</message>";

   $$XMLmessage.="<message name=\"deleteRecordOutParameter\">";
   $$XMLmessage.="<part name=\"parameters\" ".
                 "element=\"${ns}:deleteRecordResponse\" />";
   $$XMLmessage.="</message>";

   $$XMLtypes.="<xsd:element name=\"deleteRecord\">";
   $$XMLtypes.="<xsd:complexType>";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"input\" ".
              "type=\"${ns}:deleteRecInp\" />";
              "minOccurs=\"1\" maxOccurs=\"1\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="</xsd:element>";

   $$XMLtypes.="<xsd:complexType name=\"deleteRecInp\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"lang\" ".
              "type=\"xsd:string\" nillable=\"true\" />";
   $$XMLtypes.="<xsd:element name=\"IdentifiedBy\" ".
              "type=\"xsd:integer\" nillable=\"true\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

   $$XMLtypes.="<xsd:element name=\"deleteRecordResponse\">";
   $$XMLtypes.="<xsd:complexType>";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"output\" ".
              "type=\"${ns}:deleteRecOut\" />";
              "minOccurs=\"1\" maxOccurs=\"1\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="</xsd:element>";

   $$XMLtypes.="<xsd:complexType name=\"deleteRecOut\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element minOccurs=\"1\" maxOccurs=\"1\" ".
              "name=\"exitcode\" type=\"xsd:int\" />";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
              "name=\"IdentifiedBy\" type=\"xsd:integer\" />";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
              "name=\"lastmsg\" type=\"${ns}:ArrayOfStringItems\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

}

sub WSDLaddNativFieldList
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $module=shift;
   my $mode=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;

}

sub WSDLfieldList
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $module=shift;
   my $mode=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;
   my @flist;
   if ($o->can("getFieldObjsByView")){
      @flist=$o->getFieldObjsByView(["ALL"],class=>$module);
   }
   if ($mode eq "filter" || $mode eq "result" || $mode eq "store"){
      foreach my $fobj (@flist){
         my $type=$fobj->WSDLfieldType($ns,$mode);
         next if (!defined($type));
         next if ($fobj->Type() ne "Id" && $fobj->readonly && $mode eq "store");
         next if ($fobj->Type() eq "Linenumber" && 
                  ($mode eq "store" || $mode eq "filter"));
         next if ($mode eq "filter" && !($fobj->searchable()) &&
                  $fobj->Type() ne "Interface");
        # next if ($fobj->Type() eq "Link" && 
        #          ($mode eq "result" || $mode eq "store"));
         my $minOccurs="0";
         my $label=$fobj->Label();
         $label=~s/&/&amp;/g;
         my $name=$fobj->Name();
         next if ($name eq "");
         $$XMLtypes.="<xsd:element minOccurs=\"$minOccurs\" ".
                     "maxOccurs=\"1\" name=\"$name\" type=\"$type\">";
         $$XMLtypes.="<xsd:annotation>";
         $$XMLtypes.="<xsd:documentation>";
         $$XMLtypes.=$label;
         $$XMLtypes.="</xsd:documentation>";
         $$XMLtypes.="</xsd:annotation>";
         $$XMLtypes.="</xsd:element>";
      }
   }
   $self->WSDLaddNativFieldList($uri,$ns,$fp,$module,$mode,
                         $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);
}



sub WSDLfindRecord
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $module=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;

   $$XMLbinding.="<!-- the findRecord() method allows to access all data -->";
   $$XMLbinding.="<operation name=\"findRecord\">";
   $$XMLbinding.="<SOAP:operation ".
                "soapAction=\"http://w5base.net/mod/${fp}".
                "#findRecord\" style=\"document\" />";
   $$XMLbinding.="<input><SOAP:body use=\"literal\" /></input>";
   $$XMLbinding.="<output><SOAP:body use=\"literal\" /></output>";
   $$XMLbinding.="</operation>";


   $$XMLportType.="<operation name=\"findRecord\">";
   $$XMLportType.="<input message=\"${ns}:findRecordInpParameter\" />";
   $$XMLportType.="<output message=\"${ns}:findRecordOutParameter\" />";
   $$XMLportType.="</operation>";

   $$XMLmessage.="<message name=\"findRecordInpParameter\">";
   $$XMLmessage.="<part name=\"parameters\" ".
                 "element=\"${ns}:findRecord\" />";
   $$XMLmessage.="</message>";
   $$XMLmessage.="<message name=\"findRecordOutParameter\">";
   $$XMLmessage.="<part name=\"parameters\" ".
                 "element=\"${ns}:findRecordResponse\" />";
   $$XMLmessage.="</message>";

   $$XMLtypes.="<xsd:element name=\"findRecord\">";
   $$XMLtypes.="<xsd:complexType>";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"input\" ".
              "type=\"${ns}:findRecordInp\" />";
              "minOccurs=\"1\" maxOccurs=\"1\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="</xsd:element>";

   $$XMLtypes.="<xsd:element name=\"findRecordResponse\">";
   $$XMLtypes.="<xsd:complexType>";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"output\" ".
              "type=\"${ns}:findRecordOut\" />";
              "minOccurs=\"1\" maxOccurs=\"1\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";
   $$XMLtypes.="</xsd:element>";

   $$XMLtypes.="<xsd:complexType name=\"findRecordOut\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
              "name=\"lastmsg\" type=\"${ns}:ArrayOfStringItems\" />";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"1\" ".
              "name=\"records\" type=\"${ns}:RecordList\" />";
   $$XMLtypes.="<xsd:element minOccurs=\"1\" maxOccurs=\"1\" ".
              "name=\"exitcode\" type=\"xsd:int\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

   $$XMLtypes.="<xsd:complexType name=\"RecordList\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element minOccurs=\"0\" maxOccurs=\"unbounded\" ".
               "name=\"record\" type=\"${ns}:Record\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

   $$XMLtypes.="<xsd:complexType name=\"findRecordInp\">";
   $$XMLtypes.="<xsd:sequence>";
   $$XMLtypes.="<xsd:element name=\"lang\" ".
              "type=\"xsd:string\" nillable=\"true\" />";
   $$XMLtypes.="<xsd:element name=\"view\" ".
              "type=\"xsd:string\" nillable=\"true\" />";
   $$XMLtypes.="<xsd:element name=\"limit\" ".
              "type=\"xsd:integer\" minOccurs=\"0\" nillable=\"true\" />";
   $$XMLtypes.="<xsd:element name=\"limitstart\" ".
              "type=\"xsd:integer\" minOccurs=\"0\" nillable=\"true\" />";
   $$XMLtypes.="<xsd:element name=\"filter\" ".
              "type=\"${ns}:Filter\" />";
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

}

sub WSDLfindRecordRecord
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $module=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;

   $$XMLtypes.="<xsd:complexType name=\"Record\">";
   $$XMLtypes.="<xsd:sequence>";
   $self->WSDLfieldList($uri,$ns,$fp,$module,"result",
                         $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";

}

sub WSDLfindRecordFilter
{
   my $self=shift;
   my $o=$self;
   my $uri=shift;
   my $ns=shift;
   my $fp=shift;
   my $module=shift;
   my $XMLbinding=shift;
   my $XMLportType=shift;
   my $XMLmessage=shift;
   my $XMLtypes=shift;

   $$XMLtypes.="<xsd:complexType name=\"Filter\">";
   $$XMLtypes.="<xsd:sequence>";
   $self->WSDLfieldList($uri,$ns,$fp,$module,"filter",
                         $XMLbinding,$XMLportType,$XMLmessage,$XMLtypes);
   $$XMLtypes.="</xsd:sequence>";
   $$XMLtypes.="</xsd:complexType>";


}




1;
