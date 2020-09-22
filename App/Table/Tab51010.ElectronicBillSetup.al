table 51010 "EB Electronic Bill Setup"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(51000; "EB Primary Key"; Code[10])
        {
            Caption = 'Primary Key', Comment = 'ESM="Clave primaria"';

        }
        field(51001; "EB URI Service"; Text[100])
        {
            Caption = 'URI Billing Service';
        }
        field(51002; "EB Detraction Code"; Code[20])
        {
            Caption = 'Detraction Code';
            TableRelation = "Legal Document"."Legal No." where("Option Type" = const("Catalogue SUNAT"), "Type Code" = const('14'));
            ValidateTableRelation = false;
        }
        field(51003; "EB Detrac. Goods/Services Code"; Code[20])
        {
            Caption = 'Detrac. Goods/Services Code';
            TableRelation = "Legal Document"."Legal No." where("Option Type" = const("Catalogue SUNAT"), "Type Code" = const('15'));
            ValidateTableRelation = false;
        }
        field(51004; "EB Detrac. National Bank Code"; Code[20])
        {
            Caption = 'Detrac. National Bank Code';
            TableRelation = "Legal Document"."Legal No." where("Option Type" = const("Catalogue SUNAT"), "Type Code" = const('15'));
            ValidateTableRelation = false;
        }
        field(51005; "EB National Bank Account No."; Code[25])
        {
            Caption = 'National Bank Account No.';
        }
        field(51006; "EB TAX Code"; Code[20])
        {
            Caption = 'TAX Code';
            TableRelation = "Legal Document"."Legal No." where("Option Type" = const("Catalogue SUNAT"), "Type Code" = const('05'));
            ValidateTableRelation = false;
        }
        field(51007; "EB ISC Code"; Code[20])
        {
            Caption = 'ISC Code';
            TableRelation = "Legal Document"."Legal No." where("Option Type" = const("Catalogue SUNAT"), "Type Code" = const('05'));
            ValidateTableRelation = false;
        }
        field(51008; "EB Charge/Dsct Detailed Code"; Code[22])
        {
            Caption = 'Charge/Dsct Detailed Code';
            TableRelation = "Legal Document"."Legal No." where("Option Type" = const("Catalogue SUNAT"), "Type Code" = const('53'), "Applied Level" = const(Line));
            ValidateTableRelation = false;
        }
        field(51009; "EB Electronic Sender"; Boolean)
        {
            Caption = 'Electronic Sender';
        }
        field(51010; "EB Company Name"; Text[30])
        {
            Caption = 'Company Name';
            TableRelation = Company.Name;
        }
        field(51011; "EB Unit of Measure"; Code[25])
        {
            Caption = 'Unit of Measure';
            TableRelation = "Unit of Measure";
        }
        field(51012; "EB Get QR"; Text[100])
        {
            Caption = 'Get Files';
        }
        field(51013; "EB Charge G/L Account"; Code[20])
        {
            Caption = 'Charge G/L Account';
            TableRelation = "G/L Account"."No." WHERE("Account Type" = CONST(Posting));
        }
        field(51014; "EB Discount G/L Account"; Code[20])
        {
            Caption = 'Discount G/L Account';
            TableRelation = "G/L Account"."No." WHERE("Account Type" = CONST(Posting));
        }
        field(51015; "EB Invoice"; Text[200])
        {
            Caption = 'Invoice';
        }
        field(51016; "EB Ticket"; Text[200])
        {
            Caption = 'Ticket';
        }
        field(51017; "EB Credit Note"; Text[200])
        {
            Caption = 'Credit Note';
        }
        field(51018; "EB Debit Note"; Text[200])
        {
            Caption = 'Debit Note';
        }
        field(51019; "EB Retention"; Text[200])
        {
            Caption = 'Retention';
        }
        field(51020; "EB Voided Document"; Text[200])
        {
            Caption = 'Voided Document';
        }
        field(51021; "EB Summary Documents"; Text[200])
        {
            Caption = 'Summary Documents';
        }
        field(51022; "EB Get PDF"; Text[200])
        {
            Caption = 'Get PDF';
        }
        field(51023; "EB Get Ticket Status"; Text[200])
        {
            Caption = 'Get Ticket Status';
        }
        field(51024; "EB Validate Summary Document"; Text[200])
        {
            Caption = 'Validate Summary Document';
        }
        field(51025; "EB Elec. Bill Resolution No."; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Elec. Bill Resolution No.';
        }
    }

    keys
    {
        key(PK; "EB Primary Key")
        {
            Clustered = true;
        }
    }

    var
        myInt: Integer;

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

}