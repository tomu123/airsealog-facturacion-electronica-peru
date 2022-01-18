pageextension 51207 "EB Posted Sales Inv. Subform" extends "Posted Sales Invoice Subform"
{
    layout
    {
        // Add changes to page layout here
        addafter("Line Discount %")
        {
            field("EB Motive discount code"; "EB Motive discount code")
            {
                ApplicationArea = All;
            }
            field("Amount Advanced"; "Amount Advanced")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}