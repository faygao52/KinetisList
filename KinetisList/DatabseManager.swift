//
//  DatabseManager.swift
//  KinetisList
//
//  Created by MAD-Test on 15-1-22.
//  Copyright (c) 2015年 FSL. All rights reserved.
//
import Foundation
import SQLite

let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first as String

let db = Database("\(path)/db.sqlite3")

//table query
let Header_table = db[DBdefine.Header().TABLE_NAME]
let Device_table = db[DBdefine.Devices().TABLE_NAME]
let Column_table = db[DBdefine.Column().TABLE_NAME]
//statement for header table
let Header_ID = Expression<Int>(DBdefine.Header()._ID)
let Header_Name = Expression<String>(DBdefine.Header().COLUMN_NAME_NAME)
let Header_Title = Expression<String>(DBdefine.Header().COLUMN_NAME_TITLE)
let Header_Type = Expression<String>(DBdefine.Header().COLUMN_NAME_TYPE)
let Header_Width = Expression<Int>(DBdefine.Header().COLUMN_NAME_WIDTH)
let Header_Visible = Expression<Bool>(DBdefine.Header().COLUMN_NAME_SHOW)

//statement for coloumn table
let Column_Name = Expression<String>(DBdefine.Column().COLUMN_NAME_NAME)
let Column_Type = Expression<String>(DBdefine.Column().COLUMN_NAME_TYPE)
let Column_Text = Expression<String>(DBdefine.Column().COLUMN_NAME_TEXT)
let Column_Value = Expression<Int>(DBdefine.Column().COLUMN_NAME_VALUE)
let Column_Visible = Expression<Bool>(DBdefine.Column().COLUMN_NAME_SHOW)

var xmlHeader = Array<DBdefine.HeaderItem>()
var xmlDevice = [[String]]()
public class DataBaseManager{
    let RESET_DATABASE:Bool = false

    init(){
        if(RESET_DATABASE){
            db.drop(table:Header_table)
            db.drop(table: Device_table)
            db.drop(table: Column_table)
            
            let PXR = ParseXmlResource(xmlfiles: "\(path)/test.xml","")
            PXR.getData(xmlHeader, xmlDevice: xmlDevice)
            fillTable_Header()
            fillTable_Devices()
            fillTable_Column()
        }
        
        
    }
    func fillTable_Header(){
        db.execute("CREATE TABLE " + DBdefine.Header().TABLE_NAME + " ("
            + DBdefine.Header()._ID + " INTEGER PRIMARY KEY,"
            + DBdefine.Header().COLUMN_NAME_NAME + " TEXT,"
            + DBdefine.Header().COLUMN_NAME_TITLE + " TEXT,"
            + DBdefine.Header().COLUMN_NAME_TYPE + " TEXT,"
            + DBdefine.Header().COLUMN_NAME_WIDTH + " INTEGER,"
            + DBdefine.Header().COLUMN_NAME_SHOW + " BOOLEAN"
            + ");")
        let numColumn:Int = xmlHeader.count
        for var iColumn = 0; iColumn < numColumn; ++iColumn {
            let xHeader:DBdefine.HeaderItem = xmlHeader[iColumn]
            if let insertID = Header_table.insert(Header_Name <- xHeader.Name, Header_Title <- xHeader.Title, Header_Type <- xHeader.Type, Header_Width <- xHeader.width, Header_Visible <- xHeader.Visible){
                println("inserted ID: \(insertID)")
            }
        }
    }
    
