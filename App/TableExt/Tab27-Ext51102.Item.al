tableextension 51102 "EB Item" extends "Item"
{
    fields
    {
        // Add changes to table fields here 51000..51000
        field(51000; "EB Legal Item Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Legal Item Code';
            TableRelation = "Legal Document"."Legal No." where("Option Type" = const(Others), "Type Code" = const('Item Code'));
            ValidateTableRelation = false;
        }
    }
}