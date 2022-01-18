codeunit 51046 "EB Send Electronic Management"
{
    trigger OnRun()
    var
        lcElectronicBilliEntry: Record "EB Electronic Bill Entry";
    begin
        lcElectronicBilliEntry.Reset();
        lcElectronicBilliEntry.SetRange("EB Status Send Doc. Cust", lcElectronicBilliEntry."EB Status Send Doc. Cust"::Open);
        lcElectronicBilliEntry.SetRange("EB Ship Status", lcElectronicBilliEntry."EB Ship Status"::Succes);
        if lcElectronicBilliEntry.FindSet() then
            repeat
                SendElectronicDocument(lcElectronicBilliEntry);
                lcElectronicBilliEntry."EB Status Send Doc. Cust" := lcElectronicBilliEntry."EB Status Send Doc. Cust"::Send;
                lcElectronicBilliEntry."EB Send Date" := CreateDateTime(Today, Time);
                lcElectronicBilliEntry."EB Send User Id." := UserId;
                lcElectronicBilliEntry.Modify();
            until lcElectronicBilliEntry.Next() = 0;
    end;

    local procedure LevantaColas()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.RESET;
        JobQueueEntry.SETFILTER(Status, '%1', JobQueueEntry.Status::Error);
        IF JobQueueEntry.FINDFIRST THEN
            REPEAT
                JobQueueEntry.Restart;
            UNTIL JobQueueEntry.NEXT = 0;
    end;

    procedure SendElectronicDocument(var pElectronicBilliEntry: Record "EB Electronic Bill Entry")
    var
        SMTPMail: Codeunit "SMTP Mail";
        Mails: List of [Text];
        MailsCC: List of [Text];
        Company: Record "Company Information";
        SMTPSetup: Record "SMTP Mail Setup";
        EBElectronicSetup: Record "EB Electronic Bill Setup";
        Divisa: Code[10];
        Contact: Record Contact;
        ContactBus: Record "Contact Business Relation";
        lcSalesInvoiceHeader: Record "Sales Invoice Header";
        lcCrediMemoHeader: Record "Sales Cr.Memo Header";
        lcCustomer: Record Customer;
        aux: Boolean;
        Base64Convert: Codeunit "Base64 Convert";
        TempFileBlobRespFileDoc: Codeunit "Temp Blob";
        OutStreamFile: OutStream;
        InStreamFile: InStream;
        lcDocumentAttachment: Record "Document Attachment";
        FullFileName: Text;
        lcLegalDocument: Record "Legal Document";
        lcCustomerNo: Code[20];
        lcAmountVAT: Decimal;
        lcDueDate: Date;
        Picture: Text;
        PictureText: Text;
        FileManagement: Codeunit "File Management";
    begin
        DocumentNo := pElectronicBilliEntry."EB Document No.";
        LegalDocument := pElectronicBilliEntry."EB Legal Document";

        if lcSalesInvoiceHeader.Get(DocumentNo) then begin
            lcCustomerNo := lcSalesInvoiceHeader."Bill-to Customer No.";
            lcSalesInvoiceHeader.CalcFields("Amount Including VAT");
            lcAmountVAT := lcSalesInvoiceHeader."Amount Including VAT";
            lcDueDate := lcSalesInvoiceHeader."Due Date";
            if lcSalesInvoiceHeader."Currency Code" <> '' then
                Divisa := lcSalesInvoiceHeader."Currency Code"
            else
                Divisa := 'PEN';
        end else begin
            lcCrediMemoHeader.Get(DocumentNo);
            lcCustomerNo := lcCrediMemoHeader."Bill-to Customer No.";
            lcCrediMemoHeader.CalcFields("Amount Including VAT");
            lcAmountVAT := lcCrediMemoHeader."Amount Including VAT";
            lcDueDate := lcCrediMemoHeader."Due Date";
            if lcCrediMemoHeader."Currency Code" <> '' then
                Divisa := lcCrediMemoHeader."Currency Code"
            else
                Divisa := 'PEN';
        end;


        lcCustomer.Get(lcCustomerNo);
        // CompanyInfo.Get();
        // if CompanyInfo."E-Mail" <> '' then
        //     Mails.Add(CompanyInfo."E-Mail");

        // ContactBus.Reset();
        // ContactBus.SetRange("No.", lcCustomer."VAT Registration No.");
        // ContactBus.SetRange("Business Relation Code", 'CLIENTES');
        // if ContactBus.FindFirst() then begin
        //     Contact.Reset();
        //     Contact.SetRange("Company No.", ContactBus."Contact No.");
        //     Contact.SetRange("Send Emails", true);
        //     if Contact.FindSet() then begin
        //         repeat
        //             if (lcCustomer."E-Mail" = '') and (Contact."E-Mail" = '') then
        //                 Error('El contacto %1 del cliente %2 - %3 no tiene configurado un correo electronico.', Contact."No.", lcCustomer."VAT Registration No.", lcCustomer.Name);
        //             Mails.Add(Contact."E-Mail");
        //         until Contact.Next() = 0;
        //     end else
        //         if (lcCustomer."E-Mail" = '') then begin
        //             Error('El cliente %1 - %2 no tiene contactos asociados para enviar.', lcCustomer."VAT Registration No.", lcCustomer.Name);
        //         end;
        // end else
        //     if (lcCustomer."E-Mail" = '') then begin
        //         Error('El cliente %1 - %2 no tiene contactos asociados para enviar.', lcCustomer."VAT Registration No.", lcCustomer.Name);
        //     end;julissavergel@power.com.pe

        if lcCustomer."E-Mail" <> '' then
            Mails.Add(lcCustomer."E-Mail");

        Company.Get();
        if Company."E-Mail" <> '' then
            MailsCC.Add(Company."E-Mail");
        lcLegalDocument.Get(lcLegalDocument."Option Type"::"SUNAT Table", '10', LegalDocument);

        SMTPSetup.Get();
        EBElectronicSetup.Get();
        if EBElectronicSetup."Send electronic documents to" <> '' then
            Mails.Add(EBElectronicSetup."Send electronic documents to");
        SMTPMail.CreateMessage('', SMTPSetup."User ID", Mails, StrSubstNo('Has recibido una ' + lcLegalDocument.Description + ' Nro. %1 de AIRSEALOGISTICS SAC', DocumentNo), '');
        SMTPMail.AddCC(MailsCC);
        SMTPMail.AppendBody('<p><font face="Arial">Estimado <b>' + lcCustomer.Name + '</b>:</font><br /><br /></p>' +
        '<p><font face="Arial">Te ha llegado una ' + lcLegalDocument.Description + ' de <b> AIRSEALOGISTICS SAC </b> con las siguientes características:</font><br /><br /></p>');

        SMTPMail.AppendBody('<p style="padding-left:20px;"><font face="Arial"> <b>N° de ' + lcLegalDocument.Description + '  : </b> ' + DocumentNo + '</font></p>');
        SMTPMail.AppendBody('<p style="padding-left:20px;"><font face="Arial"> <b>Vencimiento    : </b>' + Format(lcDueDate, 0, '<Day,2>-<Month,2>-<Year4>') + '</font></p>');

        SMTPMail.AppendBody('<p style="padding-left:20px;"><font face="Arial"> <b>Importe total  : ' + Divisa + '</b> ' + FormatNumber(lcAmountVAT) + '</font><br /><br /></p>');
        SMTPMail.AppendBody('<p><font face="Arial">En caso de tener alguna duda al respecto, favor de enviar un correo a nuestro centro de control: facturacion.peru@airsea-log.com</font><br /><br /></p>');
        SMTPMail.AppendBody('<p><font face="Arial">Para más información, puedes revisar la web de : https://unionlabelnet.azurewebsites.net</font><br /><br /></p>');
        SMTPMail.AppendBody('<p><font face="Arial">Atentamente,</font><br /><br /></p>');
        // Picture := 'Firma.jpg';
        // EBElectronicSetup.CalcFields("Picture Signature");
        // TempFileBlobRespFileDoc.CreateOutStream(OutStreamFile);
        // EBElectronicSetup."Picture Signature".CreateInStream(InStreamFile);

        //TempFileBlobRespFileDoc.CreateInStream(InStreamFile);
        //FileManagement.BLOBImportFromServerFile(TempFileBlobRespFileDoc, SMTPSetup."Picture Signature".EXPORT(Picture));
        //Base64Convert.ToBase64(SMTPSetup."Picture Signature".EXPORT(Picture));
        // if SMTPSetup."Picture Signature".HasValue then begin
        //     SMTPSetup."Picture Signature".CreateInStream(InStreamFile);
        // while not InStreamFile.EOS do begin
        //     Picture := '';
        //     InStreamFile.ReadText(Picture);
        //     PictureText += Picture;
        // end;
        //end;

        // SMTPMail.AppendBody('<br><div><img src="data:image/png;base64, ' + Base64Convert.ToBase64(InStreamFile) + '" alt="Red dot" /></div>');
        //Adjunto PDF
        GetDocumentFile(0);
        TempFileBlobRespFileDoc.CreateOutStream(OutStreamFile);
        Base64Convert.FromBase64(PDFText, OutStreamFile);
        TempFileBlobRespFileDoc.CreateInStream(PDFInStream);
        SMTPMail.AddAttachmentStream(PDFInStream, StrSubstNo('%1-%2-%3.%4', CompanyInfo."VAT Registration No.", LegalDocument, DocumentNo, 'pdf'));

        //Adjunto XML
        GetDocumentFile(1);
        TempFileBlobRespFileDoc.CreateOutStream(OutStreamFile);
        Base64Convert.FromBase64(XMLText_, OutStreamFile);
        TempFileBlobRespFileDoc.CreateInStream(XMLInStream);
        SMTPMail.AddAttachmentStream(XMLInStream, StrSubstNo('%1-%2-%3.%4', CompanyInfo."VAT Registration No.", LegalDocument, DocumentNo, 'xml'));

        //Adjunto CDR
        GetDocumentFile(2);
        TempFileBlobRespFileDoc.CreateOutStream(OutStreamFile);
        Base64Convert.FromBase64(CDRText, OutStreamFile);
        TempFileBlobRespFileDoc.CreateInStream(CDRInStream);
        SMTPMail.AddAttachmentStream(CDRInStream, StrSubstNo('CDR-%1-%2-%3.%4', CompanyInfo."VAT Registration No.", LegalDocument, DocumentNo, 'xml'));

        //Enviar adjuntos
        lcDocumentAttachment.Reset();
        lcDocumentAttachment.SetRange("Table ID", Database::"Sales Invoice Header");
        lcDocumentAttachment.SetRange("No.", DocumentNo);
        if lcDocumentAttachment.FindSet() then
            repeat
                FullFileName := lcDocumentAttachment."File Name" + '.' + lcDocumentAttachment."File Extension";
                TempFileBlobRespFileDoc.CreateOutStream(OutStreamFile);
                lcDocumentAttachment."Document Reference ID".ExportStream(OutStreamFile);
                TempFileBlobRespFileDoc.CreateInStream(InStreamFile);
                SMTPMail.AddAttachmentStream(InStreamFile, FullFileName);
            until lcDocumentAttachment.Next() = 0;

        SMTPMail.Send();

        pElectronicBilliEntry."EB Status Send Doc. Cust" := pElectronicBilliEntry."EB Status Send Doc. Cust"::Send;
        pElectronicBilliEntry."EB Send Date" := CreateDateTime(Today, Time);
        pElectronicBilliEntry."EB Send User Id." := UserId;
        // pElectronicBilliEntry.fnAssignedStatusLog(DocumentNo, pElectronicBilliEntry."EB Status Send Doc. Cust"::Send);
        pElectronicBilliEntry.Modify();
        Message('Se envio correctamente.');
    end;

    procedure GetDocumentFile(FileTypeOption: Option)
    var
        LegalDocumentInt: Integer;
    begin
        case FileTypeOption of
            0:
                FileType := 'PDF';
            1:
                FileType := 'XML';
            2:
                FileType := 'CDR';
        end;

        GetSetup(true);
        CreateXmlGetDocument();
        ConsumeService();
    end;

    local procedure GetSetup(CheckSetup: Boolean)
    begin
        EBSetup.Get();
        LSetup.Get();
        CompanyInfo.Get();
        if CheckSetup then
            CheckGetSetup();
    end;

    local procedure CheckGetSetup()
    begin
        EBSetup.TestField("EB URI Service");
        EBSetup.TestField("EB Get PDF");
        CompanyInfo.TestField("VAT Registration No.");
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
        TempFileBlob.CreateInStream(NewFileInStream);
        HttpContent.WriteFrom(NewFileInStream);
        HttpContent.GetHeaders(HttpHeadersContent);
        HttpHeadersContent.Remove('Content-Type');
        HttpHeadersContent.Add('Content-Type', 'text/xml;charset=utf-8');
        HttpHeadersContent.Add('SOAPAction', EBSetup."EB Get PDF");
        HttpClient.SetBaseAddress(EBSetup."EB URI Service");
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
    begin
        case HttpStatusCode of
            200:
                begin
                    ReadResponseHttpStatus200(ResponseInStream);
                end;
            else begin
                    Error(StrSubstNo('Respuesta %1', Format(HttpStatusCode)));
                end;
        end;
    end;

    local procedure ReadResponseHttpStatus200(ResponseInStream: InStream)
    var
        XMLBuffer: Record "XML Buffer" temporary;
        SunatDescription: Text;
    begin
        XMLBuffer.Reset();
        XMLBuffer.DeleteAll();
        XMLBuffer.LoadFromStream(ResponseInStream);
        XMLBuffer.Reset();

        SetFileDocument(XMLBuffer, SunatDescription);
        if SunatDescription <> '' then
            Error(SunatDescription);
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
            //TempFileBlobRespFileDoc.CreateOutStream(OutStreamFile);
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
            // Base64Convert.FromBase64(RespFileText, OutStreamFile);
            // TempFileBlobRespFileDoc.CreateInStream(InStreamFileDoc);
            case FileType of
                'PDF':
                    begin
                        // ToFileName := StrSubstNo('%1-%2.%3', DocumentNo, LegalDocument, 'pdf');
                        // DownloadFromStream(InStreamFileDoc, DialogTitle, '', 'All Files (*.*)|*.pdf', ToFileName);
                        //PDFInStream := InStreamFileDoc;
                        PDFText := RespFileText;
                    end;
                'XML':
                    begin
                        // ToFileName := StrSubstNo('%1-%2.%3', DocumentNo, LegalDocument, 'xml');
                        // DownloadFromStream(InStreamFileDoc, DialogTitle, '', 'All Files (*.*)|*.xml', ToFileName);
                        //XMLInStream := InStreamFileDoc;
                        XMLText_ := RespFileText;
                    end;
                'CDR':
                    begin
                        //ToFileName := StrSubstNo('%1-%2.%3', DocumentNo, LegalDocument, 'xml');
                        //DownloadFromStream(InStreamFileDoc, DialogTitle, '', 'All Files (*.*)|*.xml', ToFileName);
                        CDRText := RespFileText;
                    end;
            end;
            //SunatDescription := StrSubstNo('Archivo %1 correctamente descargado', FileType);
        end else
            SunatDescription := 'Ocurrio un problema, volver a intentar.';
    end;

    local procedure FormatNumber(ValueDecimal: Decimal): Text
    begin
        exit(Format(ValueDecimal, 0, '<Integer Thousand><Decimals>'));
    end;


    var
        FileType: Text;
        DocumentNo: Code[20];
        LegalDocument: Code[10];
        EBSetup: Record "EB Electronic Bill Setup";
        LSetup: Record "Setup Localization";
        CompanyInfo: Record "Company InFormation";
        TempFileBlob: Codeunit "Temp Blob";
        SenderXMLTempFileBlob: Codeunit "Temp Blob";
        TempFileBlobResponse: Codeunit "Temp Blob";
        SenderXmlConstrutOutStream: OutStream;
        ConstrutOutStream: OutStream;
        PDFInStream: InStream;
        XMLInStream: InStream;
        CDRInStream: InStream;
        PDFText: Text;
        XMLText_: Text;
        CDRText: Text;
}
