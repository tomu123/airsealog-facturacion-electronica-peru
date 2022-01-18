pageextension 51049 "EB VAT Posting Setup Card" extends "VAT Posting Setup Card"
{
    layout
    {
        // Add changes to page layout here
        addafter(General)
        {
            group(Localization)
            {
                Caption = 'Peruvian Localization', Comment = 'ESM="Localización peruana"';
                field("EB VAT Type Affectation"; "EB VAT Type Affectation")
                {
                    ApplicationArea = All;
                }
                field("EB Tax Type Code"; "EB Tax Type Code")
                {
                    ApplicationArea = All;
                }
                field("EB Others Tax Concepts"; "EB Others Tax Concepts")
                {
                    ApplicationArea = All;
                }
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