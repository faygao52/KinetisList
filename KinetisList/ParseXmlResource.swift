//
//  ParseXmlResource.swift
//  KinetisList
//
//  Created by MAD-Test on 15-1-22.
//  Copyright (c) 2015年 FSL. All rights reserved.
//

import Foundation
public class ParseXmlResource{
    let FEATURES:String = "FEATURES"
    let HEADER:String = "HEADER"
    let FAMILY:String = "FAMILY"
    let DEVICE:String = "DEVICE"
    let ITEM:String = "ITEM"
    
    let HEADER_NAME:String = DBdefine.Header().COLUMN_NAME_NAME
    let HEADER_TYPE:String = DBdefine.Header().COLUMN_NAME_TYPE
    let HEADER_WIDTH = DBdefine.Header().COLUMN_NAME_WIDTH
    let HEADER_SHOW = DBdefine.Header().COLUMN_NAME_SHOW
    
    let ATTR_Name:String = "Name"
    let ATTR_Data:String = "Data"
    
    var itemIndex:Int = 0
    var NumColumns:Int = 0
    var HeaderMap = Dictionary<String,Int>()
    
    var xDeviceRow:[String] = [String]()
    var familyName:String?

    var xmls:[XMLIndexer] = [XMLIndexer]()
    var sourceName:[String] = ["Hot parts", "Conditional parts", "Legacy parts"]
    init(xmlfiles:String...){
        for xmlfile in xmlfiles{
            self.xmls.append(SWXMLHash.parse(xmlfile))
        }
    }
    
    func getData(inout xmlHeader:Array<DBdefine.HeaderItem>, inout xmlDevice:[[String]]){
        //parse header
        var i:Int = 0;
        for xml in xmls{
            for head in xml[FEATURES][HEADER][ITEM]{
                //var Header_Name = head[ITEM].element!.attributes["Width"]!
                var xHeader = DBdefine.HeaderItem()
                xHeader.Name  = head.element!.attributes[HEADER_NAME]!
                xHeader.Title = head.element!.attributes[ATTR_Data]!
                xHeader.Type = head.element!.attributes[HEADER_TYPE]!
                xHeader.width = head.element!.attributes[HEADER_WIDTH]!.toInt()!
                if((head.element!.attributes[HEADER_SHOW]) != nil && head.element!.attributes[HEADER_SHOW] == "false"){
                    xHeader.Visible = false
                }
                HeaderMap[xHeader.Name] = itemIndex
                xmlHeader.append(xHeader)
                itemIndex++
            }
            //parse devices
            xDeviceRow = [String](count: xmlHeader.count, repeatedValue: (""))
            for family in xml[FEATURES][FAMILY]{
                familyName = family.element!.attributes[ATTR_Name]
                for devices in family[DEVICE]{
                    var column:Int? = HeaderMap["SubFamily"]
                    if((column) != nil){
                        xDeviceRow[column!] = familyName!
                    }
                    for items in devices[ITEM]{
                        var itemName:String = items.element!.attributes[ATTR_Name]!
                        column = HeaderMap[itemName]
                        if((column) != nil){
                            xDeviceRow[column!] = items.element!.attributes[ATTR_Data]!
                        }
                    }
                    xDeviceRow[xDeviceRow.count] = sourceName[i]
                    xmlDevice.append(xDeviceRow)
                }
            }
        }
        i++
    }
    
    
}