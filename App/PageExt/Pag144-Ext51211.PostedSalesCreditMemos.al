pageextension 51211 "EB Posted Sales Credit Memos" extends "Posted Sales Credit Memos"
{
    layout
    {
        // Add changes to page layout here

        addbefore("Legal Status")
        {
            field("EB Electronic Bill"; "EB Electronic Bill")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        addafter(IncomingDoc)
        {
            action(electronicCreditMemo)
            {
                ApplicationArea = All;
                Caption = 'Electronic Credit Memo', Comment = 'ESM="Nota de Cédito Electrónica"';
                Image = ElectronicDoc;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                Scope = "Repeater";
                RunObject = page "EB Electronic Bill Entries";
                RunPageLink = "EB Document No." = field("No."), "EB Document Type" = const("Credit Memo");
            }
        }
    }
}