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
let Column_ID = Expression<Int>(DBdefine.Column()._ID)
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
            PXR.getData(&xmlHeader, xmlDevice: &xmlDevice)
            fillTable_Header()
            fillTable_Devices()
            fillTable_Column()
        }
        
        
    }
    //Create Header table and insert data
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
    
    //Create Device table and insert data
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
    
    //Create Column table and insert data
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
    
    public func getListData(family:String,inout hList:Array<DBdefine.HeaderItem>, inout dList:Array<DBdefine.DeviceRow>){
        if(!hList.isEmpty){
            hList = Array<DBdefine.HeaderItem>()
            dList = Array<DBdefine.DeviceRow>()
        }
        readHeaderList(&hList,All: false)
        readDeviceList(family,HeaderList: hList,devList: &dList)
    }
    
    //return data from Header table
    public func readHeaderList(inout HeaderList:Array<DBdefine.HeaderItem> ,All: Bool){
        var results: Query
        if(All){
            results = Header_table.select(Header_Name,Header_Title,Header_Type,Header_Width,Header_Visible).order(Header_ID)
        }else{
            results = Header_table.select(Header_Name,Header_Title,Header_Type,Header_Width,Header_Visible).filter(Header_Visible).order(Header_ID)
        }
        if(results.count != 0){
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
    }
    
    //return data from devices table , with visible column and value
    private func readDeviceList(let family:String, let HeaderList:Array<DBdefine.HeaderItem>, inout devList:Array<DBdefine.DeviceRow>){
        var results:Query
        results = Column_table.select(Column_Name,Column_Type,Column_Text,Column_Value).filter(Column_Visible).order(Column_ID)
        var filterType = ""
        var selections:String = ""
        if(family != "*"){
            selections += "SubFamily = "+family
        }
        if(results.count != 0){
            for result in results{
                if(!selections.isEmpty){selections += " AND "}
                selections += "`"+result[Column_Name]+"` <>"
                filterType = result[Column_Type]
                if(filterType == "INTEGER"){selections += String(result[Column_Value])}
                else{ selections += result[Column_Text]}
            }
        }
        
        var projection:String = ""
        var iCol = 0
        for(iCol; iCol < HeaderList.count; ++iCol){
            projection += "`"+HeaderList[iCol].Name+"`, "
        }
        projection += "`SourceID`"
        
        let seleExpression = Expression<Bool?>(selections)
        let orderExpreesion = Expression<String>(DBdefine.Devices().DEFAULT_SORT_ORDER)
        let stmt = Device_table.filter(seleExpression).order(orderExpreesion)
        
        let test = db.run("SELECT "+projection+" FROM "+DBdefine.Devices().TABLE_NAME+" WHERE ("+selections+") ORDER BY "+DBdefine.Devices().DEFAULT_SORT_ORDER)
        for row in stmt{
            var device = DBdefine.DeviceRow(columns:HeaderList.count)
            for(var iParam = 0; iParam < HeaderList.count; ++iParam){
                if(HeaderList[iParam].Type == "INTEGER"){
                    let expression = Expression<Int>(HeaderList[iParam].Name)
                    device.Param[iParam] = String(row.get(expression))
                }else{
                    let expression = Expression<String>(HeaderList[iParam].Name)
                    device.Param[iParam] = row.get(expression)
                }
            }
            devList.append(device)
        }
    }
    
    //get source list
    public func getSource(inout sourceList:Array<String>, inout cntList:Array<Int>){
        let SourceExp = Expression<String>("SourceID")
        let countExp = Expression<Int>("COUNT(*)")
        let query = Device_table.select(SourceExp,countExp).group(SourceExp).order(countExp.desc)
        var total:Int = 0
        for result in query{
            if(!result.get(SourceExp).isEmpty){
                sourceList.append(result.get(SourceExp))
                cntList.append(result.get(countExp))
            }
            total += result.get(countExp)
        }
        sourceList.append("All parts")
        cntList.append(total)
    }
    
    public func getFamily(let SourceID:String, inout familyList:Array<String>, inout cntList:Array<Int>){
        let SourceExp = Expression<String>("SourceID")
        //let countExp = Expression<Int>("COUNT(*)")
        let FamilyExp = Expression<String>("SubFamily")
        var query:Query
        if(SourceID == "All parts"){
            query = Device_table.select(FamilyExp,count(*)).group(FamilyExp).order(count(*).desc)
        }else{
            query = Device_table.select(FamilyExp,count(*)).filter(SourceExp == SourceID).group(FamilyExp).order(count(*).desc)
        }
        var total:Int = 0
        for result in query{
            if(!result.get(SourceExp).isEmpty){
                familyList.append(result.get(FamilyExp))
                cntList.append(result.get(count(*)))
            }
            total += result.get(count(*))
        }
        familyList.append("All families")
        cntList.append(total)
    }
    

    public func getColumnValues(strFamily:String, selColumn:String) -> Array<DBdefine.ColumnValue>{
        var first:Bool
        var cnArray:Array<DBdefine.ColumnValue> = []
        var results:Query
        results = Column_table.select(Column_Name,Column_Type,Column_Text,Column_Value).filter(Column_Visible && (Column_Name != selColumn)).order(Column_ID)
       // db.excuteQuery()
        var filterType = ""
        var SQL:String = "SELECT "+DBdefine.Column().COLUMN_NAME_TEXT+", "+DBdefine.Column().COLUMN_NAME_VALUE + ", "+DBdefine.Column().COLUMN_NAME_SHOW + " FROM "+DBdefine.Column().TABLE_NAME + " WHERE "+DBdefine.Column().COLUMN_NAME_NAME + " = " + selColumn
        if(strFamily != "*"){
            SQL += " AND " + DBdefine.Column().COLUMN_NAME_TEXT + " IN (SELECT `" + selColumn + "` FROM " + DBdefine.Devices().TABLE_NAME + " WHERE SubFamily= " + strFamily
            first = false
        }else{
            SQL += " AND " + DBdefine.Column().COLUMN_NAME_TEXT + " IN (SELECT `" + selColumn + "` FROM " + DBdefine.Devices().TABLE_NAME + " WHERE "
            first = true
        }
        if(results.count != 0){
            for result in results{
                if(!SQL.isEmpty && !first){SQL += " AND "}
                SQL += "`"+result.get(Column_Name)+"` <> "
                filterType = result.get(Column_Type)
                if(filterType == "INTEGER"){SQL += String(result.get(Column_Value))}
                else{SQL += result.get(Column_Text)}
                first = false
            }
        }
        SQL += " ) ORDER BY " + DBdefine.Column().COLUMN_NAME_VALUE
        var cv:DBdefine.ColumnValue
        let statement = db.run(SQL)
        for row in statement{
            cv  = DBdefine.ColumnValue()
            cv.Text = row[0] as String!
            cv.Value = row[1] as Int!
            cv.Visible = row[3] as Bool!
            cnArray.append(cv)
        }
        return cnArray
    }
    public func setColumnValues(inout cvArray:Array<DBdefine.ColumnValue>, selColumn:String){
        setColumnValues(&cvArray,selColumn: selColumn, showState: false)
        setColumnValues(&cvArray, selColumn: selColumn, showState: true)
    }
    private func setColumnValues(inout cvArray:Array<DBdefine.ColumnValue>, selColumn:String, showState:Bool){
        let cursor = Column_table.select(distinct: Column_Type).filter(Column_Name == selColumn)
        let columnIsValue:Bool = (cursor.first?.get(Column_Type) == "INTEGER")
        var strParam:String = ""
        for cv in cvArray {
            if(cv.Text == ""){continue}
            if(cv.Visible == showState){
                if(strParam != ""){strParam += " OR "}
                if(columnIsValue){ strParam += DBdefine.Column().COLUMN_NAME_VALUE + " = " + String(cv.Value)
                }else{strParam += DBdefine.Column().COLUMN_NAME_TEXT + " = " + cv.Text }
            }
        }
        if(strParam != ""){
            let ParamExp = Expression<Bool?>(strParam)
            let column = Column_table.filter(Column_Name == selColumn && ParamExp)
            column.update(Column_Visible <- showState)?
            var value:Int
            if(showState == false){ value = 0 }else{ value = 1 }
            //let SQL = "UPDATE " + DBdefine.Column().TABLE_NAME + " SET `" + DBdefine.Column().COLUMN_NAME_SHOW + "` = `" + value +"` WHERE " + strParam
            //db.run(SQL)
        }
    }
    
    func getColumnFilters(inout filterList:Array<DBdefine.ColumnFilter>){
        let query = Column_table.select(distinct: Column_Name,Column_Visible).order(Column_ID)
        var columnFilter:DBdefine.ColumnFilter
        var lastFilter = DBdefine.ColumnFilter()
        var iclf:Int = 0
        for row in query{
            columnFilter = DBdefine.ColumnFilter()
            columnFilter.Column = row.get(Column_Name)
            columnFilter.Visible = row.get(Column_Visible)
            if(columnFilter.Column == lastFilter.Column){
                if(lastFilter.Visible == true){ filterList[iclf-1] = columnFilter }
                continue
            }
            filterList.append(columnFilter)
            lastFilter.Column = columnFilter.Column
            lastFilter.Visible = columnFilter.Visible
        }
    }
    
    func clearColumnFilters(theColumn:String){
        if(Column_table.select(Column_Name == theColumn).update(Column_Visible <- true))>0{
            println(" clear succeed")
        }
    }
    
    func updateColumnVisibility(let hvList:Array<DBdefine.HeaderItem>){
        //change all columns to be visible
        Header_table.update(Header_Visible <- true)?
        
        var whereStr:String = ""
        for hItem in hvList{
            if(!hItem.Visible){
                if(whereStr != ""){whereStr += " OR "}
                whereStr += DBdefine.Header().COLUMN_NAME_NAME + " = " + hItem.Name
            }
        }
        if(whereStr != ""){
            let SQL = "UPDATE " + DBdefine.Header().TABLE_NAME+" SET `" + DBdefine.Header().COLUMN_NAME_SHOW + "` = `0` WHERE " + whereStr
            db.run(SQL)
        }
    }
}