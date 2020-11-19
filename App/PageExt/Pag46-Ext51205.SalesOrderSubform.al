pageextension 51205 "EB Sales Order Subform" extends "Sales Order Subform"
{
    layout
    {
        // Add changes to page layout here}
        addafter("Line Discount %")
        {
            field("EB Motive discount code"; "EB Motive discount code")
            {
                ApplicationArea = All;
                ShowMandatory = ("Line Discount %" <> 0);
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