tableextension 51194 "EB Sales Invoice Line" extends "Sales Invoice Line"
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
            Caption = 'No. factura anticipo', Comment = 'ESM="No. factura anticipo"';
        }
        field(51102; "Account Advanced"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Cuenta de anticipos', Comment = 'ESM="Cuenta de anticipos"';
        }
        field(51103; "Amount Advanced"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Importe Anticipo', Comment = 'ESM="Importe Anticipo"';
        }
    }

    var
        myInt: Integer;
}