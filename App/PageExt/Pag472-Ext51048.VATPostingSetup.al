pageextension 51048 "EB Posting Setup List" extends "VAT Posting Setup"
{
    layout
    {
        // Add changes to page layout here
        addafter("Tax Category")
        {
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