    func fillTable_Devices(){
        var columnList:String = ""
        let numColumn:Int = xmlHeader.count
        for var iColumn = 0; iColumn < numColumn; ++iColumn {
            let xHeader:DBdefine.HeaderItem = xmlHeader[iColumn]
            if xHeader.Type == ("INTEGER"){
                columnList += ", `" + xHeader.Name + "` INTEGER"
            }else{
                columnList += ", `" + xHeader.Name + "` TEXT"
            }
        }
        db.execute("CREATE TABLE " + DBdefine.Devices().TABLE_NAME
        + " (_id INTEGER PRIMARY KEY"
        + columnList + ");")
        
        columnList = ""
        var valueList = ""
        var numDev = xmlDevice.count
        for var iDev = 0; iDev < numDev; ++iDev {
            let xDev:[String] = xmlDevice[iDev];
            var iColumn = 0
            for iColumn = 0; iColumn < numColumn; ++iColumn {
                let xHeader:DBdefine.HeaderItem = xmlHeader[iColumn]
                columnList += "`"+xHeader.Name+"`, "
                if xHeader.Type == ("INTEGER") {
                    var number = 0;
                    let intStr = xDev[iColumn].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    if intStr == ("-") {number = -1}
                    else {number = intStr.toInt()!}
                    valueList += String(number) + ", "
                }else{
                    valueList += "`" + xDev[iColumn] + "`, "
                }
            }
            columnList += "`SourceID`"
            valueList += "`"+xDev[iColumn]+"`"

            db.execute("INSERT INTO " + DBdefine.Devices().TABLE_NAME + "( " + columnList + " ) VALUES ( " + valueList + " );")
        }
        
    }
    
    func fillTable_Column(){
        db.execute("CREATE TABLE " + DBdefine.Column().TABLE_NAME + " ("
            + DBdefine.Column()._ID + " INTEGER PRIMARY KEY,"
            + DBdefine.Column().COLUMN_NAME_NAME + " TEXT,"
            + DBdefine.Column().COLUMN_NAME_TYPE + " TEXT,"
            + DBdefine.Column().COLUMN_NAME_TEXT + " TEXT,"
            + DBdefine.Column().COLUMN_NAME_VALUE + " INTEGER,"
            + DBdefine.Column().COLUMN_NAME_SHOW + " BOOLEAN"
            + ");")
        
        var numColumn = xmlHeader.count
        for var iColumn = 2; iColumn < numColumn; ++iColumn {	// skip the "Family" and "Part"
            let xHeader:DBdefine.HeaderItem = xmlHeader[iColumn]
            
            // Look for all available values in the column
            var select = Expression<String>("`"+xHeader.Name+"`");
            let query = Device_table.select(select).order(select.asc)
            for cursor in query{
                var text:String
                var value:Int
                // check the value of DBdefine.Header.COLUMN_NAME_TYPE
                if(xHeader.Type == ("STRING")){
                    text = cursor[select]
                    value = 0
                }else{
                    text = cursor[select]
                    value = cursor[select].toInt()!
                }
                
                if let insertID = Column_table.insert(Column_Name <- xHeader.Name, Column_Type <- xHeader.Type, Column_Text <- text, Column_Value <- value, Header_Visible <- true)
                    {
                        println("inserted ID: \(insertID)")
                    }
            }
        }
    }
    
    public func getListData(family:String,var hList:Array<DBdefine.HeaderItem>, var dList:Array<DBdefine.DeviceRow>){
        if(!hList.isEmpty){
            hList = Array<DBdefine.HeaderItem>()
            dList = Array<DBdefine.DeviceRow>()
        }
        readHeaderList(hList,All: false)
        readDeviceList(family,HeaderList: hList,devList: dList)
    }
    
    func readHeaderList(var HeaderList:Array<DBdefine.HeaderItem> ,All: Bool){
        var results: Query
        if(All){
            results = Header_table.select(Header_Name,Header_Title,Header_Type,Header_Width,Header_Visible).order(Header_ID)
        }else{
            results = Header_table.select(Header_Name,Header_Title,Header_Type,Header_Width,Header_Visible).filter(Header_Visible).order(Header_ID)
        }
        for result in results{
            var headerItem =  DBdefine.HeaderItem()
            headerItem.Name = result[Header_Name]
            headerItem.Title = result[Header_Title]
            headerItem.Type = result[Header_Type]
            headerItem.width = result[Header_Width]
            headerItem.Visible = result[Header_Visible]
            HeaderList.append(headerItem)
        }
    }
    
    func readDeviceList(let family:String, let HeaderList:Array<DBdefine.HeaderItem>, var devList:Array<DBdefine.DeviceRow>){
        
    }
}