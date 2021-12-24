pageextension 51204 "EB Sales invoice subform" extends "Sales Invoice Subform"
{
    layout
    {
        // Add changes to page layout here
        addafter("Line Discount %")
        {
            field("EB Motive discount code"; "EB Motive discount code")
            {
                ApplicationArea = All;
                ShowMandatory = ("Line Discount %" <> 0);
            }
            field("EB No. Invoice Advanced"; "EB No. Invoice Advanced")
            {
                ApplicationArea = All;
            }

        }
        addbefore("VAT Prod. Posting Group")
        {
            field("VAT Bus. Posting Group"; "VAT Bus. Posting Group")
            {
                ApplicationArea = All;
                ShowMandatory = ("Line Discount %" <> 0);
            }
            field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
            {
                ApplicationArea = All;
                ShowMandatory = ("Line Discount %" <> 0);
            }

        }
        modify("Gen. Prod. Posting Group")
        {
            ApplicationArea = All;
            Visible  = true;
            ShowMandatory = ("Line Discount %" <> 0);
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}
