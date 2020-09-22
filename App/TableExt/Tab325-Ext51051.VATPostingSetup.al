tableextension 51051 "EB VAT Posting Setup" extends "VAT Posting Setup"
{
    fields
    {
        // Add changes to table fields here 51002..51005
        field(51002; "EB VAT Type Affectation"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'VAT Type Affectation';
            TableRelation = "Legal Document"."Legal No." where("Option Type" = const("Catalogue SUNAT"), "Type Code" = const('07'));
            ValidateTableRelation = false;
        }
        field(51003; "EB Tax Type Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Tax type code';
            TableRelation = "Legal Document"."Legal No." where("Option Type" = const("Catalogue SUNAT"), "Type Code" = const('05'));
            ValidateTableRelation = false;
        }
        field(51004; "EB Others Tax Concepts"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Others Tax Concepts';
            TableRelation = "Legal Document"."Legal No." where("Option Type" = const("Catalogue SUNAT"), "Type Code" = const('14'));
            ValidateTableRelation = false;
        }
    }
}