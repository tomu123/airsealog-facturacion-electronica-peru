pageextension 51209 "EB Posted Sales Invoices" extends "Posted Sales Invoices"
{
    layout
    {
        addafter("Remaining Amount")
        {
            field("Total Applied. Advance"; "Total Applied. Advance")
            {
                ApplicationArea = All;
            }
        }
    }
    actions
    {
        // Add changes to page actions here
        addafter(IncomingDoc)
        {
            action(electronicInvoice)
            {
                ApplicationArea = All;
                Caption = 'Electronic Invoice', Comment = 'ESM="Factura Electrónica"';
                Image = ElectronicDoc;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = "Repeater";
                RunObject = page "EB Electronic Bill Entries";
                RunPageLink = "EB Document No." = field("No."), "EB Document Type" = const(Invoice);
            }
        }
    }

    procedure SetParameters(var pCodeAdvance: Code[20])
    var

    begin
        gShowAdvance := TRUE;
        pCodeAdvance := "No.";
    end;

    var
        myInt: Integer;
        gShowAdvance: Boolean;
}