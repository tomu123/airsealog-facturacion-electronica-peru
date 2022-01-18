tableextension 51105 "EB Unit of Measure" extends "Unit of Measure"
{
    fields
    {
        // Add changes to table fields here
        field(51000; "EB Comercial Unit of Measure"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Comercial Unit of Measure';
            TableRelation = "Legal Document"."Legal No." where("Option Type" = const("Catalogue SUNAT"), "Type Code" = const('03'));
            ValidateTableRelation = false;
        }
    }
}