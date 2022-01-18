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
            }
            field("EB Tax Type Code"; "EB Tax Type Code")
            {
                ApplicationArea = All;
            }
            field("EB Others Tax Concepts"; "EB Others Tax Concepts")
            {
                ApplicationArea = All;
            }
            field("EB Type Value Sales"; "EB Type Value Sales")
            {
                ApplicationArea = All;
            }
        }
    }
}