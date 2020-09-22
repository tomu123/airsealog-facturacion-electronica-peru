pageextension 51049 "EB VAT Posting Setup Card" extends "VAT Posting Setup Card"
{
    layout
    {
        // Add changes to page layout here
        addafter(General)
        {
            group(Localization)
            {
                Caption = 'Peruvian Localization', Comment = 'ESM="Localización Peruana"';
                field("EB VAT Type Affectation"; "EB VAT Type Affectation")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Type Affectation', comment = 'ESM="Tipo Afectación IGV"';
                }
                field("EB Tax Type Code"; "EB Tax Type Code")
                {
                    ApplicationArea = All;
                    Caption = 'Tax Type Code', comment = 'ESM="Código Tipo Tributo"';
                }
                field("EB Others Tax Concepts"; "EB Others Tax Concepts")
                {
                    ApplicationArea = All;
                    Caption = 'Others Tax Concepts', comment = 'ESM="Otros Conceptos Tributarios"';
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