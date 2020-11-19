pageextension 51208 "EB Pstd Sales Cr. Memo Subform" extends "Posted Sales Cr. Memo Subform"
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
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}