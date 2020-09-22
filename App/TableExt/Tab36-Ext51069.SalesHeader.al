tableextension 51069 "EB Sales Header" extends "Sales Header"
{

    fields
    {
        // Add changes to table fields here
        field(51100; "EB Type Operation Document"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Type Operation Document';
            TableRelation = "Legal Document"."Legal No." where("Option Type" = const("Catalogue SUNAT"), "Type Code" = const('51'));
            ValidateTableRelation = false;
        }
        field(51101; "EB NC/ND Description Type"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'NC/ND Description Type';
            TableRelation = if ("Legal Document" = const('07')) "Legal Document"."Legal No." where("Option Type" = const("Catalogue SUNAT"), "Type Code" = const('09')) else
            if ("Legal Document" = const('08')) "Legal Document"."Legal No." where("Option Type" = const("Catalogue SUNAT"), "Type Code" = const('10'));
        }
        field(51102; "EB NC/ND Support Description"; Text[200])
        {
            DataClassification = ToBeClassified;
            Caption = 'NC/ND Support Description';
        }
        field(51103; "EB TAX Ref. Document Type"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'TAX Ref. Document Type';
            TableRelation = "Legal Document"."Legal No." where("Option Type" = const("Catalogue SUNAT"), "Type Code" = const('12'));
            ValidateTableRelation = false;
        }
        field(51104; "EB Electronic Bill"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Electronic Bill';
        }
        field(51105; "EB Language Invoice"; Option)
        {
            DataClassification = ToBeClassified;
            Caption = 'Language';
            OptionMembers = Spanish,English;
            OptionCaption = 'Spanish,English';
        }
        field(51106; "EB Charge/Discount Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Charge/Discount Code';
            TableRelation = "Legal Document"."Legal No." where("Option Type" = const("Catalogue SUNAT"), "Type Code" = const('53'), "Applied Level" = const(Header));
            ValidateTableRelation = false;
        }
    }

    var
        table36: Record 37;
}