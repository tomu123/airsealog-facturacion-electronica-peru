page 59456 "EB XML Buffer View"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "XML Buffer";
    SourceTableTemporary = true;
    Caption = 'XML Buffer View', comment = 'ESM="Mostrar XML"';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = All;
                    Caption = 'Entry No.', comment = 'ESM="Nro. Movimiento"';
                }
                field(Type; Type)
                {
                    ApplicationArea = All;
                    Caption = 'Type', comment = 'ESM="Tipo"';
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name', comment = 'ESM="Nombre"';
                }
                field(Path; Path)
                {
                    ApplicationArea = All;
                    Caption = 'Path', comment = 'ESM="Ruta"';
                }
                field(Value; Value)
                {
                    ApplicationArea = All;
                    Caption = 'Value', comment = 'ESM="Valor"';
                }
                field(Depth; Depth)
                {
                    ApplicationArea = All;
                }
                field("Parent Entry No."; "Parent Entry No.")
                {
                    ApplicationArea = All;
                    Caption = 'Parent Entry No.', comment = 'ESM="Nro. movimiento padre"';
                }
                field("Is Parent"; "Is Parent")
                {
                    ApplicationArea = All;
                    Caption = 'Is Parent', comment = 'ESM="Es padre"';
                }
                field("Data Type"; "Data Type")
                {
                    ApplicationArea = All;
                    Caption = 'Data Type', comment = 'ESM="Tipo Dato"';
                }
                field(Code; Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code', comment = 'ESM="Código"';
                }
                field("Node Name"; "Node Name")
                {
                    ApplicationArea = All;
                    Caption = 'Node Name', comment = 'ESM="Nombre Nodo"';
                }
                field("Has Attributes"; "Has Attributes")
                {
                    ApplicationArea = All;
                    Caption = 'Has Attributes', comment = 'ESM="Tiene Atributos"';
                }
                field("Node Number"; "Node Number")
                {
                    ApplicationArea = All;
                    Caption = 'Node Number', comment = 'ESM="Nro. Nodo"';
                }
                field(Namespace; Namespace)
                {
                    ApplicationArea = All;
                }
                field("Import ID"; "Import ID")
                {
                    ApplicationArea = All;
                }
                field("Value BLOB"; "Value BLOB")
                {
                    ApplicationArea = All;
                }
            }
        }
        area(Factboxes)
        {

        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {
                ApplicationArea = All;

                trigger OnAction();
                begin

                end;
            }
        }
    }

    procedure SetBufferTemp(var XmlBufferTemp: Record "XML Buffer" temporary)
    begin
        XmlBufferTemp.Reset();
        if XmlBufferTemp.FindFirst() then
            repeat
                Init();
                TransferFields(XmlBufferTemp, true);
                Insert();
            until XmlBufferTemp.Next() = 0;
        Reset();
    end;
}