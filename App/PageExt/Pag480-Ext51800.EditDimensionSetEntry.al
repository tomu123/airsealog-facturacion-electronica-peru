pageextension 51800 "ST Edit Dim. Set Entry" extends "Edit Dimension Set Entries"
{
    layout
    {
        // Add changes to page layout here
        addafter("Dimension Code")
        {
            field("Dimension Set ID"; "Dimension Set ID")
            {
                ApplicationArea = All;
                Visible = false;
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