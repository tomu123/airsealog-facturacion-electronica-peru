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
            }
        }
        modify(SellToEmail){
            ApplicationArea = All;
            Visible = true;
            Editable = true;
        }
    }

    actions
    {
        addafter(IncomingDocument)
        {
            action(electronicInvoice)
            {
                ApplicationArea = All;
                Caption = 'Electronic Invoice', Comment = 'ESM="Factura Electrónica"';
                Image = ElectronicDoc;
                RunObject = page "EB Electronic Bill Entries";
                RunPageLink = "EB Document No." = field("No."), "EB Document Type" = const(Invoice);
            }
        }
    }
}
