pageextension 51096 "EB Item Card" extends "Item Card"
{
    layout
    {
        // Add changes to page layout here
        addafter(FirstField)
        {
            field("EB Legal Item Code"; "EB Legal Item Code")
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