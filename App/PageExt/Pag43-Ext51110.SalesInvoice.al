pageextension 51110 "EB Sales Invoice" extends "Sales Invoice"
{
    layout
    {
        // Add changes to page layout here

        modify(LegalPropertyType)
        {
            Visible = false;

        }
        modify("VAT Registration Type")
        {
            Visible = false;
        }

        modify("VAT Registration No.")
        {
            Visible = false;
        }
        modify("Legal Property Type")
        {
            Visible = false;
        }
        addafter("Legal Document")
        {
            field("Posting No. Series"; "Posting No. Series")
            {
                ApplicationArea = All;
                Editable = True;
            }
            field("Posting No."; "Posting No.")
            {
                ApplicationArea = All;
                Editable = True;
            }
        }

        modify("Legal Document")
        {
            trigger OnAfterValidate()
            var

            begin
                if NOT ("Legal Document" IN ['01', '03', '08']) then
                    Error('No es posible elegir este documento');
            end;
        }

        addafter(LegalPropertyType)
        {
            group(EBInformation)
            {
                Editable = ShowElectronicInvoice;
                Visible = ShowElectronicInvoice;
                Caption = 'Electronic Bill', Comment = 'ESM="Facturación Electrónica"';
                field("EB Electronic Bill"; "EB Electronic Bill")
                {
                    ApplicationArea = All;
                }
                field("EB Type Operation Document"; "EB Type Operation Document")
                {
                    ApplicationArea = All;
                    Editable = "EB Electronic Bill";
                }
                field("EB Motive discount code"; "EB Motive discount code")
                {
                    ApplicationArea = All;
                    Editable = "EB Electronic Bill";
                }
                field("EB TAX Ref. Document Type"; "EB TAX Ref. Document Type")
                {
                    ApplicationArea = All;
                    Caption = 'TAX Ref. Document Type';
                    Editable = "EB Electronic Bill";
                }
                field("EB NC/ND Description Type"; "EB NC/ND Description Type")
                {
                    ApplicationArea = All;
                    Caption = 'ND Description Type', Comment = 'ESM="Tipo descripción ND"';
                    Editable = "EB Electronic Bill";
                }
                field("EB NC/ND Support Description"; "EB NC/ND Support Description")
                {
                    ApplicationArea = All;
                    Caption = 'ND Support Description', Comment = 'ESM="Motivo Nota de Dédito"';
                    Editable = "EB Electronic Bill";
                }
                field("Initial Advanced"; "Initial Advanced")
                {
                    ApplicationArea = All;
                    Caption = 'Anticipo Inicial', Comment = 'ESM="Anticipo Inicial"';
                    Editable = "EB Electronic Bill";
                    trigger OnValidate()
                    var
                        myInt: Integer;
                    begin
                        if "Initial Advanced" then
                            "Final Advanced" := false;
                    end;
                }
                field("Total Applied. Advance"; "Total Applied. Advance")
                {
                    ApplicationArea = All;
                    Caption = 'Total Anticipo Aplicado', Comment = 'ESM="Total Anticipo Aplicado"';
                    Editable = "EB Electronic Bill";
                }
                field("Final Advanced"; "Final Advanced")
                {
                    ApplicationArea = All;
                    Caption = 'Anticipo Final', Comment = 'ESM="Anticipo Final"';
                    Editable = "EB Electronic Bill";
                    trigger OnValidate()
                    var
                        myInt: Integer;
                    begin
                        if "Final Advanced" then
                            "Initial Advanced" := false;
                    end;
                }
            }
        }

    }
    actions
    {
        addlast("F&unctions")
        {
            action("Apply Advance")
            {
                Promoted = true;
                PromotedIsBig = true;
                Image = ApplyEntries;
                PromotedCategory = Category4;
                trigger OnAction()
                var
                    SalesInvHeader2: Record "Sales Invoice Header";
                    gSalesInvHeaderAux: Record "Sales Invoice Header";
                    PostedSalesInvoices: Page "Posted Sales Invoices";
                    gSalesInvoiceLine: Record "Sales Invoice Line";
                    TEXT001: Label 'Client % 1 has no pending advance invoices.', Comment = 'ESM="El cliente %1 no tiene facturas de anticipo pendiente."';
                begin

                    SalesInvHeader2.RESET;
                    SalesInvHeader2.FILTERGROUP(2);
                    SalesInvHeader2.SETRANGE("Bill-to Customer No.", Rec."Bill-to Customer No.");
                    SalesInvHeader2.SETRANGE("Initial Advanced", true);
                    SalesInvHeader2.SETRANGE("Currency Code", "Currency Code");
                    SalesInvHeader2.FILTERGROUP(0);
                    IF SalesInvHeader2.FINDSET THEN BEGIN
                        gSalesInvoiceLine.RESET;
                        //gSalesInvoiceLine.SETRANGE();
                        CLEAR(PostedSalesInvoices);
                        PostedSalesInvoices.LOOKUPMODE(TRUE);
                        PostedSalesInvoices.SETTABLEVIEW(SalesInvHeader2);
                        PostedSalesInvoices.RUNMODAL;
                        PostedSalesInvoices.SetParameters(gNoAdvance);
                        IF gNoAdvance <> '' THEN BEGIN
                            gSalesInvHeaderAux.RESET;
                            gSalesInvHeaderAux.SETRANGE("No.", gNoAdvance);

                            IF gSalesInvHeaderAux.FINDSET THEN
                                Rec.ValidateAnticipo(gSalesInvHeaderAux);
                        END;
                        PostedSalesInvoices.LOOKUPMODE(FALSE);
                    END ELSE
                        MESSAGE(TEXT001, "Bill-to Customer No.", "Currency Code");
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        EBSetup.Get();
        ShowElectronicInvoice := EBSetup."EB Electronic Sender";
    end;

    var
        EBSetup: Record "EB Electronic Bill Setup";
        ShowElectronicInvoice: Boolean;
        gNoAdvance: Code[20];
}