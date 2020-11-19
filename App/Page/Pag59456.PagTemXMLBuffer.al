page 59456 "EB XML Buffer View"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "XML Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = All;
                }
                field(Type; Type)
                {
                    ApplicationArea = All;
                }
                field(Name; Name)
                {
                    ApplicationArea = All;
                }
                field(Path; Path)
                {
                    ApplicationArea = All;
                }
                field(Value; Value)
                {
                    ApplicationArea = All;
                }
                field(Depth; Depth)
                {
                    ApplicationArea = All;
                }
                field("Parent Entry No."; "Parent Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Is Parent"; "Is Parent")
                {
                    ApplicationArea = All;
                }
                field("Data Type"; "Data Type")
                {
                    ApplicationArea = All;
                }
                field(Code; Code)
                {
                    ApplicationArea = All;
                }
                field("Node Name"; "Node Name")
                {
                    ApplicationArea = All;
                }
                field("Has Attributes"; "Has Attributes")
                {
                    ApplicationArea = All;
                }
                field("Node Number"; "Node Number")
                {
                    ApplicationArea = All;
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