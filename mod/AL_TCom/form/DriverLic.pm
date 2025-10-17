package AL_TCom::form::DriverLic;
use strict;
use vars qw(@ISA);
use kernel;
use kernel::Form;
@ISA=qw(kernel::Form);

sub new
{
   my $type=shift;
   my %param=@_;
   my $self=bless($type->SUPER::new(%param),$type);
   $self->{url}="http://detefleetservices.telekom.de/coremedia/generator/DTFS/property=blobBinary/id=51534.pdf";

   return($self);
}

sub AddFrontendFields
{
   my $self=shift;
   $self->getParent->AddFrontendFields(
      new kernel::Field::Text(
                name          =>'team',
                label         =>'Einsatzresort'),
      new kernel::Field::Text(
                name          =>'fullname',
                label         =>'Antragsteller'),
      new kernel::Field::Text(
                name          =>'DriverLic_office_persnum',
                label         =>'Personalnummer'),
      new kernel::Field::Text(
                name          =>'office_phone',
                label         =>'Telefonnummer'),
      new kernel::Field::Text(
                name          =>'office_facsimile',
                label         =>'Fax'),
      new kernel::Field::Select(
                name          =>'DriverLic_class',
                value         =>['B/BE (3)'],
                label         =>'Kraftfahrzeugklasse'),
      new kernel::Field::Text(
                name          =>'DriverLic_licno',
                label         =>'Führerscheinnummer'),
      new kernel::Field::Text(
                name          =>'DriverLic_licdate',
                label         =>'Führerschein Ausstellungsdatum'),
      new kernel::Field::Text(
                name          =>'DriverLic_licorg',
                label         =>'Führerschein ausgestellt durch'),
      new kernel::Field::Text(
                name          =>'DriverLic_licrest',
                label         =>'Führerschein Auflagen'),
   ); 
}

sub Validate
{
   my $self=shift;
   my $f=shift;
   foreach my $v (qw(DriverLic_office_persnum DriverLic_licno 
                     fullname DriverLic_licorg )){
      if (length($f->{$v})<3){
         my $l=$self->getParent->{FrontendField}->{$v};
         $self->getParent->LastMsg(ERROR,
                                   "missing necessary '\%s' informations",
                                   $l->Label());
         return(0);
      }
   }
   return(1);
}


sub Fill
{
   my $self=shift;
   my $form=shift;
   my $page=shift;

   my $p=$self->getParent();
   my $date=$p->ExpandTimeExpression("now","deday",undef,"CET");


   if ($page==1){
      prFontSize(10);
      prAreaText(162,655,380,18,0,$form->{team});
      prAreaText(205,630,120,18,0,$form->{office_phone});
      prAreaText(370,630,120,18,0,$form->{office_facsimile});
      prAreaText(162,550,380,18,0,$form->{fullname});
      prAreaText(162,500,380,18,0,$form->{DriverLic_office_persnum});
      prAreaText(295,452,120,18,0,$form->{DriverLic_class});
      prAreaText(162,430,120,18,0,"");
      prAreaText(170,350,380,18,1,$form->{DriverLic_licrest});
      prAreaText(420,286,120,18,0,$form->{DriverLic_licno});
      prAreaText(250,251,350,18,0,$form->{DriverLic_licorg}.
                                  " am ".$form->{DriverLic_licdate});

      prAreaText(365,135,120,18,0,$date);
      prFontSize(8);
      prAreaText(201,113,120,15,0,"Leiter");
      prAreaText(365,113,120,15,0,"Datum");
   }
   if ($page==2){
      prFontSize(8);
      prAreaText(162,568,380,15,0,$form->{fullname}.", ".$date);
      prAreaText(162,458,380,50,0,"");
   }
}




1;
