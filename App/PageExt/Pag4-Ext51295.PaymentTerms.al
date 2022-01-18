pageextension 51295 "ASL Payment Terms" extends "Payment Terms"
{
    layout
    {
        // Add changes to page layout here
        addafter(Description)
        {
            field("Payment Type"; "Payment Type")
            {
                ApplicationArea = All;
            }
            field("Payment Method Type"; "Payment Method Type")
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