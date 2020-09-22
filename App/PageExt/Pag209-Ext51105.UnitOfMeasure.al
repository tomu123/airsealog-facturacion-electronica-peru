pageextension 51105 "EB Unit of Measure List" extends "Units of Measure"
{
    layout
    {
        // Add changes to page layout here
        addafter("International Standard Code")
        {
            field("EB Comercial Unit of Measure"; "EB Comercial Unit of Measure")
            {
                ApplicationArea = All;
                Caption = 'Comercial Unit of Measure', Comment = 'ESM="Unidad Medida Comercial"';
            }
        }
    }
}