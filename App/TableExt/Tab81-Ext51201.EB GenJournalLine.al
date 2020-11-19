tableextension 51201 "EB Gen. Journal Line" extends 81
{
    fields
    {
        // Add changes to table fields here
        field(51062; "EB No. Invoice Advanced"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'No. factura anticipo', Comment = 'ESM="No. factura anticipo"';
        }
    }
    var
        myInt: Integer;
}