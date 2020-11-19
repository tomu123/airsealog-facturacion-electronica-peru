tableextension 51202 "EB Sales Shipment Line" extends 111
{
    fields
    {
        // Add changes to table fields here
        field(51000; "EB No. Invoice Advanced"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'No. Invoice Advanced', Comment = 'ESM="No. factura anticipo"';
            TableRelation = "Sales Invoice Header" where("Invoice Payment Advanced" = const(true), "Bill-to Customer No." = field("Bill-to Customer No."));
        }
    }

    var
        myInt: Integer;
}