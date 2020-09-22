pageextension 51098 "EB Fixed Asset Card" extends "Fixed Asset Card"
{
    layout
    {
        // Add changes to page layout here
        addafter(FirstField)
        {
            field("EB Legal Item Code"; "EB Legal Item Code")
            {
                ApplicationArea = All;
                Caption = 'Legal Item Code', comment = 'ESM="Código Producto Legal"';
            }
        }
    }
}