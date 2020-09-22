tableextension 51072 "EB No Series" extends "No. Series"
{
    fields
    {
        // Add changes to table fields here
        field(51004; "EB Electronic Bill"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Electronic Bill';
        }
    }

    var
        myInt: Integer;
}