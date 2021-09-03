codeunit 51015 "EB Billing Management"
{
    trigger OnRun()
    var
        CodeUnit80: codeunit "Sales-Post";

    begin

    end;
    //******************* Integrations with codeunit "Copy Document Mgt." BEGIN ********************
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnBeforeModifySalesHeader', '', true, true)]
    local procedure SetBeforeModifySalesHeader(VAR ToSalesHeader: Record "Sales Header"; FromDocType: Option; FromDocNo: Code[20]; IncludeHeader: Boolean; FromDocOccurenceNo: Integer; FromDocVersionNo: Integer)
    begin
        ToSalesHeader.Validate("Applies-to Doc. No. Ref.", FromDocNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnCopySalesDocOnAfterTransferPostedInvoiceFields', '', true, true)]
    local procedure SetCopySalesDocOnAfterTransferPostedInvoiceFields(var ToSalesHeader: Record "Sales Header"; SalesInvoiceHeader: Record "Sales Invoice Header"; OldSalesHeader: Record "Sales Header")
    begin
        ToSalesHeader.Validate("Legal Document", OldSalesHeader."Legal Document");
    end;
    //******************* Integrations with codeunit "Copy Document Mgt." END  *********************    
    //******************* Integrations with codeunit sales-post BEGIN *********************
    // OnBeforePostSalesDoc(var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var HideProgressWindow: Boolean)
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostSalesDoc', '', false, false)]
    local procedure SetOnBeforePostSalesDoc(var SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean; PreviewMode: Boolean; var HideProgressWindow: Boolean)
    begin
        checkPrePostAccount(SalesHeader);
        CheckElectronicBill(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure SetOnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]; CommitIsSuppressed: Boolean; InvtPickPutaway: Boolean)
    begin
        GetSetup(false);
        if not EBSetup."EB Electronic Sender" then
            exit;
        if SalesInvHdrNo <> '' then begin
            SalesInvHeader.Get(SalesInvHdrNo);
            if not SalesInvHeader."EB Electronic Bill" then
                exit;
            PostElectronicDocument(SalesInvHeader."No.", SalesInvHeader."Legal Document");
        end;
        if SalesCrMemoHdrNo <> '' then begin
            SalesCrMemoHdr.Get(SalesCrMemoHdrNo);
            if not SalesCrMemoHdr."EB Electronic Bill" then
                exit;
            PostElectronicDocument(SalesCrMemoHdr."No.", SalesCrMemoHdr."Legal Document");
        end;
    end;
    //OnBeforeInsertGLEntryBuffer(var TempGLEntryBuf: Record "G/L Entry" temporary; var GenJournalLine: Record "Gen. Journal Line"; var BalanceCheckAmount: Decimal; var BalanceCheckAmount2: Decimal; var BalanceCheckAddCurrAmount: Decimal; var BalanceCheckAddCurrAmount2: Decimal; var NextEntryNo: Integer; var TotalAmount: Decimal; var TotalAddCurrAmount: Decimal)
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeInsertGLEntryBuffer', '', true, true)]
    local procedure SetOnBeforeInsertGLEntryBuffer(var TempGLEntryBuf: Record "G/L Entry" temporary; var GenJournalLine: Record "Gen. Journal Line"; var BalanceCheckAmount: Decimal; var BalanceCheckAmount2: Decimal; var BalanceCheckAddCurrAmount: Decimal; var BalanceCheckAddCurrAmount2: Decimal; var NextEntryNo: Integer; var TotalAmount: Decimal; var TotalAddCurrAmount: Decimal)
    var
        DimensionEntry: Record "Dimension Set Entry";
    begin
        DimensionEntry.Reset();
        DimensionEntry.SetRange("Dimension Set ID", GenJournalLine."Dimension Set ID");
        DimensionEntry.SetRange("Dimension Code", 'ANTICIPO');
        IF DimensionEntry.FindSet() then
            TempGLEntryBuf."EB No. Invoice Advanced" := DimensionEntry."Dimension Value Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterInitRecord', '', True, True)]
    procedure AssignLegalDocumentValues(var SalesHeader: Record "Sales Header")
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Reset();
        NoSeries.SetRange(Code, SalesHeader."Posting No. Series");
        NoSeries.SetRange("EB Electronic Bill", true);
        SalesHeader."EB Electronic Bill" := NoSeries.Find('-');
    end;

    //OnRunOnBeforeFinalizePosting(var SalesHeader: Record "Sales Header"; var SalesShipmentHeader: Record "Sales Shipment Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnReceiptHeader: Record "Return Receipt Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; CommitIsSuppressed: Boolean)
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnRunOnBeforeFinalizePosting', '', false, false)]
    local procedure OnRunOnBeforeFinalizePosting(var SalesHeader: Record "Sales Header"; var SalesShipmentHeader: Record "Sales Shipment Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var ReturnReceiptHeader: Record "Return Receipt Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; CommitIsSuppressed: Boolean)
    var
        DimValue: Record "Dimension Value";
        SLSetup2: Record "Setup Localization";
    begin
        if SalesInvoiceHeader.IsEmpty then
            exit;
        if SalesInvoiceHeader."Invoice Payment Advanced" then begin
            DimValue.Init();
            DimValue."Dimension Code" := 'ANTICIPO';
            DimValue.Code := SalesInvoiceHeader."No.";
            DimValue.Name := 'Descripción definir por lizeth';
            DimValue.Insert();
        end;
    end;
    //******************* Integrations with codeunit sales-post END *********************
    //******************* Integrations with codeunit "Correct Posted Document" BEGIN ********************
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LD Correct Posted Documents", 'OnAfterCreateCreditMemoFromPostedSalesinvoice', '', true, true)]
    local procedure SetAfterCreateCreditMemoFromPostedSalesinvoice(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        if SalesHeader."Legal Status" in [SalesHeader."Legal Status"::Anulled, SalesHeader."Legal Status"::OutFlow] then begin
            SalesHeader."EB Electronic Bill" := false;
            SalesHeader.Modify();
        end;
    end;
    //************************** POSTED *******************************

    procedure PostElectronicDocument(pDocumentNo: Code[20]; pLegalDocument: Code[10]): Text
    begin
        Initialize();
        DocumentNo := pDocumentNo;
        LegalDocument := pLegalDocument;
        Invoice := LegalDocument = '01';
        Ticket := LegalDocument = '03';
        CreditNote := LegalDocument = '07';
        DebitNote := LegalDocument = '08';
        if CreditNote then begin
            SalesCrMemoHdr.Get(DocumentNo);
            SalesCrMemoHdr.CalcFields(Amount, "Amount Including VAT");
            Customer.Get(SalesCrMemoHdr."Sell-to Customer No.");
        end else begin
            SalesInvHeader.Get(DocumentNo);
            SalesInvHeader.CalcFields(Amount, "Amount Including VAT");
            Customer.Get(SalesInvHeader."Sell-to Customer No.");
        end;
        CreateXmlDocuments();
        ConsumeService();
    end;

    procedure GetDocumentFile(var EBEntry: Record "EB Electronic Bill Entry"; FileTypeOption: Option)
    var
        LegalDocumentInt: Integer;
    begin
        GetFileDocument := true;
        case FileTypeOption of
            0:
                FileType := 'PDF';
            1:
                FileType := 'XML';
            2:
                FileType := 'CDR';
        end;
        DocumentNo := EBEntry."EB Document No.";
        LegalDocument := EBEntry."EB Legal Document";
        GetSetup(true);
        CreateXmlGetDocument();
        ConsumeService();
    end;

    local procedure Initialize()
    begin
        Clear(Invoice);
        Clear(Ticket);
        Clear(CreditNote);
        Clear(DebitNote);
        GetSetup(true);
    end;

    local procedure CreateXmlDocuments()
    begin
        CreateTempFile();
        if Invoice or Ticket then
            CreateXmlInvoiceTicket();
        if CreditNote then
            CreateXmlCreditNote();
        if DebitNote then
            CreateXmlDebitNote();
    end;

    local procedure CreateXmlInvoiceTicket()
    begin
        HeadersXMLPart();
        GeneralInfoXMLPart();
        NoteXMLPart();
        SupplierAccountXMLPart();
        CustomerAccountXMLPart();
        DetractionXMLPart();
        PrePaidPaymentXMLPart();
        TotalSaleValueXMLPart();
        TotalTaxAmtXMLPart();
        DetailedInvoiceTicketXMLPart();
        PersonalizationPDFXMLPart();
        PaymentTermsSunatXMLPart();
        FooterXMLPart();
    end;

    local procedure CreateXmlCreditNote()
    begin
        HeadersXMLPart();
        GeneralInfoXMLPart();
        SupplierAccountXMLPart();
        CustomerAccountXMLPart();
        TotalTaxAmtXMLPart();
        TotalSaleValueXMLPart();
        DetailedCreditNoteXMLPart();
        PersonalizationPDFXMLPart();
        PaymentTermsSunatXMLPart();
        FooterXMLPart();
    end;

    local procedure CreateXmlDebitNote()
    begin
        HeadersXMLPart();
        GeneralInfoXMLPart();
        SupplierAccountXMLPart();
        CustomerAccountXMLPart();
        TotalTaxAmtXMLPart();
        TotalSaleValueXMLPart();
        DetailedDebitNoteXMLPart();
        PersonalizationPDFXMLPart();
        FooterXMLPart();
    end;

    local procedure CreateXmlGetDocument()
    var
        LegalDocInteger: Integer;
    begin
        Evaluate(LegalDocInteger, LegalDocument);
        CreateTempFile();
        AddLineXMLTemp('<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">');
        AddLineXMLTemp('<soapenv:Header/>');
        AddLineXMLTemp('<soapenv:Body>');
        AddLineXMLTemp('    <tem:getDocument>');
        AddLineXMLTemp('        <tem:ruc>' + CompanyInfo."VAT Registration No." + '</tem:ruc>');
        AddLineXMLTemp('        <tem:document>' + DocumentNo + '</tem:document>');
        AddLineXMLTemp('        <tem:type>' + Format(LegalDocInteger) + '</tem:type>');
        AddLineXMLTemp('        <tem:archivo>' + FileType + '</tem:archivo>');
        AddLineXMLTemp('    </tem:getDocument>');
        AddLineXMLTemp('</soapenv:Body>');
        AddLineXMLTemp('</soapenv:Envelope>');
    end;

    local procedure HeadersXMLPart()
    begin
        AddLineXMLTemp('<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ');
        AddLineXMLTemp('xmlns:tem="http://tempuri.org/" ');
        AddLineXMLTemp('xmlns:elec="http://schemas.datacontract.org/2004/07/ElectronicBilling.Structures" ');
        AddLineXMLTemp('xmlns:elec1="http://schemas.datacontract.org/2004/07/ElectronicBilling.Structures.Level1" ');
        AddLineXMLTemp('xmlns:elec2="http://schemas.datacontract.org/2004/07/ElectronicBilling.Structures.Level2" ');
        AddLineXMLTemp('xmlns:elec3="http://schemas.datacontract.org/2004/07/ElectronicBilling.Structures.Level3" ');
        AddLineXMLTemp('xmlns:elec4="http://schemas.datacontract.org/2004/07/ElectronicBilling.Structures.Level4" ');
        AddLineXMLTemp('xmlns:elec5="http://schemas.datacontract.org/2004/07/ElectronicBilling.Structures.Level5" ');
        AddLineXMLTemp('xmlns:elec6="http://schemas.datacontract.org/2004/07/ElectronicBilling.Utils" ');
        AddLineXMLTemp('xmlns:arr="http://schemas.microsoft.com/2003/10/Serialization/Arrays" >');
        AddLineXMLTemp('<soapenv:Header/>');
        AddLineXMLTemp('<soapenv:Body>');

        case true of
            Invoice:
                begin
                    AddLineXMLTemp('<tem:sendInvoiceDocuments>');
                    AddLineXMLTemp('<tem:pInvoice>');
                end;
            Ticket:
                begin
                    AddLineXMLTemp('<tem:sendTicketDocuments>');
                    AddLineXMLTemp('<tem:pInvoice>');
                end;
            CreditNote:
                begin
                    AddLineXMLTemp('<tem:sendCreditNoteDocuments>');
                    AddLineXMLTemp('<tem:pCreditNote>');
                end;
            DebitNote:
                begin
                    AddLineXMLTemp('<tem:sendDebitNoteDocuments>');
                    AddLineXMLTemp('<tem:pDebitNote>');
                end;
        end;
    end;

    local procedure GeneralInfoXMLPart()
    begin
        case true of
            Invoice, Ticket:
                begin
                    AddLineXMLTemp(CreateXMLTag('elec:ID', SalesInvHeader."No."));
                    AddLineXMLTemp(CreateXMLTag('elec:IssueDate', FormatDate(SalesInvHeader."Posting Date")));
                    //AddLineXMLTemp(CreateXMLTag('elec:IssueTime', FormatTime(SalesInvHeader."Hora Registro")));
                    AddLineXMLTemp(CreateXMLTag('elec:IssueTime', FormatTime(TIME)));
                    AddLineXMLTemp(CreateXMLTag('elec:DueDate', FormatDate(SalesInvHeader."Due Date")));
                    AddLineXMLTemp(CreateXMLTag('elec:ProfileID', SalesInvHeader."EB Type Operation Document"));
                    AddLineXMLTemp(CreateXMLTag('elec:InvoiceTypeCode', SalesInvHeader."Legal Document"));
                    AddLineXMLTemp(CreateXMLTag('elec:DocumentCurrencyCode', GetCurrencyCode(SalesInvHeader."Currency Code")));
                    //AddLineXMLTemp(CreateXMLTag('elec:InvoiceTypeCode_listID', alesInvHeader."Legal Document"));
                    AddLineXMLTemp(CreateXMLTag('elec:LineCountNumeric', Format(1)));
                end;
            CreditNote:
                begin
                    AddLineXMLTemp(CreateXMLTag('elec:ID', SalesCrMemoHdr."No."));
                    AddLineXMLTemp(CreateXMLTag('elec:IssueDate', FormatDate(SalesCrMemoHdr."Posting Date")));
                    //AddLineXMLTemp(CreateXMLTag('elec:IssueTime', FormatTime(SalesCrMemoHdr."Hora Registro")));
                    AddLineXMLTemp(CreateXMLTag('elec:IssueTime', FormatTime(TIME)));
                    AddLineXMLTemp(CreateXMLTag('elec:ProfileID', SalesCrMemoHdr."EB Type Operation Document"));//RPA
                    NoteXMLPart();
                    /*AddLineXMLTemp('<elec:lNote>');
                                AddLineXMLTemp('<elec1:Note>');
                                AddLineXMLTemp(CreateXMLTag('elec1:languageLocaleID', '1000'));
                                AddLineXMLTemp(CreateXMLTag('elec1:value', '<![CDATA[' + GetAmoutToText(SalesCrMemoHdr."Amount Including VAT", SalesCrMemoHdr."Currency Code") + ']]>'));
                                AddLineXMLTemp('</elec1:Note>');
                                AddLineXMLTemp('</elec:lNote>');*/
                    AddLineXMLTemp(CreateXMLTag('elec:DocumentCurrencyCode', GetCurrencyCode(SalesCrMemoHdr."Currency Code")));
                    //--Codigo Tipo de Nota de Credito + Motivo o Sustento --------
                    AddLineXMLTemp('<elec:eDiscrepancyResponse>');
                    //AddLineXMLTemp(CreateXMLTag('elec1:referenceId' ,SalesCrMemoHdr."Applies-to Doc. No. 2"));
                    AddLineXMLTemp(CreateXMLTag('elec1:referenceId', SalesCrMemoHdr."Applies-to Doc. No."));
                    AddLineXMLTemp(CreateXMLTag('elec1:responseCode', SalesCrMemoHdr."EB NC/ND Description Type"));
                    AddLineXMLTemp(CreateXMLTag('elec1:description', '<![CDATA[' + SalesCrMemoHdr."EB NC/ND Support Description" + ']]>'));
                    AddLineXMLTemp(CreateXMLTag('elec1:MotivoDescription', '<![CDATA[' + GetCatalogoDescription(SalesCrMemoHdr."EB NC/ND Description Type", '09') + ']]>'));
                    AddLineXMLTemp('</elec:eDiscrepancyResponse>');

                    //--Tipo - Serie y número del documento que modifica-------------
                    AddLineXMLTemp('<elec:eBillingReference>');
                    AddLineXMLTemp('<elec2:eInvoiceDocumentReference>');
                    AddLineXMLTemp(CreateXMLTag('elec3:DocumentTypeCode', SalesCrMemoHdr."Legal Document Ref."));
                    AddLineXMLTemp(CreateXMLTag('elec3:ID', SalesCrMemoHdr."Applies-to Doc. No."));
                    AddLineXMLTemp('</elec2:eInvoiceDocumentReference>');
                    AddLineXMLTemp('</elec:eBillingReference>');
                end;
            DebitNote:
                begin
                    AddLineXMLTemp(CreateXMLTag('elec:ID', SalesInvHeader."No."));
                    AddLineXMLTemp(CreateXMLTag('elec:IssueDate', FormatDate(SalesInvHeader."Posting Date")));
                    AddLineXMLTemp(CreateXMLTag('elec:ProfileID', SalesInvHeader."EB Type Operation Document"));//RPA
                    NoteXMLPart();
                    AddLineXMLTemp(CreateXMLTag('elec:DocumentCurrencyCode', GetCurrencyCode(SalesInvHeader."Currency Code")));

                    //--Codigo Tipo de Nota de Credito + Motivo o Sustento --------
                    if SalesInvHeader."EB NC/ND Description Type" <> '03' then begin
                        AddLineXMLTemp('<elec:eDiscrepancyResponse>');
                        AddLineXMLTemp(CreateXMLTag('elec1:referenceId', SalesInvHeader."Applies-to Doc. No. Ref."));
                        AddLineXMLTemp(CreateXMLTag('elec1:responseCode', SalesInvHeader."EB NC/ND Description Type"));
                        AddLineXMLTemp(CreateXMLTag('elec1:description', '<![CDATA[' + SalesInvHeader."EB NC/ND Support Description" + ']]>'));
                        AddLineXMLTemp(CreateXMLTag('elec1:MotivoDescription', '<![CDATA[' + GetCatalogoDescription(SalesInvHeader."EB NC/ND Description Type", '10') + ']]>'));
                        AddLineXMLTemp('</elec:eDiscrepancyResponse>');
                        //---------------------------------------------------------------

                        //--Tipo - Serie y número del documento que modifica-------------
                        AddLineXMLTemp('<elec:eBillingReference>');
                        AddLineXMLTemp('<elec2:eInvoiceDocumentReference>');
                        AddLineXMLTemp(CreateXMLTag('elec3:DocumentTypeCode', SalesInvHeader."Legal Document Ref."));
                        AddLineXMLTemp(CreateXMLTag('elec3:ID', SalesInvHeader."Applies-to Doc. No. Ref."));
                        AddLineXMLTemp('</elec2:eInvoiceDocumentReference>');
                        AddLineXMLTemp('</elec:eBillingReference>');
                    end else begin
                        AddLineXMLTemp('<elec:eDiscrepancyResponse>');
                        AddLineXMLTemp(CreateXMLTag('elec1:responseCode', SalesInvHeader."EB NC/ND Description Type"));
                        AddLineXMLTemp(CreateXMLTag('elec1:description', '<![CDATA[' + SalesInvHeader."EB NC/ND Support Description" + ']]>'));
                        AddLineXMLTemp('</elec:eDiscrepancyResponse>');
                    end;
                end;
        end;
    end;

    local procedure NoteXMLPart()
    begin
        AddLineXMLTemp('<elec:lNote>');
        AddLineXMLTemp('<elec1:Note>');
        AddLineXMLTemp(CreateXMLTag('elec1:languageLocaleID', '1000'));
        if CreditNote then begin
            if SalesCrMemoHdr."FT Free Title" then
                AddLineXMLTemp(CreateXMLTag('elec1:value', '<![CDATA[' + GetAmoutToText(0, SalesCrMemoHdr."Currency Code") + ']]>'))
            else
                AddLineXMLTemp(CreateXMLTag('elec1:value', '<![CDATA[' + GetAmoutToText(SalesCrMemoHdr."Amount Including VAT", SalesCrMemoHdr."Currency Code") + ']]>'))
        end else begin
            if SalesInvHeader."FT Free Title" then
                AddLineXMLTemp(CreateXMLTag('elec1:value', '<![CDATA[' + GetAmoutToText(0, SalesInvHeader."Currency Code") + ']]>'))
            else
                AddLineXMLTemp(CreateXMLTag('elec1:value', '<![CDATA[' + GetAmoutToText(SalesInvHeader."Amount Including VAT", SalesInvHeader."Currency Code") + ']]>'));
        end;
        AddLineXMLTemp('</elec1:Note>');
        if SalesInvHeader."Sales Detraction" then begin
            AddLineXMLTemp('<elec1:Note>');
            AddLineXMLTemp(CreateXMLTag('elec1:languageLocaleID', '2006'));
            AddLineXMLTemp(CreateXMLTag('elec1:value', '<![CDATA[LEYENDA: OPERACIÓN SUJETA A DETRACCIÓN]]>'));
            AddLineXMLTemp('</elec1:Note>');
        end;
        if SalesInvHeader."FT Free Title" then begin
            AddLineXMLTemp('<elec1:Note>');
            AddLineXMLTemp(CreateXMLTag('elec1:languageLocaleID', '1002'));
            AddLineXMLTemp(CreateXMLTag('elec1:value', '<![CDATA[LEYENDA: TRANSFERENCIA GRATUITA DE UN BIEN Y/O SERVICIO PRESTADO GRATUITAMENTE]]>'));
            AddLineXMLTemp('</elec1:Note>');
        end;
        AddLineXMLTemp('</elec:lNote>');
    end;

    local procedure SupplierAccountXMLPart()
    begin
        if not (Invoice or Ticket or CreditNote or DebitNote) then
            exit;
        AddLineXMLTemp('<elec:eAccountingSupplierParty>');
        AddLineXMLTemp(CreateXMLTag('elec1:AccountID', NormalizeRUC(CompanyInfo."VAT Registration No.")));
        AddLineXMLTemp(CreateXMLTag('elec1:AdditionalAccountID', NormalizeRUC(CompanyInfo."VAT Registration Type")));
        AddLineXMLTemp(CreateXMLTag('elec1:CustomerAssignedAccountID', NormalizeRUC(CompanyInfo."VAT Registration No.")));
        AddLineXMLTemp('<elec1:eParty>');
        //if Invoice or Ticket then
        //AddLineXMLTemp(CreateXMLTag('elec2:ePartyIdentification',CreateXMLTag('elec3:ID',CompanyInfo."VAT Registration No."+'-'+SalesInvHeader."VAT Registration Type"+'-'+SalesInvHeader."No." )))
        //else
        AddLineXMLTemp(CreateXMLTag('elec2:ePartyIdentification', CreateXMLTag('elec3:ID', NormalizeRUC(CompanyInfo."VAT Registration No."))));

        AddLineXMLTemp('<elec2:ePartyLegalEntity>');
        AddLineXMLTemp(CreateXMLTag('elec3:RegistrationName', '<![CDATA[' + ConverSpecialCharAmpersam(ConvertSpecialCharEnie(CompanyInfo.Name)) + ']]>'));
        AddLineXMLTemp('<elec3:eRegistrationAddress>');
        AddLineXMLTemp(CreateXMLTag('elec4:AddressLine', '<![CDATA[' + CompanyInfo.Address + ']]>'));
        AddLineXMLTemp(CreateXMLTag('elec4:AddressTypeCode', '0000'));
        AddLineXMLTemp(CreateXMLTag('elec4:CityName', CopyStr(UbigeoMgt.Departament(CompanyInfo."Country/Region Code", CompanyInfo."Post Code"), 1, 30)));
        AddLineXMLTemp(CreateXMLTag('elec4:CountrySubentity', CopyStr(UbigeoMgt.Province(CompanyInfo."Country/Region Code", CompanyInfo."Post Code", CompanyInfo.City), 1, 30)));
        AddLineXMLTemp(CreateXMLTag('elec4:District', CopyStr(UbigeoMgt.District(CompanyInfo."Country/Region Code", CompanyInfo."Post Code", CompanyInfo.City, CompanyInfo.County), 1, 30)));
        AddLineXMLTemp(CreateXMLTag('elec4:ID', CompanyInfo."Post Code" + CompanyInfo.City + CompanyInfo.County));
        AddLineXMLTemp(CreateXMLTag('elec4:eCountry', CreateXMLTag('elec5:IdentificationCode', CompanyInfo."Country/Region Code")));
        AddLineXMLTemp('</elec3:eRegistrationAddress>');
        AddLineXMLTemp('</elec2:ePartyLegalEntity>');

        AddLineXMLTemp(CreateXMLTag('elec2:ePartyName', CreateXMLTag('elec3:Name', CompanyInfo.Name)));

        AddLineXMLTemp('<elec2:ePartyTaxScheme>');
        AddLineXMLTemp(CreateXMLTag('elec3:CompanyID', NormalizeRUC(CompanyInfo."VAT Registration No.")));
        AddLineXMLTemp(CreateXMLTag('elec3:CompanyID_schemeID', CompanyInfo."VAT Registration Type"));
        AddLineXMLTemp('<elec3:eRegistrationAddress>');
        AddLineXMLTemp(CreateXMLTag('elec4:AddressLine', '<![CDATA[' + CompanyInfo.Address + ']]>'));
        AddLineXMLTemp(CreateXMLTag('elec4:AddressTypeCode', '0000'));
        AddLineXMLTemp(CreateXMLTag('elec4:CityName', CopyStr(UbigeoMgt.Departament(CompanyInfo."Country/Region Code", CompanyInfo."Post Code"), 1, 30)));
        AddLineXMLTemp(CreateXMLTag('elec4:CountrySubentity', CopyStr(UbigeoMgt.Province(CompanyInfo."Country/Region Code", CompanyInfo."Post Code", CompanyInfo.City), 1, 30)));
        AddLineXMLTemp(CreateXMLTag('elec4:District', CopyStr(UbigeoMgt.District(CompanyInfo."Country/Region Code", CompanyInfo."Post Code", CompanyInfo.City, CompanyInfo.County), 1, 30)));
        AddLineXMLTemp(CreateXMLTag('elec4:ID', CompanyInfo."Post Code" + CompanyInfo.City + CompanyInfo.County));
        AddLineXMLTemp(CreateXMLTag('elec4:eCountry', CreateXMLTag('elec5:IdentificationCode', CompanyInfo."Country/Region Code")));
        AddLineXMLTemp('</elec3:eRegistrationAddress>');
        AddLineXMLTemp('</elec2:ePartyTaxScheme>');
        AddLineXMLTemp('</elec1:eParty>');
        AddLineXMLTemp('</elec:eAccountingSupplierParty>');
    end;

    local procedure CustomerAccountXMLPart()
    begin
        if Invoice or Ticket or DebitNote then begin
            AddLineXMLTemp('<elec:eAccountingCustomerParty>');
            AddLineXMLTemp(CreateXMLTag('elec1:CustomerAssignedAccountID', SalesInvHeader."VAT Registration Type"));
            AddLineXMLTemp(CreateXMLTag('elec1:CustomerAccountID', NormalizeRUC(SalesInvHeader."VAT Registration No.")));
            AddLineXMLTemp(CreateXMLTag('elec1:CustomerName', '<![CDATA[' + SalesInvHeader."Sell-to Customer Name" + ']]>'));
            AddLineXMLTemp(CreateXMLTag('elec1:CustomerAddress', '<![CDATA[' + SalesInvHeader."Sell-to Address" + ']]>'));
            if EBSetup."Send electronic documents to" <> '' then
                AddLineXMLTemp(CreateXMLTag('elec1:CustomerEmail', StrSubstNo('%1;%2', EBSetup."Send electronic documents to", SalesInvHeader."Sell-to E-Mail")))
            else
                AddLineXMLTemp(CreateXMLTag('elec1:CustomerEmail', SalesInvHeader."Sell-to E-Mail"));
            AddLineXMLTemp('<elec1:eParty>');
            if DebitNote then begin
                if SalesInvHeader."VAT Registration Type" = '0' then
                    AddLineXMLTemp(CreateXMLTag('elec2:ePartyIdentification', CreateXMLTag('elec3:ID', ConvertAdjustVATRegistrationNo(SalesInvHeader."VAT Registration No."))))
                else
                    AddLineXMLTemp(CreateXMLTag('elec2:ePartyIdentification', CreateXMLTag('elec3:ID', NormalizeRUC(SalesInvHeader."VAT Registration No."))));
            end else
                AddLineXMLTemp(CreateXMLTag('elec2:ePartyIdentification', CreateXMLTag('elec3:ID', NormalizeRUC(SalesInvHeader."VAT Registration No."))));
            AddLineXMLTemp('<elec2:ePartyLegalEntity>');
            AddLineXMLTemp(CreateXMLTag('elec3:RegistrationName', '<![CDATA[' + SalesInvHeader."Sell-to Customer Name" + ']]>'));
            AddLineXMLTemp('<elec3:eRegistrationAddress>');
            AddLineXMLTemp(CreateXMLTag('elec4:AddressLine', '<![CDATA[' + SalesInvHeader."Sell-to Address" + ']]>'));
            if SalesInvHeader."Sell-to Country/Region Code" = 'PE' then begin
                AddLineXMLTemp(CreateXMLTag('elec4:CityName', UbigeoMgt.Departament(SalesInvHeader."Sell-to Country/Region Code", SalesInvHeader."Sell-to Post Code")));
                AddLineXMLTemp(CreateXMLTag('elec4:CountrySubentity', UbigeoMgt.Province(SalesInvHeader."Sell-to Country/Region Code", SalesInvHeader."Sell-to Post Code", SalesInvHeader."Sell-to City")));
                AddLineXMLTemp(CreateXMLTag('elec4:District', UbigeoMgt.District(SalesInvHeader."Sell-to Country/Region Code", SalesInvHeader."Sell-to Post Code", SalesInvHeader."Sell-to City", SalesInvHeader."Sell-to County")));
            end;
            AddLineXMLTemp(CreateXMLTag('elec4:ID', SalesInvHeader."Sell-to Post Code" + SalesInvHeader."Sell-to City" + SalesInvHeader."Sell-to County"));
            AddLineXMLTemp(CreateXMLTag('elec4:eCountry', CreateXMLTag('elec5:IdentificationCode', SalesInvHeader."Sell-to Country/Region Code")));
            AddLineXMLTemp('</elec3:eRegistrationAddress>');
            AddLineXMLTemp('</elec2:ePartyLegalEntity>');
            AddLineXMLTemp(CreateXMLTag('elec2:ePartyName', CreateXMLTag('elec3:Name', '<![CDATA[' + SalesInvHeader."Sell-to Customer Name" + ']]>')));
            AddLineXMLTemp('<elec2:ePartyTaxScheme>');
            AddLineXMLTemp(CreateXMLTag('elec3:CompanyID', NormalizeRUC(SalesInvHeader."VAT Registration No.")));
            AddLineXMLTemp(CreateXMLTag('elec3:CompanyID_schemeID', SalesInvHeader."VAT Registration Type"));
            AddLineXMLTemp(CreateXMLTag('elec3:RegistrationName', '<![CDATA[' + ConverSpecialCharAmpersam(ConvertSpecialCharEnie(SalesInvHeader."Sell-to Customer Name")) + ']]>'));
            AddLineXMLTemp('<elec3:eRegistrationAddress>');
            AddLineXMLTemp(CreateXMLTag('elec4:AddressLine', '<![CDATA[' + SalesInvHeader."Sell-to Address" + ']]>'));
            AddLineXMLTemp(CreateXMLTag('elec4:AddressTypeCode', ''));
            if SalesInvHeader."Sell-to Country/Region Code" = 'PE' then begin
                AddLineXMLTemp(CreateXMLTag('elec4:CityName', UbigeoMgt.Departament(SalesInvHeader."Sell-to Country/Region Code", SalesInvHeader."Sell-to Post Code")));
                AddLineXMLTemp(CreateXMLTag('elec4:CountrySubentity', UbigeoMgt.Province(SalesInvHeader."Sell-to Country/Region Code", SalesInvHeader."Sell-to Post Code", SalesInvHeader."Sell-to City")));
                AddLineXMLTemp(CreateXMLTag('elec4:District', UbigeoMgt.District(SalesInvHeader."Sell-to Country/Region Code", SalesInvHeader."Sell-to Post Code", SalesInvHeader."Sell-to City", SalesInvHeader."Sell-to County")));
            end;
            AddLineXMLTemp(CreateXMLTag('elec4:ID', SalesInvHeader."Sell-to Post Code" + SalesInvHeader."Sell-to City" + SalesInvHeader."Sell-to County"));
            AddLineXMLTemp(CreateXMLTag('elec4:eCountry', CreateXMLTag('elec5:IdentificationCode', SalesInvHeader."Sell-to Country/Region Code")));
            AddLineXMLTemp('</elec3:eRegistrationAddress>');
            AddLineXMLTemp('</elec2:ePartyTaxScheme>');
            AddLineXMLTemp('</elec1:eParty>');
            AddLineXMLTemp('</elec:eAccountingCustomerParty>');
        end;
        if CreditNote then begin
            AddLineXMLTemp('<elec:eAccountingCustomerParty>');
            AddLineXMLTemp(CreateXMLTag('elec1:CustomerAssignedAccountID', SalesCrMemoHdr."VAT Registration Type"));
            AddLineXMLTemp(CreateXMLTag('elec1:CustomerAccountID', NormalizeRUC(SalesCrMemoHdr."VAT Registration No.")));
            AddLineXMLTemp(CreateXMLTag('elec1:CustomerName', '<![CDATA[' + SalesCrMemoHdr."Sell-to Customer Name" + ']]>'));
            AddLineXMLTemp(CreateXMLTag('elec1:CustomerAddress', '<![CDATA[' + SalesCrMemoHdr."Sell-to Address" + ']]>'));
            if EBSetup."Send electronic documents to" <> '' then
                AddLineXMLTemp(CreateXMLTag('elec1:CustomerEmail', StrSubstNo('%1;%2', EBSetup."Send electronic documents to", SalesCrMemoHdr."Sell-to E-Mail")))
            else
                AddLineXMLTemp(CreateXMLTag('elec1:CustomerEmail', SalesCrMemoHdr."Sell-to E-Mail"));
            AddLineXMLTemp('<elec1:eParty>');
            if SalesCrMemoHdr."VAT Registration Type" = '0' then
                AddLineXMLTemp(CreateXMLTag('elec2:ePartyIdentification', CreateXMLTag('elec3:ID', ConvertAdjustVATRegistrationNo(SalesCrMemoHdr."VAT Registration No."))))
            else
                AddLineXMLTemp(CreateXMLTag('elec2:ePartyIdentification', CreateXMLTag('elec3:ID', NormalizeRUC(SalesCrMemoHdr."VAT Registration No."))));
            AddLineXMLTemp('<elec2:ePartyLegalEntity>');
            AddLineXMLTemp(CreateXMLTag('elec3:RegistrationName', '<![CDATA[' + SalesCrMemoHdr."Sell-to Customer Name" + ']]>'));
            AddLineXMLTemp('<elec3:eRegistrationAddress>');
            AddLineXMLTemp(CreateXMLTag('elec4:AddressLine', '<![CDATA[' + SalesCrMemoHdr."Sell-to Address" + ']]>'));
            if SalesCrMemoHdr."Sell-to Country/Region Code" = 'PE' then begin
                AddLineXMLTemp(CreateXMLTag('elec4:CityName', UbigeoMgt.Departament(SalesCrMemoHdr."Sell-to Country/Region Code", SalesCrMemoHdr."Sell-to Post Code")));
                AddLineXMLTemp(CreateXMLTag('elec4:CountrySubentity', UbigeoMgt.Province(SalesCrMemoHdr."Sell-to Country/Region Code", SalesCrMemoHdr."Sell-to Post Code", SalesCrMemoHdr."Sell-to City")));
                AddLineXMLTemp(CreateXMLTag('elec4:District', UbigeoMgt.District(SalesCrMemoHdr."Sell-to Country/Region Code", SalesCrMemoHdr."Sell-to Post Code", SalesCrMemoHdr."Sell-to City", SalesCrMemoHdr."Sell-to County")));
            end;
            AddLineXMLTemp(CreateXMLTag('elec4:ID', SalesCrMemoHdr."Sell-to Post Code" + SalesCrMemoHdr."Sell-to City" + SalesCrMemoHdr."Sell-to County"));
            AddLineXMLTemp(CreateXMLTag('elec4:eCountry', CreateXMLTag('elec5:IdentificationCode', SalesCrMemoHdr."Sell-to Country/Region Code")));
            AddLineXMLTemp('</elec3:eRegistrationAddress>');
            AddLineXMLTemp('</elec2:ePartyLegalEntity>');
            AddLineXMLTemp(CreateXMLTag('elec2:ePartyName', CreateXMLTag('elec3:Name', '<![CDATA[' + SalesCrMemoHdr."Sell-to Customer Name" + ']]>')));
            AddLineXMLTemp('<elec2:ePartyTaxScheme>');
            AddLineXMLTemp(CreateXMLTag('elec3:CompanyID', NormalizeRUC(SalesCrMemoHdr."VAT Registration No.")));
            AddLineXMLTemp(CreateXMLTag('elec3:CompanyID_schemeID', SalesCrMemoHdr."VAT Registration Type"));
            AddLineXMLTemp(CreateXMLTag('elec3:RegistrationName', '<![CDATA[' + ConverSpecialCharAmpersam(ConvertSpecialCharEnie(SalesCrMemoHdr."Sell-to Customer Name")) + ']]>'));
            AddLineXMLTemp('<elec3:eRegistrationAddress>');
            AddLineXMLTemp(CreateXMLTag('elec4:AddressLine', '<![CDATA[' + SalesCrMemoHdr."Sell-to Address" + ']]>'));
            AddLineXMLTemp(CreateXMLTag('elec4:AddressTypeCode', ''));
            if SalesCrMemoHdr."Sell-to Country/Region Code" = 'PE' then begin
                AddLineXMLTemp(CreateXMLTag('elec4:CityName', UbigeoMgt.Departament(SalesCrMemoHdr."Sell-to Country/Region Code", SalesCrMemoHdr."Sell-to Post Code")));
                AddLineXMLTemp(CreateXMLTag('elec4:CountrySubentity', UbigeoMgt.Province(SalesCrMemoHdr."Sell-to Country/Region Code", SalesCrMemoHdr."Sell-to Post Code", SalesCrMemoHdr."Sell-to City")));
                AddLineXMLTemp(CreateXMLTag('elec4:District', UbigeoMgt.District(SalesCrMemoHdr."Sell-to Country/Region Code", SalesCrMemoHdr."Sell-to Post Code", SalesCrMemoHdr."Sell-to City", SalesCrMemoHdr."Sell-to County")));
            end;
            AddLineXMLTemp(CreateXMLTag('elec4:ID', SalesCrMemoHdr."Sell-to Post Code" + SalesCrMemoHdr."Sell-to City" + SalesCrMemoHdr."Sell-to County"));
            AddLineXMLTemp(CreateXMLTag('elec4:eCountry', CreateXMLTag('elec5:IdentificationCode', SalesCrMemoHdr."Sell-to Country/Region Code")));
            AddLineXMLTemp('</elec3:eRegistrationAddress>');
            AddLineXMLTemp('</elec2:ePartyTaxScheme>');
            AddLineXMLTemp('</elec1:eParty>');
            AddLineXMLTemp('</elec:eAccountingCustomerParty>');
        end;
    end;

    local procedure DetractionXMLPart()
    begin
        if not SalesInvHeader."Sales Detraction" then
            exit;
        if not (Invoice or Ticket) then
            exit;
        AddLineXMLTemp('<elec:ePaymentMeans>');
        AddLineXMLTemp(CreateXMLTag('elec1:PaymentMeansCode', SalesInvHeader."Payment Method Code Detrac"));
        AddLineXMLTemp('<elec1:ePayeeFinancialAccount>');
        AddLineXMLTemp(CreateXMLTag('elec2:ID', EBSetup."EB National Bank Account No."));
        AddLineXMLTemp('</elec1:ePayeeFinancialAccount>');
        AddLineXMLTemp('</elec:ePaymentMeans>');
        AddLineXMLTemp('<elec:ePaymentTerms>');
        AddLineXMLTemp(CreateXMLTag('elec1:ID', SalesInvHeader."Service Type Detrac"));
        AddLineXMLTemp(CreateXMLTag('elec1:PaymentMeansID', SalesInvHeader."Service Type Detrac"));
        AddLineXMLTemp(CreateXMLTag('elec1:PaymentPercent', Format(SalesInvHeader."Sales % Detraction")));
        AddLineXMLTemp(CreateXMLTag('elec1:Amount', FormatNumber(SalesInvHeader."Sales Amt Detraction (LCY)")));
        AddLineXMLTemp(CreateXMLTag('elec1:currencyDetra', 'PEN'));
        AddLineXMLTemp('</elec:ePaymentTerms>');
    end;

    local procedure PrePaidPaymentXMLPart()
    var
        PrePaymentSalesInvHdr: Record "Sales Invoice Header";
    begin
        if not (Invoice or Ticket) then
            exit;
        if not (SalesInvHeader."Final Advanced") then //Factura final anticipo
            exit;

        SalesInvLine.Reset;
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        SalesInvLine.SetFilter("EB No. Invoice Advanced", '<>%1', '');
        if SalesInvLine.FindFirst then begin
            AddLineXMLTemp('<elec:lPrepaidPayment>');
            repeat
                PrePaymentSalesInvHdr.Get(SalesInvLine."EB No. Invoice Advanced");
                //AddLineXMLTemp('<elec:ePrepaidPayment>');
                AddLineXMLTemp('<elec1:PrepaidPayment>');
                AddLineXMLTemp(CreateXMLTag('elec1:ID', SalesInvLine."EB No. Invoice Advanced"));//Add develope
                AddLineXMLTemp(CreateXMLTag('elec1:PaidAmount', FormatNumber(Abs(SalesInvLine."Amount Including VAT"))));
                AddLineXMLTemp(CreateXMLTag('elec1:currencyID', GetCurrencyCode(PrePaymentSalesInvHdr."Currency Code")));
                AddLineXMLTemp(CreateXMLTag('elec1:PaidDate', FormatDate(PrePaymentSalesInvHdr."Due Date")));
                AddLineXMLTemp(CreateXMLTag('elec1:InstructionID', PrePaymentSalesInvHdr."VAT Registration Type"));
                AddLineXMLTemp(CreateXMLTag('elec1:ID_schemeID', PrePaymentSalesInvHdr."Legal Document"));
                AddLineXMLTemp(CreateXMLTag('elec1:DocumentTypeCode', '02'));
                //AddLineXMLTemp(CreateXMLTag('elec1:DocumentTypeCode', PrePaymentSalesInvHdr."EB TAX Ref. Document Type"));
                AddLineXMLTemp(CreateXMLTag('elec1:PaidTaxableAmount', FormatNumber(Abs(SalesInvLine.Amount))));
                AddLineXMLTemp(CreateXMLTag('elec1:ReceivedDate', FormatDate(PrePaymentSalesInvHdr."Document Date")));
                AddLineXMLTemp('</elec1:PrepaidPayment>');
            until SalesInvLine.NEXT = 0;
            AddLineXMLTemp('</elec:lPrepaidPayment>');
        end;
    end;

    local procedure TotalSaleValueXMLPart()
    var
        TaxBase: Decimal;
        TotalAmtDiscount: Decimal;
        PercentageAmt: Decimal;
        TotalDiscountLine: Decimal;
        ReasonCode: Code[10];
    begin
        GetGlobalDiscount(TaxBase, TotalAmtDiscount, PercentageAmt, ReasonCode);
        if Invoice or Ticket then begin
            if (Invoice or Ticket) and ((TotalAmtDiscount <> 0)) then begin
                AddLineXMLTemp('<elec:eAllowancecharge>');
                if SalesInvHeader."Final Advanced" then
                    AddLineXMLTemp(CreateXMLTag('elec1:AllowanceChargeReasonCode', Format(04)))
                else
                    AddLineXMLTemp(CreateXMLTag('elec1:AllowanceChargeReasonCode', Format(ReasonCode)));
                AddLineXMLTemp(CreateXMLTag('elec1:Amount', FormatNumber(TotalAmtDiscount)));
                AddLineXMLTemp(CreateXMLTag('elec1:Amount_currencyID', GetCurrencyCode(SalesInvHeader."Currency Code")));
                AddLineXMLTemp(CreateXMLTag('elec1:BaseAmount', FormatNumber(TaxBase)));
                AddLineXMLTemp(CreateXMLTag('elec1:ChargeIndicator', '<![CDATA[false]]>'));
                AddLineXMLTemp(CreateXMLTag('elec1:MultiplierFactorNumeric', Format(Round(TotalAmtDiscount / TaxBase, 0.0001), 0, '<Precision,5:5><Standard Format,2>')));
                AddLineXMLTemp('</elec:eAllowancecharge>');
            end;
            if (Invoice or Ticket) and (SalesInvHeader."Final Advanced") then begin
                SalesInvLine.Reset;
                SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
                SalesInvLine.SetFilter("EB No. Invoice Advanced", '<>%1', '');
                if SalesInvLine.FindFirst then begin
                    TotalAmtDiscount := SalesInvLine.Amount;
                    TotalAmtDiscount := Abs(TotalAmtDiscount);
                end;
                AddLineXMLTemp('<elec:eAllowancecharge>');
                if SalesInvHeader."Final Advanced" then
                    AddLineXMLTemp(CreateXMLTag('elec1:AllowanceChargeReasonCode', '04'))
                else
                    AddLineXMLTemp(CreateXMLTag('elec1:AllowanceChargeReasonCode', Format(ReasonCode)));
                AddLineXMLTemp(CreateXMLTag('elec1:Amount', FormatNumber(TotalAmtDiscount)));
                AddLineXMLTemp(CreateXMLTag('elec1:Amount_currencyID', GetCurrencyCode(SalesInvHeader."Currency Code")));
                AddLineXMLTemp(CreateXMLTag('elec1:BaseAmount', FormatNumber(TaxBase)));
                AddLineXMLTemp(CreateXMLTag('elec1:ChargeIndicator', '<![CDATA[false]]>'));
                AddLineXMLTemp(CreateXMLTag('elec1:MultiplierFactorNumeric', Format(Round(TotalAmtDiscount / TaxBase, 0.0001), 0, '<Precision,5:5><Standard Format,2>')));
                AddLineXMLTemp('</elec:eAllowancecharge>');
            end;
            GetTotalAmtDiscountLine(TaxBase, TotalDiscountLine);
            AddLineXMLTemp('<elec:eLegalMonetaryTotal>');
            if SalesInvHeader."Final Advanced" then
                AddLineXMLTemp(CreateXMLTag('elec1:AllowanceTotalAmount', FormatNumber(0)))
            else
                AddLineXMLTemp(CreateXMLTag('elec1:AllowanceTotalAmount', FormatNumber(TotalAmtDiscount + TotalDiscountLine))); //Total de Descuentos.  
            AddLineXMLTemp(CreateXMLTag('elec1:CharGetotalAmount', FormatNumber(0))); //Sumatoria otros Cargos
            AddLineXMLTemp(CreateXMLTag('elec1:LegalMonetaryTotal_currencyID', GetCurrencyCode(SalesInvHeader."Currency Code")));
            AddLineXMLTemp(CreateXMLTag('elec1:LineExtensionAmount', FormatNumber(GetTotalGrossSellingValue))); //Total Valor de Venta sin IGV
            if SalesInvHeader."FT Free Title" then
                AddLineXMLTemp(CreateXMLTag('elec1:PayableAmount', FormatNumber(0))) //Importe total de la venta incluido IGV 
            else
                AddLineXMLTemp(CreateXMLTag('elec1:PayableAmount', FormatNumber(SalesInvHeader."Amount Including VAT"))); //Importe total de la venta incluido IGV 
            AddLineXMLTemp(CreateXMLTag('elec1:PayableRoundingAmount', Format(0)));
            if GetTotalPrePaidPaymentAmount <> 0 then
                AddLineXMLTemp(CreateXMLTag('elec1:PrepaidAmount', FormatNumber(GetTotalPrePaidPaymentAmount)));
            if SalesInvHeader."FT Free Title" then
                AddLineXMLTemp(CreateXMLTag('elec1:TaxInclusiveAmount', FormatNumber(0))) //Total Precio de Venta.
            else
                if GetTotalPrePaidPaymentAmount <> 0 then
                    AddLineXMLTemp(CreateXMLTag('elec1:TaxInclusiveAmount', FormatNumber(GetTotalPrePaidPaymentAmount)))
                else
                    AddLineXMLTemp(CreateXMLTag('elec1:TaxInclusiveAmount', FormatNumber(SalesInvHeader."Amount Including VAT"))); //Total Precio de Venta.
            AddLineXMLTemp('</elec:eLegalMonetaryTotal>');
        end;

        if CreditNote then begin
            GetTotalAmtDiscountLine(TaxBase, TotalDiscountLine);
            AddLineXMLTemp('<elec:eLegalMonetaryTotal>');
            AddLineXMLTemp(CreateXMLTag('elec1:AllowanceTotalAmount', FormatNumber(TotalAmtDiscount + TotalDiscountLine))); //Total de Descuentos.  
            AddLineXMLTemp(CreateXMLTag('elec1:CharGetotalAmount', FormatNumber(0))); //Sumatoria otros Cargos
            AddLineXMLTemp(CreateXMLTag('elec1:LegalMonetaryTotal_currencyID', GetCurrencyCode(SalesCrMemoHdr."Currency Code")));
            AddLineXMLTemp(CreateXMLTag('elec1:LineExtensionAmount', FormatNumber(GetTotalGrossSellingValue))); //Total Valor de Venta sin IGV
            if SalesCrMemoHdr."FT Free Title" then
                AddLineXMLTemp(CreateXMLTag('elec1:PayableAmount', FormatNumber(0))) //Importe total de la venta incluido IGV
            else
                AddLineXMLTemp(CreateXMLTag('elec1:PayableAmount', FormatNumber(SalesCrMemoHdr."Amount Including VAT"))); //Importe total de la venta incluido IGV 
            AddLineXMLTemp(CreateXMLTag('elec1:PayableRoundingAmount', Format(0)));
            if GetTotalPrePaidPaymentAmount <> 0 then
                AddLineXMLTemp(CreateXMLTag('elec1:PrepaidAmount', Format(GetTotalPrePaidPaymentAmount)));
            if SalesCrMemoHdr."FT Free Title" then
                AddLineXMLTemp(CreateXMLTag('elec1:TaxInclusiveAmount', FormatNumber(0))) //Total Precio de Venta.
            else
                AddLineXMLTemp(CreateXMLTag('elec1:TaxInclusiveAmount', FormatNumber(SalesCrMemoHdr."Amount Including VAT"))); //Total Precio de Venta.
            AddLineXMLTemp('</elec:eLegalMonetaryTotal>');
        end;

        if DebitNote then begin
            AddLineXMLTemp('<elec:eRequestedMonetaryTotal>');
            AddLineXMLTemp(CreateXMLTag('elec1:charGetotalAmount', FormatNumber(SalesInvHeader."Invoice Discount Amount")));
            AddLineXMLTemp(CreateXMLTag('elec1:payableAmount', FormatNumber(SalesInvHeader."Amount Including VAT")));
            AddLineXMLTemp('</elec:eRequestedMonetaryTotal>');
        end;
    end;

    local procedure GetGlobalDiscount(var TaxBase: Decimal; var AmtDiscount: Decimal; var PercentageAmt: Decimal; var ReasonCode: Code[10])
    begin
        Clear(TaxBase);
        Clear(AmtDiscount);
        Clear(PercentageAmt);
        Clear(ReasonCode);
        if CreditNote then begin
            SalesCrMemoLine.Reset;
            SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHdr."No.");
            SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
            SalesCrMemoLine.SetFilter(Quantity, '>%1', 0);
            if SalesCrMemoLine.FindSet then begin
                repeat
                    if SalesCrMemoHdr."Prices Including VAT" then
                        AmtDiscount += Round(SalesCrMemoLine."Inv. Discount Amount" / (1 + SalesCrMemoLine."VAT %" / 100), 0.01)
                    else
                        AmtDiscount += SalesCrMemoLine."Inv. Discount Amount";
                    TaxBase += SalesCrMemoLine."Line Amount";
                until SalesCrMemoLine.NEXT = 0;
            end;
            ReasonCode := SalesCrMemoHdr."EB Charge/Discount Code";//  " EB Charges Code or Discounts Code";
        end else begin
            SalesInvLine.Reset;
            SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
            SalesInvLine.SetFilter(Type, '<>%1', SalesInvLine.Type::" ");
            SalesInvLine.SetFilter(Quantity, '>%1', 0);
            if SalesInvLine.FindSet then begin
                repeat
                    if SalesInvHeader."Prices Including VAT" then
                        AmtDiscount += Round(SalesInvLine."Inv. Discount Amount" / (1 + SalesInvLine."VAT %" / 100), 0.01)
                    else
                        AmtDiscount += SalesInvLine."Inv. Discount Amount";
                    TaxBase += SalesInvLine."Line Amount";
                until SalesInvLine.NEXT = 0;
            end;
            ReasonCode := SalesInvHeader."EB Charge/Discount Code";
        end;
        //TaxBase := TaxBase + AmtDiscount;
        if AmtDiscount <> 0 then
            PercentageAmt := Round((AmtDiscount / TaxBase) * 100, 0.01)
    end;

    local procedure GetTotalAmtDiscountLine(var TaxBase: Decimal; var DiscountAmount: Decimal)
    begin
        Clear(TaxBase);
        Clear(DiscountAmount);
        if CreditNote then begin
            SalesCrMemoLine.Reset;
            SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHdr."No.");
            SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
            SalesCrMemoLine.SetFilter(Quantity, '>%1', 0);
            SalesCrMemoLine.SetFilter("Line Discount Amount", '<>%1', 0);
            if SalesCrMemoLine.FindFirst() then begin
                repeat
                    if SalesCrMemoHdr."Prices Including VAT" then
                        DiscountAmount := DiscountAmount + Round(SalesCrMemoLine."Line Discount Amount" / (1 + SalesCrMemoLine."VAT %" / 100), 0.01)
                    else
                        DiscountAmount := DiscountAmount + SalesCrMemoLine."Line Discount Amount";
                    TaxBase := TaxBase + SalesCrMemoLine."Line Amount";
                until SalesCrMemoLine.NEXT = 0;
            end;
        end else begin
            SalesInvLine.Reset;
            SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
            SalesInvLine.SetFilter(Type, '<>%1', SalesInvLine.Type::" ");
            SalesInvLine.SetFilter(Quantity, '>%1', 0);
            SalesInvLine.SetFilter("Line Discount Amount", '<>%1', 0);
            if SalesInvLine.FindSet then begin
                repeat
                    if SalesInvHeader."Prices Including VAT" then
                        DiscountAmount := DiscountAmount + Round(SalesInvLine."Line Discount Amount" / (1 + SalesInvLine."VAT %" / 100), 0.01)
                    else
                        DiscountAmount := DiscountAmount + SalesInvLine."Line Discount Amount";
                    TaxBase := TaxBase + SalesInvLine."Line Amount";
                until SalesInvLine.NEXT = 0;
            end;
        end;
        TaxBase := TaxBase + DiscountAmount;
    end;

    local procedure GetTotalGrossSellingValue(): Decimal
    var
        GrossSaleValue: Decimal;
    begin
        Clear(GrossSaleValue);
        if CreditNote then begin
            SalesCrMemoLine.Reset;
            SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHdr."No.");
            SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
            SalesCrMemoLine.SetFilter(Quantity, '>%1', 0);
            if SalesCrMemoLine.FINDSET then begin
                repeat
                    if GetTaxTypeCode(SalesCrMemoLine."VAT Bus. Posting Group", SalesCrMemoLine."VAT Prod. Posting Group") IN ['1000', '1016', '9995', '9997', '9998'] then begin
                        if SalesCrMemoHdr."Prices Including VAT" then
                            GrossSaleValue := GrossSaleValue + Round((SalesCrMemoLine.Amount + SalesCrMemoLine."Line Discount Amount") / (1 + SalesCrMemoLine."VAT %" / 100), 0.01)
                        else
                            GrossSaleValue := GrossSaleValue + (SalesCrMemoLine.Amount + SalesCrMemoLine."Line Discount Amount");
                        //GrossSaleValue := GrossSaleValue + SalesCrMemoLine."VAT Base Amount";
                    end;
                until SalesCrMemoLine.NEXT = 0;
            end;
        end else begin
            SalesInvLine.Reset;
            SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
            SalesInvLine.SetFilter(Type, '<>%1', SalesInvLine.Type::" ");
            SalesInvLine.SetFilter(Quantity, '>%1', 0);
            if SalesInvLine.FINDSET then begin
                repeat
                    if GetTaxTypeCode(SalesInvLine."VAT Bus. Posting Group", SalesInvLine."VAT Prod. Posting Group") IN ['1000', '1016', '9995', '9997', '9998'] then begin
                        if SalesInvHeader."Prices Including VAT" then
                            GrossSaleValue := Round((SalesInvLine.Amount + SalesInvLine."Line Discount Amount") / (1 + SalesInvLine."VAT %" / 100), 0.01)
                        else
                            GrossSaleValue := (SalesInvLine.Amount + SalesInvLine."Line Discount Amount");
                        //GrossSaleValue := GrossSaleValue + SalesInvLine."VAT Base Amount";
                    end;
                until SalesInvLine.NEXT = 0;
            end;
        end;
        exit(GrossSaleValue);
    end;

    local procedure GetTaxTypeCode(VATBusPostingGroup: Code[10]; VATProdPostingGroup: Code[10]): Code[10]
    begin
        if VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup) then
            exit(VATPostingSetup."EB Tax Type Code");
        exit('');
    end;

    local procedure NormalizeRUC(pRuc: Text): Text
    var
        PermisionCharacter: Label '1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ-';
    begin
        exit(DelChr(pRuc, '=', DelChr(pRuc, '=', PermisionCharacter)));
    end;

    local procedure GetTotalPrePaidPaymentAmount(): Decimal
    var
        TotalPrePaidAmt: Decimal;
    begin
        Clear(TotalPrePaidAmt);
        if not (Invoice or Ticket) then
            exit(0);
        if not SalesInvHeader."Final Advanced" then
            exit(0);
        //SalesInvLine."EB No. Invoice Advanced"

        SalesInvLine.Reset;
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        SalesInvLine.SetFilter("EB No. Invoice Advanced", '<>%1', '');
        if SalesInvLine.FindFirst() then
            repeat
                TotalPrePaidAmt += Abs(SalesInvLine."Amount Including VAT");
            until SalesInvLine.NEXT = 0;
        exit(TotalPrePaidAmt);
    end;

    local procedure TotalTaxAmtXMLPart()
    var
        TaxableAmount: Decimal;
        TaxAmount: Decimal;
    begin
        AddLineXMLTemp('<elec:lTaxTotal>');
        AddLineXMLTemp('<elec1:TaxTotal>');

        GetTotalAmtTaxTypeCode(TaxableAmount, TaxAmount);
        AddLineXMLTemp(CreateXMLTag('elec1:TaxAmount', FormatNumber(TaxAmount)));
        AddLineXMLTemp('<elec1:eTaxSubtotal>');

        CatalogoSunat.Reset;
        CatalogoSunat.SetRange("Option Type", CatalogoSunat."Option Type"::"Catalogue SUNAT");
        CatalogoSunat.SetRange("Type Code", '05');
        if CatalogoSunat.FindFirst() then
            repeat
                if GetAmtTaxTypeCode(CatalogoSunat."Legal No.", TaxableAmount, TaxAmount) then begin
                    if SalesInvHeader."Final Advanced" then begin
                        TaxAmount := 0;
                        TaxableAmount := 0;
                    end;
                    AddLineXMLTemp('<elec2:TaxSubtotal>');
                    if CreditNote then
                        AddLineXMLTemp(CreateXMLTag('elec2:currencyID', GetCurrencyCode(SalesCrMemoHdr."Currency Code")))
                    else
                        AddLineXMLTemp(CreateXMLTag('elec2:currencyID', GetCurrencyCode(SalesInvHeader."Currency Code")));
                    AddLineXMLTemp(CreateXMLTag('elec2:TaxAmount', FormatNumber(TaxAmount)));
                    AddLineXMLTemp(CreateXMLTag('elec2:TaxableAmount', FormatNumber(TaxableAmount)));
                    AddLineXMLTemp('<elec2:eTaxCategory>');
                    AddLineXMLTemp('<elec3:eTaxScheme>');
                    AddLineXMLTemp(CreateXMLTag('elec4:ID', CatalogoSunat."Legal No."));
                    AddLineXMLTemp(CreateXMLTag('elec4:Name', CatalogoSunat."Alternative Code"));
                    AddLineXMLTemp(CreateXMLTag('elec4:TaxAmount', FormatNumber(TaxAmount)));
                    AddLineXMLTemp(CreateXMLTag('elec4:TaxTypeCode', CatalogoSunat."Generic Code"));
                    AddLineXMLTemp('</elec3:eTaxScheme>');
                    AddLineXMLTemp('</elec2:eTaxCategory>');
                    AddLineXMLTemp('</elec2:TaxSubtotal>');
                end;
            until CatalogoSunat.NEXT = 0;
        AddLineXMLTemp('</elec1:eTaxSubtotal>');
        AddLineXMLTemp('</elec1:TaxTotal>');
        AddLineXMLTemp('</elec:lTaxTotal>');
    end;

    local procedure GetTotalAmtTaxTypeCode(var TaxableAmount: Decimal; var TaxAmount: Decimal)
    begin
        //fnGetTotalAmountTributeTypeCode
        Clear(TaxableAmount);
        Clear(TaxAmount);
        if CreditNote then begin
            SalesCrMemoLine.Reset;
            SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHdr."No.");
            SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
            //SalesCrMemoLine.SetRange("Free Title Line",FALSE);
            if SalesCrMemoLine.FINDSET then begin
                repeat
                    if VATPostingSetup.Get(SalesCrMemoLine."VAT Bus. Posting Group", SalesCrMemoLine."VAT Prod. Posting Group")
                       and (VATPostingSetup."EB Tax Type Code" <> '') then begin
                        if VATPostingSetup."EB Tax Type Code" IN ['1000', '1016', '2000'] then begin
                            TaxableAmount += SalesCrMemoLine.Amount;
                            TaxAmount += SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine.Amount;
                        end;
                    end;
                until SalesCrMemoLine.NEXT = 0;
            end;
        end else begin
            SalesInvLine.Reset;
            SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
            SalesInvLine.SetFilter(Type, '<>%1', SalesInvLine.Type::" ");
            //SalesInvLine.SetRange("Free Title Line",FALSE);
            if SalesInvLine.FINDSET then begin
                repeat
                    if VATPostingSetup.Get(SalesInvLine."VAT Bus. Posting Group", SalesInvLine."VAT Prod. Posting Group")
                         and (VATPostingSetup."EB Tax Type Code" <> '') then begin
                        if VATPostingSetup."EB Tax Type Code" IN ['1000', '1016', '2000'] then begin
                            TaxableAmount += SalesInvLine.Amount;
                            TaxAmount += SalesInvLine."Amount Including VAT" - SalesInvLine.Amount;
                        end;
                    end;
                until SalesInvLine.NEXT = 0;
            end;
        end;
    end;

    local procedure GetAmtTaxTypeCode(LegalNo: Code[20]; var TaxableAmount: Decimal; var TaxAmount: Decimal): Boolean
    var
        ExistsTaxAmtTotalStatus: Boolean;
    begin
        //fnGetAmountTributeTypeCode
        Clear(TaxableAmount);
        Clear(TaxAmount);
        Clear(ExistsTaxAmtTotalStatus);
        if CreditNote then begin
            SalesCrMemoLine.Reset;
            SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHdr."No.");
            SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
            SalesCrMemoLine.SetFilter(Quantity, '>%1', 0);
            //SalesCrMemoLine.SetRange("Free Title Line",FALSE);
            if SalesCrMemoLine.FINDSET then
                repeat
                    if VATPostingSetup.GET(SalesCrMemoLine."VAT Bus. Posting Group", SalesCrMemoLine."VAT Prod. Posting Group")
                       and (VATPostingSetup."EB Tax Type Code" <> '') then
                        if VATPostingSetup."EB Tax Type Code" = LegalNo then begin
                            TaxableAmount += SalesCrMemoLine.Amount;
                            TaxAmount += SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine.Amount;
                            ExistsTaxAmtTotalStatus := true;
                        end;
                until SalesCrMemoLine.NEXT = 0;
        end else begin
            SalesInvLine.Reset;
            SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
            SalesInvLine.SetFilter(Type, '<>%1', SalesInvLine.Type::" ");
            //if SalesInvHeader."Factura final anticipo" then
            //    SalesInvLine.SetFilter(Quantity, '<>%1', 0)
            //else
            SalesInvLine.SetFilter(Quantity, '>%1', 0);
            //SalesInvLine.SetRange("Free Title Line",FALSE);
            if SalesInvLine.FINDSET then
                repeat
                    if VATPostingSetup.GET(SalesInvLine."VAT Bus. Posting Group", SalesInvLine."VAT Prod. Posting Group")
                         and (VATPostingSetup."EB Tax Type Code" <> '') then
                        if VATPostingSetup."EB Tax Type Code" = LegalNo then begin
                            TaxableAmount += SalesInvLine.Amount;
                            TaxAmount += SalesInvLine."Amount Including VAT" - SalesInvLine.Amount;
                            ExistsTaxAmtTotalStatus := true;
                        end;
                until SalesInvLine.NEXT = 0;
        end;
        exit(ExistsTaxAmtTotalStatus);
    end;

    local procedure GetCatalogoDescription(LegalNo: Code[10]; TypeCode: Code[10]): Text
    begin
        CatalogoSunat.Reset();
        CatalogoSunat.SetRange("Option Type", CatalogoSunat."Option Type"::"Catalogue SUNAT");
        CatalogoSunat.SetRange("Type Code", TypeCode);
        CatalogoSunat.SetRange("Legal No.", LegalNo);
        if CatalogoSunat.FindFirst() then
            exit(CatalogoSunat.Description);
        exit('');
    end;

    local procedure DetailedInvoiceTicketXMLPart()
    var
        LineNo: Integer;
        PriceAmountDec: Decimal;
        PriceIncludeVAT: Decimal;
        UnitDiscount: Decimal;
        LineAmountDecimal: Decimal;
        DsctoUnit: Decimal;
    begin
        if not (Invoice or Ticket) then
            exit;
        LineNo := 0;
        SalesInvLine.Reset;
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        SalesInvLine.SetFilter(Type, '<>%1', SalesInvLine.Type::" ");
        SalesInvLine.SetFilter(Quantity, '>%1', 0);
        //SalesInvLine.SetFilter("No. factura anticipo", '%1', '');
        //SalesInvLine.SetRange("Free Title Line",FALSE);
        if SalesInvLine.FindFirst() then begin
            AddLineXMLTemp('<elec:lInvoiceLine>');
            repeat
                LineNo += 1;
                PriceIncludeVAT := 0;
                UnitDiscount := 0;
                PriceAmountDec := 0;
                LineAmountDecimal := 0;
                //NumGuiaHeader := '';
                //NumGuiaHeader := SalesInvLine."Shipment No.";
                VATPostingSetup.GET(SalesInvLine."VAT Bus. Posting Group", SalesInvLine."VAT Prod. Posting Group");

                CatalogoSunat.Reset;
                CatalogoSunat.SetRange("Option Type", CatalogoSunat."Option Type"::"Catalogue SUNAT");
                CatalogoSunat.SetRange("Type Code", '05');
                CatalogoSunat.SetRange("Legal No.", VATPostingSetup."EB Tax Type Code");
                if CatalogoSunat.FindFirst() then;
                AddLineXMLTemp('<elec1:InvoiceLine>');
                AddLineXMLTemp(CreateXMLTag('elec1:ID', Format(LineNo)));  //Número de orden del Ítem.
                AddLineXMLTemp(CreateXMLTag('elec1:InvoicedQuantity', FormatNumber(SalesInvLine.Quantity))); //Cantidad y Unidad de Medida por ítem.
                //++ ULN::RRR BEGIN 06/11/2020
                if (SalesInvLine."Inv. Discount Amount" <> 0) or (SalesInvLine."Line Discount Amount" <> 0) then begin
                    if (SalesInvLine."Line Discount Amount" <> 0) then begin
                        UnitDiscount := Round(SalesInvLine."Line Discount Amount" / SalesInvLine.Quantity);
                        PriceAmountDec := Round((SalesInvLine."Unit Price" - UnitDiscount) * (1 + SalesInvLine."VAT %" / 100));
                    end else begin
                        UnitDiscount := Round(SalesInvLine."Inv. Discount Amount" / SalesInvLine.Quantity);
                        PriceAmountDec := Round((SalesInvLine."Unit Price" - UnitDiscount) * (1 + SalesInvLine."VAT %" / 100));
                    end;
                    LineAmountDecimal := PriceAmountDec * SalesInvLine.Quantity;
                    AddLineXMLTemp(CreateXMLTag('elec1:LineExtensionAmount', FormatNumber(LineAmountDecimal))); //Valor de venta por ítem
                end else //++ ULN::RRR END 06/11/2020
                    AddLineXMLTemp(CreateXMLTag('elec1:LineExtensionAmount', FormatNumber(SalesInvLine.Amount))); //Valor de venta por ítem
                AddLineXMLTemp(CreateXMLTag('elec1:currencyID', GetCurrencyCode(SalesInvHeader."Currency Code")));
                if SalesInvLine."Line Discount Amount" <> 0 then begin //Descuento en linea
                    AddLineXMLTemp('<elec1:eAllowancecharge>');
                    AddLineXMLTemp(CreateXMLTag('elec2:chargeIndicator', '<![CDATA[false]]>'));
                    AddLineXMLTemp(CreateXMLTag('elec2:AllowanceChargeReasonCode', SalesInvLine."EB Motive discount code"));
                    AddLineXMLTemp(CreateXMLTag('elec2:MultiplierFactorNumeric', FormatNumber(Round(SalesInvLine."Line Discount Amount" / (SalesInvLine.Amount + SalesInvLine."Line Discount Amount"), 0.001, '='))));
                    AddLineXMLTemp(CreateXMLTag('elec2:BaseAmount', FormatNumber(SalesInvLine.Amount + SalesInvLine."Line Discount Amount")));
                    AddLineXMLTemp(CreateXMLTag('elec2:amount', FormatNumber(SalesInvLine."Line Discount Amount")));
                    AddLineXMLTemp(CreateXMLTag('elec2:currencyID', GetCurrencyCode(SalesInvHeader."Currency Code")));
                    AddLineXMLTemp('</elec1:eAllowancecharge>');
                end;
                AddLineXMLTemp('<elec1:eItem>');
                AddLineXMLTemp(CreateXMLTag('elec2:Description', '<![CDATA[' + SalesInvLine.Description + SalesInvLine."Description 2" + ']]>'));
                if GetLegalItemCode(SalesInvLine."No.", SalesInvLine.Type) <> '' then
                    AddLineXMLTemp(CreateXMLTag('elec2:eCommodityClassification', CreateXMLTag('elec3:ItemClassificationCode', GetLegalItemCode(SalesInvLine."No.", SalesInvLine.Type))));
                //if SalesInvLine.  "Standard Sales Code" <> '' then SalesLine.
                //    AddLineXMLTemp(CreateXMLTag('elec2:eSellersItemIdentification', CreateXMLTag('elec3:ID', SalesInvLine."Standard Sales Code")))
                //else
                if SalesInvLine."Standard Sales Code" <> '' then
                    AddLineXMLTemp(CreateXMLTag('elec2:eSellersItemIdentification', CreateXMLTag('elec3:ID', SalesInvLine."Standard Sales Code")))
                else
                    AddLineXMLTemp(CreateXMLTag('elec2:eSellersItemIdentification', CreateXMLTag('elec3:ID', SalesInvLine."No.")));
                AddLineXMLTemp('</elec1:eItem>');
                AddLineXMLTemp('<elec1:ePrice>');
                if (SalesInvLine."VAT Bus. Posting Group" = LSetup."FT VAT Bus. Posting Group") then
                    // if SalesInvHeader."Free Title" then
                    //end ULN::KFA 001 2020.05.22 ++
                    AddLineXMLTemp(CreateXMLTag('elec2:PriceAmount', FormatNumber(0)))
                else
                    //++ BEGIN ULN::RRR Descuentos globales 06/11/2020
                    begin
                    if (SalesInvLine."Line Discount Amount" <> 0) then begin
                        UnitDiscount := Round(SalesInvLine."Line Discount Amount" / SalesInvLine.Quantity);
                        PriceAmountDec := Round((SalesInvLine."Unit Price" - UnitDiscount) * (1 + SalesInvLine."VAT %" / 100));
                        //PriceAmountDec := PriceIncludeVAT - UnitDiscount;
                        //PriceAmountDec := Round((SalesInvLine."Amount Including VAT" - SalesInvLine."Line Discount Amount") / SalesInvLine.Quantity, 0.01);
                    end else begin
                        UnitDiscount := Round(SalesInvLine."Inv. Discount Amount" / SalesInvLine.Quantity);
                        PriceAmountDec := Round((SalesInvLine."Unit Price" - UnitDiscount) * (1 + SalesInvLine."VAT %" / 100));
                        //PriceAmountDec := PriceIncludeVAT - UnitDiscount;
                        //PriceAmountDec := Round((SalesInvLine."Amount Including VAT" - SalesInvLine."Inv. Discount Amount") / SalesInvLine.Quantity, 0.01);
                    end;
                    AddLineXMLTemp(CreateXMLTag('elec2:PriceAmount', FormatNumber(SalesInvLine."Unit Price")));//Sin inc. igv
                    //AddLineXMLTemp(CreateXMLTag('elec2:PriceAmount', FormatNumber(PriceAmountDec)));
                end;
                //++ ULN::RRR Descuentos globales 06/11/2020

                //AddLineXMLTemp(CreateXMLTag('elec2:PriceAmountIncVAT',FormatNumber(Round(SalesInvLine."Unit Price"*(1 + SalesInvLine."VAT %"/100))))); 
                AddLineXMLTemp(CreateXMLTag('elec2:currencyID', GetCurrencyCode(SalesInvHeader."Currency Code")));
                AddLineXMLTemp('</elec1:ePrice>');
                AddLineXMLTemp('<elec1:ePricingReference>');
                AddLineXMLTemp('<elec2:lAlternativeConditionPrice>');
                AddLineXMLTemp('<elec3:AlternativeConditionPrice>');
                if (SalesInvLine."VAT Bus. Posting Group" = LSetup."FT VAT Bus. Posting Group") then
                    AddLineXMLTemp(CreateXMLTag('elec3:PriceAmount', FormatNumber(SalesInvLine."Unit Price"))) //Precio de venta unitario por ítem y código
                else begin
                    fnGetPriceAmountWithoutDscto(SalesInvLine."Line Discount Amount", SalesInvLine.Quantity, DsctoUnit);
                    AddLineXMLTemp(CreateXMLTag('elec3:PriceAmount', FormatNumber((SalesInvLine."Unit Price" - DsctoUnit) * ((100 + SalesInvLine."VAT %") / 100)))); //Precio de venta unitario por ¡tem y c¢digo
                end;
                if (SalesInvLine."VAT Bus. Posting Group" = LSetup."FT VAT Bus. Posting Group") then
                    AddLineXMLTemp(CreateXMLTag('elec3:PriceTypeCode', '02')) //Valor referencial unitario por ¡tem en operaciones no onerosas
                else
                    AddLineXMLTemp(CreateXMLTag('elec3:PriceTypeCode', '01')); //Valor referencial unitario por ítem en operaciones no onerosas 
                AddLineXMLTemp(CreateXMLTag('elec1:currencyID', GetCurrencyCode(SalesInvHeader."Currency Code")));
                AddLineXMLTemp('</elec3:AlternativeConditionPrice>');
                AddLineXMLTemp('</elec2:lAlternativeConditionPrice>');
                AddLineXMLTemp('</elec1:ePricingReference>');
                AddLineXMLTemp('<elec1:lTaxTotal>');
                AddLineXMLTemp('<elec1:TaxTotal>');
                AddLineXMLTemp(CreateXMLTag('elec1:TaxAmount', FormatNumber(SalesInvLine."Amount Including VAT" - SalesInvLine.Amount)));
                AddLineXMLTemp('<elec1:eTaxSubtotal>');
                AddLineXMLTemp('<elec2:TaxSubtotal>');
                AddLineXMLTemp(CreateXMLTag('elec2:currencyID', GetCurrencyCode(SalesInvHeader."Currency Code")));
                AddLineXMLTemp(CreateXMLTag('elec2:TaxAmount', FormatNumber(SalesInvLine."Amount Including VAT" - SalesInvLine.Amount)));
                AddLineXMLTemp(CreateXMLTag('elec2:TaxableAmount', FormatNumber(SalesInvLine.Amount)));
                AddLineXMLTemp('<elec2:eTaxCategory>');
                //AddLineXMLTemp(CreateXMLTag('elec3:ID', CatalogoSunat."Alternative Code"));
                AddLineXMLTemp(CreateXMLTag('elec3:ID', CatalogoSunat."UN ECE 5305"));//ULN::RRR 25/10/2020
                AddLineXMLTemp(CreateXMLTag('elec3:Percent', FormatNumber(SalesInvLine."VAT %")));
                AddLineXMLTemp(CreateXMLTag('elec3:TaxExemptionReasonCode', VATPostingSetup."EB VAT Type Affectation"));
                AddLineXMLTemp('<elec3:eTaxScheme>');
                AddLineXMLTemp(CreateXMLTag('elec4:ID', CatalogoSunat."Legal No."));
                AddLineXMLTemp(CreateXMLTag('elec4:Name', CatalogoSunat."Alternative Code"));
                AddLineXMLTemp(CreateXMLTag('elec4:TaxAmount', FormatNumber(SalesInvLine."Amount Including VAT" - SalesInvLine.Amount)));
                AddLineXMLTemp(CreateXMLTag('elec4:TaxTypeCode', CatalogoSunat."Generic Code"));
                AddLineXMLTemp('</elec3:eTaxScheme>');
                AddLineXMLTemp('</elec2:eTaxCategory>');
                AddLineXMLTemp('</elec2:TaxSubtotal>');
                AddLineXMLTemp('</elec1:eTaxSubtotal>');
                AddLineXMLTemp('</elec1:TaxTotal>');
                AddLineXMLTemp('</elec1:lTaxTotal>');
                AddLineXMLTemp(CreateXMLTag('elec1:unitCode', GetUnitOfMeasure(SalesInvLine."Unit of Measure Code")));
                AddLineXMLTemp('</elec1:InvoiceLine>');
            until SalesInvLine.NEXT = 0;
            AddLineXMLTemp('</elec:lInvoiceLine>');
        end;
    end;

    local procedure DetailedCreditNoteXMLPart()
    var
        LineNo: Integer;
    begin
        if not CreditNote then
            exit;

        SalesCrMemoLine.Reset;
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHdr."No.");
        SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
        SalesCrMemoLine.SetFilter(Quantity, '>%1', 0);
        //SalesCrMemoLine.SetRange("Free Title Line",FALSE);
        if SalesCrMemoLine.FindFirst() then begin
            AddLineXMLTemp('<elec:lCreditNoteLine>');
            repeat
                LineNo += 1;
                VATPostingSetup.GET(SalesCrMemoLine."VAT Bus. Posting Group", SalesCrMemoLine."VAT Prod. Posting Group");

                CatalogoSunat.Reset;
                CatalogoSunat.SetRange("Option Type", CatalogoSunat."Option Type"::"Catalogue SUNAT");
                CatalogoSunat.SetRange("Type Code", '05');
                CatalogoSunat.SetRange("Legal No.", VATPostingSetup."EB Tax Type Code");
                if CatalogoSunat.FindFirst() then;

                AddLineXMLTemp('<elec1:CreditNoteLine>');
                AddLineXMLTemp(CreateXMLTag('elec1:id', Format(LineNo)));
                AddLineXMLTemp(CreateXMLTag('elec1:unitCode', GetUnitOfMeasure(SalesCrMemoLine."Unit of Measure Code")));
                AddLineXMLTemp(CreateXMLTag('elec1:creditNoteQuantity', FormatNumber(SalesCrMemoLine.Quantity)));
                AddLineXMLTemp(CreateXMLTag('elec1:lineExtensionAmount', FormatNumber(SalesCrMemoLine.Amount)));
                AddLineXMLTemp('<elec1:ePricingReference>');
                AddLineXMLTemp('<elec2:lAlternativeConditionPrice>');
                AddLineXMLTemp('<elec3:AlternativeConditionPrice>');
                //AddLineXMLTemp(CreateXMLTag('elec3:PriceAmount',FormatNumber(SalesCrMemoLine."Unit Price"))); //Precio de venta unitario por ítem
                AddLineXMLTemp(CreateXMLTag('elec3:PriceAmount', FormatNumber(SalesCrMemoLine."Unit Price"))); //Precio de venta unitario por ítem
                                                                                                               //AddLineXMLTemp(CreateXMLTag('elec3:PriceTypeCode', '01')); //Valor referencial unitario por ítem en operaciones no onerosas 
                if (SalesCrMemoLine."VAT Bus. Posting Group" = LSetup."FT VAT Bus. Posting Group") then
                    AddLineXMLTemp(CreateXMLTag('elec3:PriceTypeCode', '02')) //Valor referencial unitario por ¡tem en operaciones no onerosas
                else
                    AddLineXMLTemp(CreateXMLTag('elec3:PriceTypeCode', '01')); //Valor referencial unitario por ítem en operaciones no onerosas 
                AddLineXMLTemp(CreateXMLTag('elec3:currencyID', GetCurrencyCode(SalesCrMemoHdr."Currency Code")));
                AddLineXMLTemp('</elec3:AlternativeConditionPrice>');
                AddLineXMLTemp('</elec2:lAlternativeConditionPrice>');
                AddLineXMLTemp('</elec1:ePricingReference>');
                AddLineXMLTemp('<elec1:lTaxTotal>');
                AddLineXMLTemp('<elec1:TaxTotal>');
                //begin ULN::KFA 001 2020.05.22 ++    
                if GetTaxTypeCode(SalesCrMemoLine."VAT Bus. Posting Group", SalesCrMemoLine."VAT Prod. Posting Group") = '9996' then
                    AddLineXMLTemp(CreateXMLTag('elec1:TaxAmount', FormatNumber(0)))
                else
                    //end ULN::KFA 001 2020.05.22 ++
                    AddLineXMLTemp(CreateXMLTag('elec1:TaxAmount', FormatNumber(SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine.Amount)));
                AddLineXMLTemp('<elec1:eTaxSubtotal>');
                AddLineXMLTemp('<elec2:TaxSubtotal>');
                AddLineXMLTemp(CreateXMLTag('elec2:currencyID', GetCurrencyCode(SalesCrMemoHdr."Currency Code")));
                AddLineXMLTemp(CreateXMLTag('elec2:TaxAmount', FormatNumber(SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine.Amount)));
                AddLineXMLTemp(CreateXMLTag('elec2:TaxableAmount', FormatNumber(SalesCrMemoLine.Amount)));
                AddLineXMLTemp('<elec2:eTaxCategory>');
                //AddLineXMLTemp(CreateXMLTag('elec3:ID',CatalogoSunat."Alternative Code"));
                //CatalogoSunat.TestField("UN ECE 5305");
                AddLineXMLTemp(CreateXMLTag('elec3:ID', CatalogoSunat."UN ECE 5305"));
                AddLineXMLTemp(CreateXMLTag('elec3:Percent', FormatNumber(SalesCrMemoLine."VAT %")));
                AddLineXMLTemp(CreateXMLTag('elec3:TaxExemptionReasonCode', VATPostingSetup."EB VAT Type Affectation"));
                AddLineXMLTemp('<elec3:eTaxScheme>');
                AddLineXMLTemp(CreateXMLTag('elec4:ID', CatalogoSunat."Legal No."));
                AddLineXMLTemp(CreateXMLTag('elec4:Name', CatalogoSunat."Alternative Code"));
                AddLineXMLTemp(CreateXMLTag('elec4:TaxAmount', FormatNumber(SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine.Amount)));
                AddLineXMLTemp(CreateXMLTag('elec4:TaxTypeCode', CatalogoSunat."Generic Code"));
                AddLineXMLTemp('</elec3:eTaxScheme>');
                AddLineXMLTemp('</elec2:eTaxCategory>');
                AddLineXMLTemp('</elec2:TaxSubtotal>');
                AddLineXMLTemp('</elec1:eTaxSubtotal>');
                AddLineXMLTemp('</elec1:TaxTotal>');
                AddLineXMLTemp('</elec1:lTaxTotal>');
                AddLineXMLTemp('<elec1:eItem>');
                //begin ULN::KFA 001 2020.05.22 ++
                // AddLineXMLTemp(CreateXMLTag('elec2:Description', '<![CDATA['+ fnSpecialCharAmpersam(SalesCrMemoLine.Description + SalesCrMemoLine."Description 2") + ']]>' )); 
                AddLineXMLTemp(CreateXMLTag('elec2:Description', '<![CDATA[' + SalesCrMemoLine.Description + SalesCrMemoLine."Description 2" + ']]>'));
                //end ULN::KFA 001 2020.05.22 ++  
                if GetLegalItemCode(SalesCrMemoLine."No.", SalesCrMemoLine.Type) <> '' then
                    AddLineXMLTemp(CreateXMLTag('elec2:eCommodityClassification', CreateXMLTag('elec3:ItemClassificationCode', GetLegalItemCode(SalesCrMemoLine."No.", SalesCrMemoLine.Type))));
                //XXXXif SalesCrMemoLine."Standard Sales Code" <> '' then
                //XXXX    AddLineXMLTemp(CreateXMLTag('elec2:eSellersItemIdentification', CreateXMLTag('elec3:ID', SalesCrMemoLine."Standard Sales Code")))
                //XXXXelse
                if SalesCrMemoLine."Standard Sales Code" <> '' then
                    AddLineXMLTemp(CreateXMLTag('elec2:eSellersItemIdentification', CreateXMLTag('elec3:ID', SalesCrMemoLine."Standard Sales Code")))
                else
                    AddLineXMLTemp(CreateXMLTag('elec2:eSellersItemIdentification', CreateXMLTag('elec3:ID', SalesCrMemoLine."No.")));
                AddLineXMLTemp('</elec1:eItem>');
                AddLineXMLTemp('<elec1:ePrice>');
                //begin ULN::KFA 001 2020.05.22 ++
                if (SalesCrMemoLine."VAT Bus. Posting Group" = LSetup."FT VAT Bus. Posting Group") then
                    // if SalesCrMemoHdr."Free Title" then
                    //end ULN::KFA 001 2020.05.22 ++
                    AddLineXMLTemp(CreateXMLTag('elec2:PriceAmount', FormatNumber(0)))
                else
                    AddLineXMLTemp(CreateXMLTag('elec2:PriceAmount', FormatNumber(SalesCrMemoLine."Unit Price")));
                //AddLineXMLTemp(CreateXMLTag('elec2:PriceAmountIncVAT',FormatNumber(Round(SalesCrMemoLine."Unit Price"*(1 + SalesCrMemoLine."VAT %"/100)))));
                AddLineXMLTemp(CreateXMLTag('elec2:currencyID', GetCurrencyCode(SalesCrMemoHdr."Currency Code")));
                AddLineXMLTemp('</elec1:ePrice>');
                AddLineXMLTemp('</elec1:CreditNoteLine>');
            until SalesCrMemoLine.NEXT = 0;
            AddLineXMLTemp('</elec:lCreditNoteLine>')
        end;
    end;

    local procedure DetailedDebitNoteXMLPart()
    var
        LineNo: Integer;
        DsctoUnit: Decimal;
    begin
        if NOt DebitNote then
            exit;
        SalesInvLine.Reset;
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        SalesInvLine.SetFilter(Type, '<>%1', SalesInvLine.Type::" ");
        SalesInvLine.SetFilter(Quantity, '>%1', 0);
        //SalesInvLine.SetFilter("No. factura anticipo", '%1', '');
        //SalesInvLine.SetRange("Free Title Line",FALSE);
        if SalesInvLine.FINDSET then begin
            AddLineXMLTemp('<elec:lDebitNoteLine>');
            repeat
                LineNo += 1;
                VATPostingSetup.GET(SalesInvLine."VAT Bus. Posting Group", SalesInvLine."VAT Prod. Posting Group");
                CatalogoSunat.Reset;
                CatalogoSunat.SetRange("Option Type", CatalogoSunat."Option Type"::"Catalogue SUNAT");
                CatalogoSunat.SetRange("Type Code", '05');
                CatalogoSunat.SetRange("Legal No.", VATPostingSetup."EB Tax Type Code");
                if CatalogoSunat.FindFirst() then;
                AddLineXMLTemp('<elec1:DebitNoteLine>');
                AddLineXMLTemp(CreateXMLTag('elec1:ID', Format(LineNo)));  //Número de orden del Ítem.
                AddLineXMLTemp(CreateXMLTag('elec1:UnitCode', GetUnitOfMeasure(SalesInvLine."Unit of Measure Code")));
                AddLineXMLTemp(CreateXMLTag('elec1:DebitedQuantity', FormatNumber(SalesInvLine.Quantity))); //Cantidad y Unidad de Medida por ítem.         
                AddLineXMLTemp(CreateXMLTag('elec1:LineExtensionAmount', FormatNumber(SalesInvLine.Amount))); //Valor de venta por ítem
                AddLineXMLTemp('<elec1:ePricingReference>');
                AddLineXMLTemp('<elec2:lAlternativeConditionPrice>');
                AddLineXMLTemp('<elec3:AlternativeConditionPrice>');
                //AddLineXMLTemp(CreateXMLTag('elec3:PriceAmount', FormatNumber(SalesInvLine."Unit Price"))); //Precio de venta unitario por ítem y código
                //AddLineXMLTemp(CreateXMLTag('elec3:PriceTypeCode', '01')); //Valor referencial unitario por ítem en operaciones no onerosas 
                if (SalesInvLine."VAT Bus. Posting Group" = LSetup."FT VAT Bus. Posting Group") then
                    AddLineXMLTemp(CreateXMLTag('elec3:PriceAmount', FormatNumber(SalesInvLine."Unit Price"))) //Precio de venta unitario por ítem y código
                else begin
                    fnGetPriceAmountWithoutDscto(SalesInvLine."Line Discount Amount", SalesInvLine.Quantity, DsctoUnit);
                    AddLineXMLTemp(CreateXMLTag('elec3:PriceAmount', FormatNumber((SalesInvLine."Unit Price" - DsctoUnit) * ((100 + SalesInvLine."VAT %") / 100)))); //Precio de venta unitario por ¡tem y c¢digo
                end;
                if (SalesInvLine."VAT Bus. Posting Group" = LSetup."FT VAT Bus. Posting Group") then
                    AddLineXMLTemp(CreateXMLTag('elec3:PriceTypeCode', '02')) //Valor referencial unitario por ¡tem en operaciones no onerosas
                else
                    AddLineXMLTemp(CreateXMLTag('elec3:PriceTypeCode', '01')); //Valor referencial unitario por ítem en operaciones no onerosas 
                AddLineXMLTemp(CreateXMLTag('elec1:currencyID', GetCurrencyCode(SalesInvHeader."Currency Code")));
                AddLineXMLTemp('</elec3:AlternativeConditionPrice>');
                AddLineXMLTemp('</elec2:lAlternativeConditionPrice>');
                AddLineXMLTemp('</elec1:ePricingReference>');
                AddLineXMLTemp('<elec1:lTaxTotal>');
                AddLineXMLTemp('<elec1:TaxTotal>');
                AddLineXMLTemp(CreateXMLTag('elec1:TaxAmount', FormatNumber(SalesInvLine."Amount Including VAT" - SalesInvLine.Amount)));
                AddLineXMLTemp('<elec1:eTaxSubtotal>');
                AddLineXMLTemp('<elec2:TaxSubtotal>');
                AddLineXMLTemp(CreateXMLTag('elec2:Amount_currencyID', GetCurrencyCode(SalesInvHeader."Currency Code")));
                AddLineXMLTemp(CreateXMLTag('elec2:TaxAmount', FormatNumber(SalesInvLine."Amount Including VAT" - SalesInvLine.Amount)));
                AddLineXMLTemp(CreateXMLTag('elec2:TaxableAmount', FormatNumber(SalesInvLine.Amount)));
                AddLineXMLTemp('<elec2:eTaxCategory>');
                //AddLineXMLTemp(CreateXMLTag('elec3:ID',CatalogoSunat."Alternative Code"));
                AddLineXMLTemp(CreateXMLTag('elec3:ID', CatalogoSunat."UN ECE 5305"));
                AddLineXMLTemp(CreateXMLTag('elec3:Percent', FormatNumber(SalesInvLine."VAT %")));
                AddLineXMLTemp(CreateXMLTag('elec3:TaxExemptionReasonCode', VATPostingSetup."EB VAT Type Affectation"));
                AddLineXMLTemp('<elec3:eTaxScheme>');
                AddLineXMLTemp(CreateXMLTag('elec4:ID', CatalogoSunat."Legal No."));
                AddLineXMLTemp(CreateXMLTag('elec4:Name', CatalogoSunat."Alternative Code"));
                //AddLineXMLTemp(CreateXMLTag('elec4:TaxAmount',FormatNumber(SalesInvLine."Amount Including VAT" - SalesInvLine.Amount)));
                AddLineXMLTemp(CreateXMLTag('elec4:TaxTypeCode', CatalogoSunat."Generic Code"));
                AddLineXMLTemp('</elec3:eTaxScheme>');
                AddLineXMLTemp('</elec2:eTaxCategory>');
                AddLineXMLTemp('</elec2:TaxSubtotal>');
                AddLineXMLTemp('</elec1:eTaxSubtotal>');
                AddLineXMLTemp('</elec1:TaxTotal>');
                AddLineXMLTemp('</elec1:lTaxTotal>');
                AddLineXMLTemp('<elec1:eItem>');
                //begin ULN::KFA 001 2020.05.22 ++
                //AddLineXMLTemp(CreateXMLTag('elec2:Description', '<![CDATA['+ fnSpecialCharAmpersam(SalesInvLine.Description + ']]>' ))); 
                AddLineXMLTemp(CreateXMLTag('elec2:Description', '<![CDATA[' + SalesInvLine.Description + ']]>'));
                //end ULN::KFA 001 2020.05.22 ++
                if GetLegalItemCode(SalesInvLine."No.", SalesInvLine.Type) <> '' then
                    AddLineXMLTemp(CreateXMLTag('elec2:eCommodityClassification', CreateXMLTag('elec3:ItemClassificationCode', GetLegalItemCode(SalesInvLine."No.", SalesInvLine.Type))));
                //if SalesInvLine."Standard Sales Code" <> '' then
                //    AddLineXMLTemp(CreateXMLTag('elec2:eSellersItemIdentification', CreateXMLTag('elec3:ID', SalesInvLine."Standard Sales Code")))
                //else
                if SalesInvLine."Standard Sales Code" <> '' then
                    AddLineXMLTemp(CreateXMLTag('elec2:eSellersItemIdentification', CreateXMLTag('elec3:ID', SalesInvLine."Standard Sales Code")))
                else
                    AddLineXMLTemp(CreateXMLTag('elec2:eSellersItemIdentification', CreateXMLTag('elec3:ID', SalesInvLine."No.")));
                AddLineXMLTemp('</elec1:eItem>');
                AddLineXMLTemp('<elec1:ePrice>');
                if SalesInvHeader."FT Free Title" then
                    AddLineXMLTemp(CreateXMLTag('elec2:PriceAmount', FormatNumber(0)))
                else
                    AddLineXMLTemp(CreateXMLTag('elec2:PriceAmount', FormatNumber(SalesInvLine."Unit Price")));
                //AddLineXMLTemp(CreateXMLTag('elec2:PriceAmountIncVAT',FormatNumber(Round(SalesInvLine."Unit Price"*(1 + SalesInvLine."VAT %"/100)))));  
                AddLineXMLTemp(CreateXMLTag('elec2:currencyID', GetCurrencyCode(SalesInvHeader."Currency Code")));
                AddLineXMLTemp('</elec1:ePrice>');
                AddLineXMLTemp('</elec1:DebitNoteLine>');
            until SalesInvLine.NEXT = 0;
            AddLineXMLTemp('</elec:lDebitNoteLine>');
        end;
    end;

    local procedure GetLegalItemCode(No: Code[20]; LineType: Enum "Sales Line Type"): Code[20]
    var
        GLAcc: Record "G/L Account";
        Item: Record Item;
        Resource: Record Resource;
        FixedAsset: Record "Fixed Asset";
        GLEntry: Record "G/L Entry";
    begin
        //(0) ,(1)G/L Account,(2)Item,(3)Resource,(4)Fixed Asset,(5)Charge (Item)
        case LineType of
            Linetype::"G/L Account":
                begin
                    GLAcc.Get(No);
                    GLAcc.TestField("EB Legal Item Code");
                    exit(GLAcc."EB Legal Item Code");
                end;
            LineType::Item:
                begin
                    Item.Get(No);
                    Item.TestField("EB Legal Item Code");
                    exit(Item."EB Legal Item Code");
                end;
            LineType::Resource:
                begin
                    Resource.Get(No);
                    Resource.TestField("EB Legal Item Code");
                    exit(Resource."EB Legal Item Code");
                end;
            LineType::"Fixed Asset":
                begin
                    FixedAsset.Get(No);
                    FixedAsset.TestField("EB Legal Item Code");
                    exit(FixedAsset."EB Legal Item Code");
                end;
        end;
        exit('');
    end;

    local procedure PersonalizationPDFXMLPart()
    var
        BankAccount: Record "Bank Account";
        LineNo: Integer;
    begin
        LineNo := 0;
        AddLineXMLTemp('<elec:lPersonalizacionPDF>');
        BankAccount.Reset;
        BankAccount.SetRange("EB Show Electronic Bill", true);
        if BankAccount.FindFirst() then begin
            AddLineXMLTemp('<elec1:lPersonalizacionBanco>');
            repeat
                LineNo := LineNo + 1;
                AddLineXMLTemp('<elec2:PersonalizacionBanco>');
                AddLineXMLTemp(CreateXMLTag('elec2:ID', ForMAT(LineNo)));
                AddLineXMLTemp(CreateXMLTag('elec2:Name', BankAccount.Name));
                AddLineXMLTemp(CreateXMLTag('elec2:Currency', GetCurrencyCode(BankAccount."Currency Code")));
                AddLineXMLTemp(CreateXMLTag('elec2:Account', BankAccount."Bank Account No."));
                AddLineXMLTemp(CreateXMLTag('elec2:AccountCCI', BankAccount."Bank Account CCI"));
                AddLineXMLTemp('</elec2:PersonalizacionBanco>');
            until BankAccount.NEXT = 0;
            AddLineXMLTemp('</elec1:lPersonalizacionBanco>');
        end;
        AddLineXMLTemp('<elec1:lPersonalizacionEtiqueta>');
        // if (Invoice or Ticket) and (SalesInvHeader."External Document No." <> '') then begin
        //     AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
        //     AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
        //     AddLineXMLTemp(CreateXMLTag('elec2:Title', 'ordenCompra'));
        //     AddLineXMLTemp(CreateXMLTag('elec2:Value', ForMAT(SalesInvHeader."External Document No.")));
        //     AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
        // end;
        /*if (Invoice or Ticket or DebitNote) and (SalesInvHeader."Job No." <> '') then begin
            AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
            AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Footer'));
            AddLineXMLTemp(CreateXMLTag('elec2:Title', 'Proyecto'));
            AddLineXMLTemp(CreateXMLTag('elec2:Value', fnGetProjectName(SalesInvHeader."Job No.")));
            AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
        end;*/
        if (Invoice) and (LSetup."Retention Agent Option" in [LSetup."Retention Agent Option"::"Only Electronic", LSetup."Retention Agent Option"::"Physical and Electronics"]) then begin
            AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
            AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Footer'));
            AddLineXMLTemp(CreateXMLTag('elec2:Title', 'Agente'));
            AddLineXMLTemp(CreateXMLTag('elec2:Value', 'Somos AGENTES DE RETENCION por R.S. ' + LSetup."Retention Resolution Number"));
            AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
        end;

        // if GetShipmentNo() <> '' then begin
        //     AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
        //     AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
        //     AddLineXMLTemp(CreateXMLTag('elec2:Title', 'NroGuia'));
        //     AddLineXMLTemp(CreateXMLTag('elec2:Value', GetShipmentNo()));
        //     AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
        // end;

        //BEGIN: Personalización Airsealog
        if CreditNote then begin
            if SalesCrMemoHdr."Shortcut Dimension 3 Code" <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'Job'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesCrMemoHdr."Shortcut Dimension 3 Code" + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesCrMemoHdr."BL No." <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'BL'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesCrMemoHdr."BL No." + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesCrMemoHdr."Shipper Name" <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'Shipper'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesCrMemoHdr."Shipper Name" + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesCrMemoHdr."Consignee Name" <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'Consignee'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesCrMemoHdr."Consignee Name" + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesCrMemoHdr."Routing No." <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'Routing'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesCrMemoHdr."Routing No." + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesCrMemoHdr.Origin <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'Origen'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesCrMemoHdr.Origin + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesCrMemoHdr.Placa <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'BarcoVuelo'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesCrMemoHdr.Placa + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesCrMemoHdr."Carrier Name" <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'Carrier'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesCrMemoHdr."Carrier Name" + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesCrMemoHdr.Destination <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'Destino'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesCrMemoHdr.Destination + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesCrMemoHdr."Get Out Date" <> 0D then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'FechaETA'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', FormatDate(SalesCrMemoHdr."Get Out Date")));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesCrMemoHdr."Arrived Date" <> 0D then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'FechaETD'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', FormatDate(SalesCrMemoHdr."Arrived Date")));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesCrMemoHdr."Cargowise Invoice No." <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'CorrelativoInterno'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesCrMemoHdr."Cargowise Invoice No." + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesCrMemoHdr."No. Sales Shipment" <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'NroGuia'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesCrMemoHdr."No. Sales Shipment" + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;
            if SalesCrMemoHdr."Purchase order No." <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'OrdenCompra'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + Format(SalesCrMemoHdr."Purchase order No." + ']]>')));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;
        end else begin
            if SalesInvHeader."Shortcut Dimension 3 Code" <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'Job'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesInvHeader."Shortcut Dimension 3 Code" + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesInvHeader."BL No." <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'BL'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesInvHeader."BL No." + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesInvHeader."Shipper Name" <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'Shipper'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesInvHeader."Shipper Name" + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesInvHeader."Consignee Name" <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'Consignee'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesInvHeader."Consignee Name" + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesInvHeader."Routing No." <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'Routing'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesInvHeader."Routing No." + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesInvHeader.Origin <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'Origen'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesInvHeader.Origin + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesInvHeader.Placa <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'BarcoVuelo'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesInvHeader.Placa + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesInvHeader."Carrier Name" <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'Carrier'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesInvHeader."Carrier Name" + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesInvHeader.Destination <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'Destino'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesInvHeader.Destination + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesInvHeader."Get Out Date" <> 0D then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'FechaETA'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', FormatDate(SalesInvHeader."Get Out Date")));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesInvHeader."Arrived Date" <> 0D then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'FechaETD'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', FormatDate(SalesInvHeader."Arrived Date")));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesInvHeader."Cargowise Invoice No." <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'CorrelativoInterno'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesInvHeader."Cargowise Invoice No." + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesInvHeader."No. Sales Shipment" <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'NroGuia'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + SalesInvHeader."No. Sales Shipment" + ']]>'));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;

            if SalesInvHeader."Purchase order No." <> '' then begin
                AddLineXMLTemp('<elec2:PersonalizacionEtiqueta>');
                AddLineXMLTemp(CreateXMLTag('elec2:Section', 'Header'));
                AddLineXMLTemp(CreateXMLTag('elec2:Title', 'OrdenCompra'));
                AddLineXMLTemp(CreateXMLTag('elec2:Value', '<![CDATA[' + Format(SalesInvHeader."Purchase order No." + ']]>')));
                AddLineXMLTemp('</elec2:PersonalizacionEtiqueta>');
            end;
        end;
        //END: Personalización Airsealog
        AddLineXMLTemp('</elec1:lPersonalizacionEtiqueta>');
        AddLineXMLTemp('</elec:lPersonalizacionPDF>');
    end;

    local procedure PaymentTermsSunatXMLPart()
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if CreditNote then begin
            AddLineXMLTemp('<elec:PaymentTermsSunat>');
            PaymentTerms.Reset();
            PaymentTerms.SetRange(Code, SalesCrMemoHdr."Payment Terms Code");
            if PaymentTerms.FindFirst() then begin
                case PaymentTerms."Payment Method Type" of
                    PaymentTerms."Payment Method Type"::Contado:
                        AddLineXMLTemp(CreateXMLTag('elec1:PaymentTermsCode', '1'));
                    PaymentTerms."Payment Method Type"::Credito:
                        AddLineXMLTemp(CreateXMLTag('elec1:PaymentTermsCode', '2'));
                end;
                if PaymentTerms."Payment Method Type" = PaymentTerms."Payment Method Type"::Credito then begin
                    SalesCrMemoHdr.CalcFields("Amount Including VAT");
                    AddLineXMLTemp(CreateXMLTag('elec1:RemainingAmount', FormatNumber(SalesCrMemoHdr."Amount Including VAT")));
                    AddLineXMLTemp(CreateXMLTag('elec1:CurrencyIDRemainingAmount', GetCurrencyCode(SalesCrMemoHdr."Currency Code")));
                    AddLineXMLTemp('<elec1:lInstallmentPayment>');
                    AddLineXMLTemp('<elec2:InstallmentPayment>');
                    AddLineXMLTemp(CreateXMLTag('elec2:ID', Format(1)));
                    AddLineXMLTemp(CreateXMLTag('elec2:Amount', FormatNumber(SalesCrMemoHdr."Amount Including VAT")));
                    AddLineXMLTemp(CreateXMLTag('elec2:CurrencyIDInstallment', GetCurrencyCode(SalesCrMemoHdr."Currency Code")));
                    AddLineXMLTemp(CreateXMLTag('elec2:PaidDate', FormatDate(SalesCrMemoHdr."Due Date")));
                    AddLineXMLTemp('</elec2:InstallmentPayment>');
                    AddLineXMLTemp('</elec1:lInstallmentPayment>');
                end;
            end;
            AddLineXMLTemp('</elec:PaymentTermsSunat>');
        end else begin
            AddLineXMLTemp('<elec:PaymentTermsSunat>');
            PaymentTerms.Reset();
            PaymentTerms.SetRange(Code, SalesInvHeader."Payment Terms Code");
            if PaymentTerms.FindFirst() then begin
                case PaymentTerms."Payment Method Type" of
                    PaymentTerms."Payment Method Type"::Contado:
                        AddLineXMLTemp(CreateXMLTag('elec1:PaymentTermsCode', '1'));
                    PaymentTerms."Payment Method Type"::Credito:
                        AddLineXMLTemp(CreateXMLTag('elec1:PaymentTermsCode', '2'));
                end;
                if PaymentTerms."Payment Method Type" = PaymentTerms."Payment Method Type"::Credito then begin
                    SalesInvHeader.CalcFields("Amount Including VAT");
                    AddLineXMLTemp(CreateXMLTag('elec1:RemainingAmount', FormatNumber(SalesInvHeader."Amount Including VAT")));
                    AddLineXMLTemp(CreateXMLTag('elec1:CurrencyIDRemainingAmount', GetCurrencyCode(SalesInvHeader."Currency Code")));
                    AddLineXMLTemp('<elec1:lInstallmentPayment>');
                    AddLineXMLTemp('<elec2:InstallmentPayment>');
                    AddLineXMLTemp(CreateXMLTag('elec2:ID', Format(1)));
                    AddLineXMLTemp(CreateXMLTag('elec2:Amount', FormatNumber(SalesInvHeader."Amount Including VAT")));
                    AddLineXMLTemp(CreateXMLTag('elec2:CurrencyIDInstallment', GetCurrencyCode(SalesInvHeader."Currency Code")));
                    AddLineXMLTemp(CreateXMLTag('elec2:PaidDate', FormatDate(SalesInvHeader."Due Date")));
                    AddLineXMLTemp('</elec2:InstallmentPayment>');
                    AddLineXMLTemp('</elec1:lInstallmentPayment>');
                end;
            end;
            AddLineXMLTemp('</elec:PaymentTermsSunat>');
        end;
    end;

    local procedure GetUnitOfMeasure(UnitOfMeasureCode: Code[20]): Text
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        //if (not UnitOfMeasure.Get(UnitOfMeasureCode)) or (UnitOfMeasureCode in ['UND', 'UN']) then
        //    exit('NIU');
        UnitOfMeasure.Get(UnitOfMeasureCode);
        UnitOfMeasure.TestField("EB Comercial Unit of Measure");
        exit(UnitOfMeasure."EB Comercial Unit of Measure");
    end;

    local procedure GetShipmentNo(): Text
    begin
        if not (Invoice or Ticket) then
            exit('');
        SalesInvLine.Reset();
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        SalesInvLine.SetFilter(Type, '<>%1', SalesInvLine.Type::" ");
        SalesInvLine.SetFilter(Quantity, '>%1', 0);
        SalesInvLine.SetFilter("Shipment No.", '<>%1', '');
        if SalesInvLine.FindFirst() then
            exit(SalesInvLine."Shipment No.");
        exit('');
    end;

    local procedure FooterXMLPart()
    begin
        case true of
            Invoice:
                begin
                    AddLineXMLTemp('</tem:pInvoice>');
                    CommonFieldsXMLPart();
                    AddLineXMLTemp('</tem:sendInvoiceDocuments>');
                end;
            Ticket:
                begin
                    AddLineXMLTemp('</tem:pInvoice>');
                    CommonFieldsXMLPart();
                    AddLineXMLTemp('</tem:sendTicketDocuments>');
                end;
            CreditNote:
                begin
                    AddLineXMLTemp('</tem:pCreditNote>');
                    CommonFieldsXMLPart();
                    AddLineXMLTemp('</tem:sendCreditNoteDocuments>');
                end;
            DebitNote:
                begin
                    AddLineXMLTemp('</tem:pDebitNote>');
                    CommonFieldsXMLPart();
                    AddLineXMLTemp('</tem:sendDebitNoteDocuments>');
                end;
        end;
        AddLineXMLTemp('</soapenv:Body>');
        AddLineXMLTemp('</soapenv:Envelope>');
    end;

    local procedure CommonFieldsXMLPart()
    begin
        AddLineXMLTemp('<tem:commonFields>');
        //AddLineXMLTemp(CreateXMLTag('elec6:cellphone',NumPhoneCust));
        if CompanyInfo."E-Mail" <> '' then
            AddLineXMLTemp(CreateXMLTag('elec6:email', CompanyInfo."E-Mail"));
        CommentsXMLPart();
        if Invoice then
            AddLineXMLTemp(CreateXMLTag('elec6:paymentTerm', GetPaymentTermDescription(SalesInvHeader."Payment Terms Code")));
        if CompanyInfo."Phone No." <> '' then
            AddLineXMLTemp(CreateXMLTag('elec6:phoneNumber', CompanyInfo."Phone No."));
        if EBSetup."EB Elec. Bill Resolution No." <> '' then
            AddLineXMLTemp(CreateXMLTag('elec6:resolucionFE', EBSetup."EB Elec. Bill Resolution No."));
        if CompanyInfo."Home Page" <> '' then
            AddLineXMLTemp(CreateXMLTag('elec6:webSite', CompanyInfo."Home Page"));
        AddLineXMLTemp('</tem:commonFields>');
    end;

    local procedure CommentsXMLPart()
    var
        WorkDescription: InStream;
        LineText: Text;
    begin
        if CreditNote then
            exit;

        SalesInvHeader.CalcFields("Work Description");
        if SalesInvHeader."Work Description".HasValue then BEGIN
            AddLineXMLTemp('<elec6:gloss>');
            SalesInvHeader."Work Description".CREATEINSTREAM(WorkDescription);
            while not WorkDescription.EOS do begin
                WorkDescription.ReadText(LineText);
                LineText := DELCHR(LineText, '=', '°´');
                AddLineXMLTemp(CreateXMLTag('arr:string', '<![CDATA[' + LineText + ']]>'));
            end;
            AddLineXMLTemp('</elec6:gloss>');
        end;
    end;

    local procedure GetPaymentTermDescription(PaymentTermCode: Code[10]): Text
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if PaymentTerms.Get(PaymentTermCode) then
            exit(PaymentTerms.Description);
        exit('');
    end;

    local procedure InsertEBLedgerEntry(ShipStatus: Option; LegalStatusCode: Code[10]; ResponseInStream: InStream; ResponseText: Text; ModifyStatus: Boolean)
    var
        SenderXMLInStream: InStream;
        QRInStream: InStream;
        DocumentType: Option;
    begin
        TempFileBlob.CreateInStream(SenderXMLInStream);
        //if not TempFileBlob.HasValue() then
        //    Message('No existe valor');
        //TempFileBlobResponse.CreateInStream(QRInStream);
        if CreditNote then
            DocumentType := 2
        else
            DocumentType := 1;
        EBEntry.InsertEBEntryRecord(DocumentType, DocumentNo, LegalDocument, ShipStatus, LegalStatusCode, ResponseText, SenderXMLInStream, ResponseInStream, TempFileBlobResponse, ModifyStatus);
    end;

    //----------------------------------------------------
    local procedure ConsumeService()
    var
        HttpContent: HttpContent;
        HttpHeadersContent: HttpHeaders;
        HttpClient: HttpClient;
        HttpRequestMessagex: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        NewFileInStream: InStream;
        RespFileInStream: InStream;
        Lenght: Integer;
        ResponseText: Text;
    begin
        SetInitParametersServices();
        TempFileBlob.CreateInStream(NewFileInStream);
        HttpContent.WriteFrom(NewFileInStream);
        HttpContent.GetHeaders(HttpHeadersContent);
        HttpHeadersContent.Remove('Content-Type');
        HttpHeadersContent.Add('Content-Type', 'text/xml;charset=utf-8');
        HttpHeadersContent.Add('SOAPAction', SOAPAction);
        HttpClient.SetBaseAddress(EBSetup."EB URI Service");
        //HttpClient.DefaultRequestHeaders.Add('Authorization', StrSubstNo('Basic %1', Base64String));
        HttpClient.Post(EBSetup."EB URI Service", HttpContent, HttpResponse);
        if HttpResponse.IsSuccessStatusCode then begin
            HttpContent.Clear();
            HttpContent := HttpResponse.Content();
            HttpContent.ReadAs(RespFileInStream);
            ReadResponse(RespFileInStream, HttpResponse.HttpStatusCode);
        end else begin
            HttpContent.Clear();
            HttpContent := HttpResponse.Content();
            HttpContent.ReadAs(RespFileInStream);
            ReadResponse(RespFileInStream, HttpResponse.HttpStatusCode);
        end;
    end;

    local procedure ReadResponse(ResponseInStream: InStream; HttpStatusCode: Integer)
    var
        Base64Convert: Codeunit "Base64 Convert";
        LegalStatus: Option;
        LegalStatusCode: Code[10];
        SunatDescription: Text[250];
        EBMessage: Text[250];
        OutStreamFile: OutStream;
        InStreamFile: InStream;
        OutStreamFile2: OutStream;
        InStreamFile2: InStream;
        IsFalse: Boolean;
        ShipStatus: Option;
        LineText: Text;
        ToFileName: Text;
        DialogTitle: Label 'Download File', comment = 'ESM="Descargar archivo"';
    begin
        case HttpStatusCode of
            200:
                begin
                    ReadResponseHttpStatus200(ResponseInStream);
                end;
            else begin
                    InsertEBLedgerEntry(0, '', ResponseInStream, StrSubstNo('Respuesta %1', Format(HttpStatusCode)), false);
                    Message(StrSubstNo('Respuesta %1', Format(HttpStatusCode)));
                end;
        end;
    end;

    local procedure ReadResponseHttpStatus200(ResponseInStream: InStream)
    var
        XMLBuffer: Record "XML Buffer" temporary;
        XMlBufferPage: Page "EB XML Buffer View";
        RspInStream: InStream;
        OutStreamFile: OutStream;
        ShipStatus: Integer;
        LegalStatusCode: Code[10];
        SunatDescription: Text;
        EBMessage: Text;
        QrText: Text;
        IsFalse: Boolean;
        ErrorEB: Label 'Ocurrió un error: \Sunat code: %1. \Sunat description %2. \Sunat message: %3.';
    begin
        XMLBuffer.Reset();
        XMLBuffer.DeleteAll();
        XMLBuffer.LoadFromStream(ResponseInStream);
        XMLBuffer.Reset();
        //Clear(XMlBufferPage);
        //XMlBufferPage.SetBufferTemp(XMLBuffer);
        //XMlBufferPage.Run();

        XMLBuffer.Reset();
        if XMLBuffer.FindFirst() then
            repeat
                case XMLBuffer.Path of
                    '/s:Envelope/s:Body/sendInvoiceDocumentsResponse/sendInvoiceDocumentsResult/a:Qr',
                    '/s:Envelope/s:Body/sendTicketDocumentsResponse/sendTicketDocumentsResult/a:Qr',
                    '/s:Envelope/s:Body/sendDebitNoteDocumentsResponse/sendDebitNoteDocumentsResult/a:Qr',
                    '/s:Envelope/s:Body/sendCreditNoteDocumentsResponse/sendCreditNoteDocumentsResult/a:Qr':
                        QrText := XMlBuffer.Value;
                    '/s:Envelope/s:Body/sendInvoiceDocumentsResponse/sendInvoiceDocumentsResult/a:SunatCode',
                    '/s:Envelope/s:Body/sendTicketDocumentsResponse/sendTicketDocumentsResult/a:SunatCode',
                    '/s:Envelope/s:Body/sendDebitNoteDocumentsResponse/sendDebitNoteDocumentsResult/a:SunatCode',
                    '/s:Envelope/s:Body/sendCreditNoteDocumentsResponse/sendCreditNoteDocumentsResult/a:SunatCode':
                        LegalStatusCode := XMLBuffer.Value;
                    '/s:Envelope/s:Body/sendInvoiceDocumentsResponse/sendInvoiceDocumentsResult/a:SunatDescription',
                    '/s:Envelope/s:Body/sendTicketDocumentsResponse/sendTicketDocumentsResult/a:SunatDescription',
                    '/s:Envelope/s:Body/sendDebitNoteDocumentsResponse/sendDebitNoteDocumentsResult/a:SunatDescription',
                    '/s:Envelope/s:Body/sendCreditNoteDocumentsResponse/sendCreditNoteDocumentsResult/a:SunatDescription':
                        SunatDescription := XMLBuffer.Value;
                    '/s:Envelope/s:Body/sendInvoiceDocumentsResponse/sendInvoiceDocumentsResult/a:message',
                    '/s:Envelope/s:Body/sendTicketDocumentsResponse/sendTicketDocumentsResult/a:messag',
                    '/s:Envelope/s:Body/sendDebitNoteDocumentsResponse/sendDebitNoteDocumentsResult/a:messag',
                    '/s:Envelope/s:Body/sendCreditNoteDocumentsResponse/sendCreditNoteDocumentsResult/a:messag':
                        EBMessage := XMLBuffer.Value;
                    '/s:Envelope/s:Body/sendInvoiceDocumentsResponse/sendInvoiceDocumentsResult/a:status',
                    '/s:Envelope/s:Body/sendTicketDocumentsResponse/sendTicketDocumentsResult/a:status',
                    '/s:Envelope/s:Body/sendDebitNoteDocumentsResponse/sendDebitNoteDocumentsResult/a:status',
                    '/s:Envelope/s:Body/sendCreditNoteDocumentsResponse/sendCreditNoteDocumentsResult/a:status':
                        IsFalse := XMLBuffer.Value = 'false';
                end;
            until XMlBuffer.Next() = 0;
        if IsFalse then begin
            InsertEBLedgerEntry(0, LegalStatusCode, ResponseInStream, EBMessage, false);
            Message(StrSubstNo(ErrorEB, LegalStatusCode, SunatDescription, EBMessage));
            exit;
        end;
        case true of
            Invoice, Ticket, CreditNote, DebitNote:
                begin
                    if QrText <> 'AAAAAAAAAAAAAA==' then begin
                        TempFileBlobResponse.CreateOutStream(OutStreamFile);
                        OutStreamFile.WriteText(QrText);
                    end;
                    case LegalStatusCode of
                        '0', '98':
                            ShipStatus := 1;
                        '99':
                            ShipStatus := 3;
                    end;
                    InsertEBLedgerEntry(ShipStatus, LegalStatusCode, ResponseInStream, SunatDescription, true);
                end;
            GetFileDocument:
                begin
                    SetFileDocument(XMLBuffer, SunatDescription);
                end;
        end;
        Message(SunatDescription);
    end;

    local procedure SetFileDocument(var pXMLBuffer: Record "XML Buffer" temporary; var SunatDescription: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        TempFileBlobRespFileDoc: Codeunit "Temp Blob";
        ToFileName: Text;
        RespFileLine: Text;
        RespFileText: Text;
        OutStreamFile: OutStream;
        InStreamFile: InStream;
        InStreamFileDoc: InStream;
        IsEmptyFile: Boolean;
        DialogTitle: Label 'Download File', Comment = 'ESM="Descargar archivo"';
    begin
        pXMLBuffer.Reset();
        pXMLBuffer.SetRange(Path, '/s:Envelope/s:Body/getDocumentResponse/getDocumentResult/a:archivo');
        pXMLBuffer.SetFilter(Value, '<>%1', 'AAAAAAAAAAAAAA==');
        if pXMLBuffer.FindFirst() then begin
            TempFileBlobRespFileDoc.CreateOutStream(OutStreamFile);
            pXMLBuffer.CalcFields("Value BLOB");
            if pXMLBuffer."Value BLOB".HasValue then begin
                pXMLBuffer."Value BLOB".CreateInStream(InStreamFile);
                while not InStreamFile.EOS do begin
                    RespFileLine := '';
                    InStreamFile.ReadText(RespFileLine);
                    RespFileText += RespFileLine;
                end;
            end else
                RespFileText := pXMLBuffer.Value;
            Base64Convert.FromBase64(RespFileText, OutStreamFile);
            TempFileBlobRespFileDoc.CreateInStream(InStreamFileDoc);
            case FileType of
                'PDF':
                    begin
                        ToFileName := StrSubstNo('%1-%2.%3', DocumentNo, LegalDocument, 'pdf');
                        DownloadFromStream(InStreamFileDoc, DialogTitle, '', 'All Files (*.*)|*.pdf', ToFileName);
                    end;
                'XML':
                    begin
                        ToFileName := StrSubstNo('%1-%2.%3', DocumentNo, LegalDocument, 'xml');
                        DownloadFromStream(InStreamFileDoc, DialogTitle, '', 'All Files (*.*)|*.xml', ToFileName);
                    end;
                'CDR':
                    begin
                        ToFileName := StrSubstNo('%1-%2.%3', DocumentNo, LegalDocument, 'xml');
                        DownloadFromStream(InStreamFileDoc, DialogTitle, '', 'All Files (*.*)|*.xml', ToFileName);
                    end;
            end;
            SunatDescription := StrSubstNo('Archivo %1 correctamente descargado', FileType);
        end else
            SunatDescription := 'Ocurrio un problema, volver a intentar.';
    end;

    local procedure IsExistsXMLTagValue(ResponseText: Text; TagText: Text): Boolean
    var
        StartTag: Text;
        EndTag: Text;
        StartPos: Integer;
        EndPos: Integer;
    begin
        StartTag := StrSubstNo('<%1>', TagText);
        EndTag := StrSubstNo('</%1>', TagText);
        if StrPos(ResponseText, TagText) = 0 then
            exit(false);
        StartPos := StrPos(ResponseText, StartTag) + StrLen(StartTag);
        EndPos := StrPos(ResponseText, EndTag) - 1;
        if not ((StartPos > 0) and (EndPos > 0)) then
            exit(false);
        ResponseText := CopyStr(ResponseText, StartPos, StrLen(ResponseText));
        ResponseText := CopyStr(ResponseText, 1, EndPos);
        exit(ResponseText <> '');
    end;

    local procedure GetXMLTagValue(ResponseText: Text; TagText: Text): Text
    var
        StartTag: Text;
        EndTag: Text;
    begin
        StartTag := StrSubstNo('<%1>', TagText);
        EndTag := StrSubstNo('</%1>', TagText);
        ResponseText := CopyStr(ResponseText, StrPos(ResponseText, StartTag) + StrLen(StartTag), STRLEN(ResponseText));
        ResponseText := CopyStr(ResponseText, 1, StrPos(ResponseText, EndTag) - 1);
        exit(ResponseText);
    end;

    local procedure SetInitParametersServices()
    var
        Base64Convert: Codeunit "Base64 Convert";
        AuthorizationString: Text;
    begin
        if Invoice then
            SOAPAction := EBSetup."EB Invoice";
        if Ticket then
            SOAPAction := EBSetup."EB Ticket";
        if CreditNote then
            SOAPAction := EBSetup."EB Credit Note";
        if DebitNote then
            SOAPAction := EBSetup."EB Debit Note";
        if VoidedDocument then
            SOAPAction := EBSetup."EB Voided Document";
        if SummaryDocuments then
            SOAPAction := EBSetup."EB Summary Documents";
        if GetFileDocument then
            SOAPAction := EBSetup."EB Get PDF";
        if GetTicketStatus then
            SOAPAction := EBSetup."EB Get Ticket Status";
        // if QRStatus then
        //     SOAPAction := EBSetup."EB Get QR";
        if ValidateSummaryDocuments then
            SOAPAction := EBSetup."EB Validate Summary Document";

        //AuthorizationString := strsubstNo('%1:%2', 'ULN', 'a123456A');
        //Base64String := Base64Convert.ToBase64(AuthorizationString);
    end;

    //----------------------------------------------------

    local procedure GetAmoutToText(Amount: Decimal; CurrencyCode: Code[10]): Text
    var
        IntegerPartText: array[2] of Text[80];
        DecimalPartText: Text[30];
        AmtInLetters: Codeunit "Amount in letters";
        SolesText: Label ' SOLES';
        DollarsText: Label 'DOLARES AMERICANOS';
        CeroText: Label 'CERO ';
        CentimosText: Label ' CÉNTIMOS';
        EurosText: Label 'EUROS';
    begin
        Clear(IntegerPartText);
        Clear(DecimalPartText);
        Clear(AmtInLetters);

        AmtInLetters.FormatNoText(IntegerPartText, Round(Amount, 0.01));
        if IntegerPartText[1] = CeroText then
            IntegerPartText[1] := IntegerPartText[1] + CentimosText;

        AmtInLetters.FormatNoText2(DecimalPartText, Amount);
        case CurrencyCode of
            'PEN', '':
                DecimalPartText := DecimalPartText + SolesText;
            'USD':
                DecimalPartText := DecimalPartText + DollarsText;
            'EUR':
                DecimalPartText := DecimalPartText + EurosText;
        end;
        exit(IntegerPartText[1] + DecimalPartText);
    end;

    local procedure CreateTempFile()
    begin
        TempFileBlob.CreateOutStream(ConstrutOutStream, TextEncoding::UTF8);
        SenderXMLTempFileBlob.CreateOutStream(SenderXmlConstrutOutStream, TextEncoding::UTF8);
    end;

    local procedure AddLineXMLTemp(LineText: Text[1024])
    begin
        ConstrutOutStream.WriteText(LineText);
        ConstrutOutStream.WriteText;
        SenderXmlConstrutOutStream.WriteText(LineText);
        SenderXmlConstrutOutStream.WriteText();
    end;

    local procedure CreateXMLTag(pTag: Text; pValue: Text): Text
    begin
        exit(StrSubstNo('<%1>%2</%1>', pTag, pValue));
    end;

    local procedure ConverSpecialCharAmpersam(ValueText: Text): Text
    var
        Lenght: Integer;
        PosSpecialChar: Integer;
        ResponseText: Text;
    begin
        Lenght := STRLEN(ValueText);
        PosSpecialChar := StrPos(ValueText, '&');
        if PosSpecialChar > 0 then
            ResponseText := CopyStr(ValueText, 1, PosSpecialChar - 1) + '&amp;' + CopyStr(ValueText, PosSpecialChar + 1, Lenght - PosSpecialChar)
        else
            ResponseText := ValueText;
        exit(ResponseText);
    end;

    local procedure ConvertSpecialCharEnie(ValueText: Text): Text
    var
        Lenght: Integer;
        PosSpecialChar: Integer;
        ResponseText: Text;
    begin
        ResponseText := ValueText;
        Lenght := StrLen(ValueText);
        PosSpecialChar := StrPos(ValueText, 'Ñ');
        if PosSpecialChar > 0 then begin
            ResponseText := CopyStr(ValueText, 1, PosSpecialChar - 1) + '&#209;' + CopyStr(ValueText, PosSpecialChar + 1, Lenght - PosSpecialChar);
        end else begin
            PosSpecialChar := StrPos(ValueText, 'ñ');
            if PosSpecialChar > 0 then
                ResponseText := CopyStr(ValueText, 1, PosSpecialChar - 1) + '&#209;' + CopyStr(ValueText, PosSpecialChar + 1, Lenght - PosSpecialChar)
        end;
        exit(ResponseText);
    end;

    local procedure ConvertAdjustVATRegistrationNo(VATRegNo: text): Text
    var
        PermisionCharacters: Label '1234567890';
    begin
        VATRegNo := DelChr(VATRegNo, '=', PermisionCharacters);
        if StrLen(VATRegNo) < 11 then
            VATRegNo := PadStr('', 11 - StrLen(VATRegNo), '0') + VATRegNo;
        exit(VATRegNo);
    end;

    local procedure FormatNumber(ValueDecimal: Decimal): Text
    begin
        exit(Format(ValueDecimal, 0, '<Precision,2:2><Standard Format,2>'));
    end;

    local procedure FormatDate(ValueDate: Date): Text
    begin
        exit(Format(ValueDate, 10, '<year4>-<month,2>-<day,2>'));
    end;

    local procedure FormatTime(ValueTime: Time): Text
    begin
        exit(Format(ValueTime, 0, '<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'));
    end;

    local procedure GetCurrencyCode(CurrencyCode: Code[10]): Text
    begin
        if CurrencyCode = '' then
            CurrencyCode := 'PEN';
        exit(CurrencyCode);
    end;

    //************************** PRE-POST *****************************
    procedure CheckElectronicBill(var SalesHeader: Record "Sales Header")
    begin
        if not SalesHeader."EB Electronic Bill" then begin
            SetNoSerie(SalesHeader."Posting No. Series");
            if NoSeries."EB Electronic Bill" then
                Error(ErrorElectronicMsg);
            exit;
        end;
        GetSetup(true);
        if SalesHeader."Legal Status" <> SalesHeader."Legal Status"::Success then
            Error(ErrorDocument, SalesHeader."Legal Status");
        SetNoSerie(SalesHeader."Posting No. Series");
        if (SalesHeader."VAT Registration No."[1] = '2') and (SalesHeader."Legal Document" = '03') then
            Error('No puede generar una boleta de venta para el proveedor %1.', SalesHeader."VAT Registration No.");
        if SalesHeader."Final Advanced" then begin
            if (SalesHeader."EB TAX Ref. Document Type" = '') or (SalesHeader."EB Motive discount code" = '') then
                error('Los campo %1 y %2 no pueden estar vacios', SalesHeader.FieldCaption(SalesHeader."EB TAX Ref. Document Type"), SalesHeader.FieldCaption(SalesHeader."EB Motive discount code"))

        end;
        CheckNoSeries();
        CheckPrePostCustomer(SalesHeader);
        CheckPrePostSales(SalesHeader);
    end;

    local procedure checkPrePostAccount(var SalesHeader: Record "Sales Header")
    var
        Account: Record "G/L Account";
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                if SalesLine.Type = SalesLine.Type::"G/L Account" then begin
                    Account.Reset();
                    Account.SetRange("No.", SalesLine."No.");
                    if Account.FindSet() then
                        Account.TestField("EB Legal Item Code");
                end;
            until SalesLine.Next() = 0;
    end;

    local procedure CheckPrePostCustomer(var SalesHeader: Record "Sales Header")
    var
        CheckRuc: Code[20];
    begin
        Customer.Get(SalesHeader."Sell-to Customer No.");
        Customer.TestField("E-Mail");
    end;

    local procedure CheckPrePostSales(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.TestField("Legal Document");
        SalesHeader.TestField("VAT Registration No.");
        SalesHeader.TestField("VAT Registration Type");
        SalesHeader.TestField("Payment Terms Code");
        SalesHeader.TestField("Payment Method Code");
        SalesHeader.TestField("EB Type Operation Document");
        SalesHeader.TestField("VAT Registration No.");
        SalesHeader.TestField("VAT Registration Type");
        if SalesHeader."VAT Registration Type" in ['1', '6'] then begin
            SalesHeader.TestField("Sell-to Country/Region Code");
            SalesHeader.TestField("Sell-to Post Code");
            SalesHeader.TestField("Sell-to City");
            SalesHeader.TestField("Sell-to County");
        end;
        SalesHeader.TestField("Sell-to E-Mail");
        //SalesHeader.TestField("Sell-to Phone No.");
        SalesHeader.TestField("Sell-to Customer No.");
        SalesHeader.TestField("Sell-to Customer Name");
        CheckPrePostUbigeo(SalesHeader);
        CheckPrePostReferenceInFormation(SalesHeader);
        CheckPrePostDetraction(SalesHeader);
        CheckPrePostFreeTitle(SalesHeader);
        CheckPrePostSalesLine(SalesHeader);
    end;

    local procedure CheckPrePostUbigeo(var SalesHeader: Record "Sales Header")
    begin
        if SalesHeader."VAT Registration Type" IN ['1', '6'] then begin
            SalesHeader.TestField("Bill-to Post Code");
            SalesHeader.TestField("Bill-to City");
            SalesHeader.TestField("Bill-to County");
            if (SalesHeader."Bill-to Post Code" = '00') or
                (SalesHeader."Bill-to City" = '00') or
                (SalesHeader."Bill-to County" = '00') then
                Error(ErrorUbigeo, StrSubstNo('%1%2%3', SalesHeader."Bill-to Post Code", SalesHeader."Bill-to City", SalesHeader."Bill-to County"));
        end;
    end;

    local procedure CheckPrePostReferenceInFormation(var SalesHeader: Record "Sales Header")
    begin
        if SalesHeader."Legal Document" in ['07', '08'] then begin
            if SalesHeader."Applies-to Document Date Ref." = 0D then
                Error(ErrorYouMustValidOne, SalesHeader.FieldCaption("Applies-to Document Date Ref."));
            if SalesHeader."EB NC/ND Description Type" = '' then
                Error(ErrorYouMustValidOne, SalesHeader.FieldCaption("EB NC/ND Description Type"));
            if SalesHeader."EB NC/ND Support Description" = '' then
                Error(ErrorYouMustValidOne, SalesHeader.FieldCaption("EB NC/ND Support Description"));
            if (SalesHeader."Applies-to Doc. No." = '') and (SalesHeader."Applies-to Doc. No. Ref." = '') then
                Error(ErrorYouMustValidTwo, SalesHeader.FieldCaption("Applies-to Doc. No."), SalesHeader.FieldCaption("Applies-to Doc. No. Ref."));
        end;
    end;

    local procedure CheckPrePostDetraction(var SalesHeader: Record "Sales Header")
    begin
        if (CopyStr(SalesHeader."EB Type Operation Document", 1, 2) = '10') and (not SalesHeader."Sales Detraction") then
            Error(ErrorDetracDoc);
        if not SalesHeader."Sales Detraction" then
            exit;
        if SalesHeader."Sales % Detraction" = 0 then
            Error(ErrorYouMustValidOne, SalesHeader.FieldCaption("Sales % Detraction"));
        if SalesHeader."Sales Amt Detraction" <= 0 then
            Error(ErrorYouMustValidOne, SalesHeader.FieldCaption("Sales Amt Detraction"));
        if SalesHeader."Sales Amt Detraction (LCY)" <= 0 then
            Error(ErrorYouMustValidOne, SalesHeader.FieldCaption("Sales Amt Detraction (LCY)"));
        if not (SalesHeader."VAT Registration Type" in ['1', '6']) then
            Error(ErrorCustDocTypeDetrac);
        if CopyStr(SalesHeader."EB Type Operation Document", 1, 2) <> '10' then
            Error(ErrorDocOpeTypeDetrac);
        EBSetup.TestField("EB Detrac. National Bank Code");
        EBSetup.TestField("EB National Bank Account No.");
        SalesHeader.TestField("Payment Method Code Detrac");
        SalesHeader.TestField("Service Type Detrac");
        CheckDetractionAmount(SalesHeader);
    end;

    local procedure CheckDetractionAmount(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        ErrorOverflowAmt: Label 'The detraction cannot exceed the Invoice', Comment = 'ESM="La detracción no debe exceder la factura"';
        DetractionAmountErr: Label 'The Detraction amount of the entered document is %1. The correct amount is %2.', comment = 'ESM="El importe de detracción del documento ingresado es %1. El importe correcto es %2."';
        SalesAmtDetraction: Decimal;
        SalesAmtDetractionLCY: Decimal;
    begin
        Clear(SalesAmtDetraction);
        Clear(SalesAmtDetractionLCY);
        GLSetup.Get();
        SalesLine.Reset();
        SalesLine.SetCurrentKey("Document Type", "Document No.", "Location Code");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Location Code");
        SalesLine.CalcSums("Amount Including VAT");
        if Round((SalesHeader."Sales % Detraction" * SalesLine."Amount Including VAT") / 100, GLSetup."Amount Rounding Precision") > SalesLine."Amount Including VAT" then
            Error(ErrorOverflowAmt);

        SalesAmtDetraction := Round((SalesHeader."Sales % Detraction" * SalesLine."Amount Including VAT") / 100, GLSetup."Amount Rounding Precision");
        if SalesHeader."Currency Code" = '' then
            SalesAmtDetractionLCY := SalesAmtDetraction
        else
            SalesAmtDetractionLCY := SalesAmtDetraction / SalesHeader."Currency Factor";

        if SalesHeader."Sales Amt Detraction" <> SalesAmtDetraction then
            Error(DetractionAmountErr, Format(SalesHeader."Sales Amt Detraction"), Format(SalesAmtDetraction));
    end;

    local procedure CheckPrePostFreeTitle(var SalesHeader: Record "Sales Header")
    begin
        if not SalesHeader."FT Free Title" then
            exit;
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SalesLine.SetFilter(Quantity, '<%1', 0);
        SalesLine.SetRange("FT Free Title Line", false);
        if SalesLine.FindFirst() then
            repeat
                SalesLine.TestField("Gen. Bus. Posting Group", LSetup."FT Gen. Bus. Posting Group");
            until SalesLine.Next() = 0;
    end;

    local procedure CheckPrePostSalesLine(var SalesHeader: Record "Sales Header")
    var
        IsDiscountOK: Boolean;
        IsDiscountHeader: Boolean;
        IsDiscountLine: Boolean;
        ItemValidation: Record Item;
        GLAcc: Record "G/L Account";
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SalesLine.SetRange("FT Free Title Line", false);
        SalesLine.SetRange("Unit of Measure", '');
        if not SalesLine.IsEmpty then
            Error(ErrorEnterInLine, SalesLine.FieldCaption("Unit of Measure"), SalesLine."Line No.");
        SalesLine.SetRange("Unit of Measure");
        SalesLine.SetFilter(Amount, '%1', 0);
        if not SalesLine.IsEmpty then
            Error(ErrorEnterInLine, SalesLine.FieldCaption("Unit Price"), SalesLine."Line No.");
        SalesLine.SetRange(Amount);
        SalesLine.SetFilter("Line Discount %", '<>%1', 0);
        IsDiscountHeader := SalesHeader."EB Motive discount code" <> '';
        if not IsDiscountHeader then begin
            if not SalesLine.IsEmpty then begin
                SalesLine.SetFilter("EB Motive discount code", '<>%1', '');
                if SalesLine.IsEmpty then
                    Error(ErrorDsctLine, SalesHeader.FieldCaption("EB Motive discount code"), SalesHeader."EB Motive discount code");
                SalesLine.SetRange("EB Motive discount code");
            end;
        end else
            if not SalesLine.IsEmpty then begin
                SalesLine.SetFilter("EB Motive discount code", '<>%1', '');
                if SalesLine.IsEmpty then
                    Error(ErrorMotiveDsctLine);
                SalesLine.SetRange("EB Motive discount code");
            end;
        SalesLine.SetRange("Line Discount %");
        if not IsDiscountHeader then begin
            SalesLine.SetFilter("Inv. Discount Amount", '<>%1', 0);
            if not SalesLine.IsEmpty then
                SalesHeader.TestField("EB Motive discount code");
        end;
        if SalesLine.FindFirst() then
            repeat
                CheckUnitOfMeasure();
                CheckSetupElectroniInvoice();
                case SalesLine.Type of
                    SalesLine.Type::"G/L Account":
                        begin
                            GLAcc.Get(SalesLine."No.");
                            GLAcc.TestField("EB Legal Item Code");
                        end;
                    SalesLine.Type::"Item":
                        begin
                            ItemValidation.Get(SalesLine."No.");
                            ItemValidation.TestField("EB Legal Item Code");
                        end;
                end;
            until SalesLine.Next() = 0;
    end;

    local procedure CheckUnitOfMeasure()
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        UnitOfMeasure.Get(SalesLine."Unit of Measure Code");
        UnitOfMeasure.TestField("EB Comercial Unit of Measure");
    end;

    local procedure CheckSetupElectroniInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        VATPostingSetup.TestField("EB Others Tax Concepts");
        VATPostingSetup.TestField("EB Tax Type Code");
        VATPostingSetup.TestField("EB VAT Type Affectation");
    end;

    //--
    local procedure SetNoSerie(NoSerieCode: Code[20])
    begin
        NoSeries.Get(NoSerieCode);
    end;

    local procedure CheckNoSeries()
    var
        ErrorNoSerie: Label 'The series %1 is not electronic.', comment = 'ESM="La serie %1 no es electónica"';
    begin
        if not NoSeries."EB Electronic Bill" then
            Error(ErrorNoSerie, NoSeries.Code);
    end;

    local procedure fnGetPriceAmountWithoutDscto(DsctoAmount: Decimal; Qty: Decimal; DsctoUnit: Decimal): Decimal
    begin
        Clear(DsctoUnit);
        if Qty <> 0 then
            DsctoUnit := Round(DsctoAmount / Qty, 0.01, '=');
    end;

    local procedure GetSetup(CheckSetup: Boolean)
    begin
        EBSetup.Get();
        CompanyInfo.Get();
        LSetup.Get();
        if CheckSetup then
            CheckGetSetup();
    end;

    local procedure CheckGetSetup()
    begin
        EBSetup.TestField("EB URI Service");
        EBSetup.TestField("EB Invoice");
        EBSetup.TestField("EB Credit Note");
        EBSetup.TestField("EB Debit Note");
        EBSetup.TestField("EB Voided Document");
        EBSetup.TestField("EB Summary Documents");
        EBSetup.TestField("EB Get PDF");
        EBSetup.TestField("EB Get Ticket Status");
        // TestField("EB Get QR");
        EBSetup.TestField("EB Validate Summary Document");
        CompanyInfo.TestField("VAT Registration No.");
        CompanyInfo.TestField("VAT Registration Type");
        CompanyInfo.TestField(Address);
        CompanyInfo.TestField("Country/Region Code");
        CompanyInfo.TestField("Post Code");
        CompanyInfo.TestField(City);
        CompanyInfo.TestField(County);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeFilterNoSeries', '', false, false)]
    local procedure SetOnBeforeFilterNoSeries(var NoSeries: Record "No. Series"; var SalesHeader: Record "Sales Header")
    begin
        NoSeries.SetRange("EB Electronic Bill", SalesHeader."EB Electronic Bill");
    end;

    local procedure MyProcedure()
    var
        myInt: Integer;
    begin

    end;

    var
        GLSetup: Record "General Ledger Setup";
        EBSetup: Record "EB Electronic Bill Setup";
        LSetup: Record "Setup Localization";
        CompanyInfo: Record "Company InFormation";
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        NoSeries: Record "No. Series";
        SalesLine: Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        CatalogoSunat: Record "Legal Document";
        EBEntry: Record "EB Electronic Bill Entry";
        TempFileBlob: Codeunit "Temp Blob";
        SenderXMLTempFileBlob: Codeunit "Temp Blob";
        TempFileBlobResponse: Codeunit "Temp Blob";
        UbigeoMgt: Codeunit "Ubigeo Management";
        SenderXmlConstrutOutStream: OutStream;
        ConstrutOutStream: OutStream;
        DocumentNo: Code[20];
        LegalDocument: Code[10];
        Invoice: Boolean;
        Ticket: Boolean;
        DebitNote: Boolean;
        CreditNote: Boolean;
        StatusQR: Boolean;
        VoidedDocument: Boolean;
        SummaryDocuments: Boolean;
        GetFileDocument: Boolean;
        GetTicketStatus: Boolean;
        QRStatus: Boolean;
        ValidateSummaryDocuments: Boolean;
        FileType: Text;
        DescriptionStatusQR: Text;
        SOAPAction: Text;
        ErrorElectronicMsg: Label 'Can´t select an electronic series for a non-electronic document.', comment = 'ESM="No se puede seleccionar una serie electrónica para un documento no electrónico."';
        ErrorUbigeo: Label 'Ubigeo %1 is not valid.', comment = 'ESM="Ubigeo %1 no es valido."';
        ErrorDocument: Label 'Legal document %1 is not valid.', comment = 'ESM="El documento legal %1 no es valido."';
        ErrorMessage: Label '%1 %2 is not valid.', comment = 'ESM="%1 %2 no es valido."';
        ErrorYouMustValidOne: Label 'You must choose a valid "%1"', comment = 'ESM="Debes elegir un %1 valido."';
        ErrorYouMustValidTwo: Label 'You must choose a valid "%1" or "%2"', comment = 'ESM="Debe elegir un %1 o %2 válido."';
        ErrorEnterInLine: Label 'Enter %1 in line %2.', comment = 'ESM="Ingrese %1 en la línea %2."';
        ErrorCustDocTypeDetrac: Label 'You must choose the document type of Customer 1 or 6 for detraction document.', comment = 'ESM="Debe elegir el tipo de documento de Cliente 1 o 6 para el documento de detracción."';
        ErrorDocOpeTypeDetrac: Label 'You must choose Document Operation Type that begin with 10 for detraction document', comment = 'ESM="Debe elegir el tipo de operación de documento que comienza con 10 para el documento de detracción."';
        ErrorDsctLine: Label 'There is no discount line, when %1 %2 is configured there must be at least one discount line.', Comment = 'ESM="No hay línea de descuento, cuando se configura %1 %2, debe haber al menos una línea con descuento."';
        ErrorMotiveDsctLine: Label 'You must select the discount reason code on the line.', Comment = 'ESM="Debe de seleccionar motivo de descuento para la linea."';
        ErrorDetracDoc: Label 'For document without detraction the document operation type should not start with %1', comment = 'ESM="Para documentos sin detracción, el tipo de operación de documento no debe comenzar con %1."';
}