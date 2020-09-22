pageextension 51175 "EB Posted Sales Invoice" extends "Posted Sales Invoice"
{
    layout
    {
        // Add changes to page layout here

        addafter("External Document No.")
        {
            field("EB Electronic Bill"; "EB Electronic Bill")
            {
                ApplicationArea = All;
                Caption = 'Electronic Bill', Comment = 'ESM="Factura electrónica"';

            }
        }
    }
}