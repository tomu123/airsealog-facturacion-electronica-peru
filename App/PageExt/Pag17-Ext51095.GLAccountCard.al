pageextension 51095 "EB G/L Account Card" extends "G/L Account Card"
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