tableextension 51195 "EB Sales Cr. Memo Line" extends "Sales Cr.Memo Line"
{
    fields
    {
        // Add changes to table fields here 51100..51200
        field(51100; "EB Motive discount code"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Motive discount code', Comment = 'ESM="Cód. Motivo descuento"';
        }
        field(51101; "EB No. Invoice Advanced"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'No. Invoice Advanced', Comment = 'ESM="No. factura anticipo"';
            TableRelation = "Sales Invoice Header" where("Invoice Payment Advanced" = const(true), "Bill-to Customer No." = field("Bill-to Customer No."));
        }
    }

    var
        myInt: Integer;
}