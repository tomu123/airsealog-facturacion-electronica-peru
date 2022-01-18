tableextension 51203 "EB G/L Entry" extends 17
{
    fields
    {
        // Add changes to table fields here

        field(51050; "EB No. Invoice Advanced"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'No. factura anticipo', Comment = 'ESM="No. factura anticipo"';
        }
    }

    var
        myInt: Integer;
}