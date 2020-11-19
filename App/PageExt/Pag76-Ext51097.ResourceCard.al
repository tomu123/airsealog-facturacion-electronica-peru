pageextension 51097 "EB Resource Card" extends "Resource Card"
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
}