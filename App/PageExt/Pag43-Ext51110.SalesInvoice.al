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
                trigger OnLookup(VAR SerieNo: Text): Boolean
                var
                    Serie: Record "No. Series";
                begin
                    Serie.Reset();
                    serie.SetRange("EB Electronic Bill", "EB Electronic Bill");
                    if Serie.FindFirst() then
                        IF PAGE.RUNMODAL(571, Serie) = ACTION::LookupOK THEN BEGIN
                            SerieNo := Serie.Code;
                            EXIT(TRUE);
                        END;
                end;
            }
        }

        modify("Legal Document")
        {
            trigger OnAfterValidate()
            var
                ChoosingDocTypeErr: Label 'It is not possible to choose this document', comment = 'ESM="No es posible elegir este documento"';
            begin
                if NOT ("Legal Document" IN ['01', '03', '08']) then
                    Error(ChoosingDocTypeErr);
            end;
        }

        addafter(LegalPropertyType)
        {
            group(EBInformation)
            {
                Editable = ShowElectronicInvoice;
                Visible = ShowElectronicInvoice;
                Caption = 'Electronic Bill', Comment = 'ESM="Factura electrónica"';
                field("EB Electronic Bill"; "EB Electronic Bill")
                {
                    ApplicationArea = All;
                    Caption = 'Electronic Bill', Comment = 'ESM="Factura electrónica"';
                }
                field("EB Type Operation Document"; "EB Type Operation Document")
                {
                    ApplicationArea = All;
                    Caption = 'Type Operation Document', Comment = 'ESM="Tipo Operación Documento"';
                    Editable = "EB Electronic Bill";
                }
                // field("EB TAX Ref. Document Type"; "EB TAX Ref. Document Type")
                // {
                //     ApplicationArea = All;
                //     Caption = 'TAX Ref. Document Type';
                //     Editable = "EB Electronic Bill";
                // }

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
}