pageextension 51108 "EB Bank Account Card" extends "Bank Account Card"
{
    layout
    {
        // Add changes to page layout here
        addafter(FirstField)
        {
            field("EB Show Electronic Bill"; "EB Show Electronic Bill")
            {
                ApplicationArea = All;
                Visible = ViewEBSender;
            }
        }
    }

    trigger OnOpenPage()
    begin
        EBSetup.Get();
        ViewEBSender := EBSetup."EB Electronic Sender";
    end;

    var
        EBSetup: Record "EB Electronic Bill Setup";
        ViewEBSender: Boolean;
}