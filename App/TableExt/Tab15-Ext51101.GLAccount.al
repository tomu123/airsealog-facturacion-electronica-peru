tableextension 51101 "EB G/L Account" extends "G/L Account"
{
    fields
    {
        // Add changes to table fields here 51001..51001
        field(51001; "EB Legal Item Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Legal Item Code';
            TableRelation = "Legal Document"."Legal No." where("Option Type" = const(Others), "Type Code" = const('ITEM CODE'));
            ValidateTableRelation = false;
        }
    }

    var
        ItemNo: Record "Legal Document";
}