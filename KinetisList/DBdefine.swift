//
//  DBdefine.swift
//  KinetisList
//
//  Created by MAD-Test on 15-1-22.
//  Copyright (c) 2015年 FSL. All rights reserved.
//

import Foundation
public final class DBdefine{


    public struct HeaderItem {
        var Name: String = ""
        var Title: String = ""
        var Type: String = "String"
        var width:Int = 300
        var Visible:Bool = true
    }

    public struct DeviceRow{
        static var Param: [String] = []
        static var Visible:Bool? = true
    }

    public struct ColumnValue{
        static var Text:String? = ""
        static var Value:Int? = 0
        static var Visible:Bool? = true
    }

    public struct ColumnFilter{
        static var Column:String?
        static var Visible:Bool?
    }
    public class BaseColumns{
        let _ID:String = "_id"
        let _COUNT:String = "_count"
    }
    
    public final class Header:BaseColumns{
        let TABLE_NAME:String = "Header"
        let DEFAULT_SORT_ORDER:String = "_id ASC"
        let COLUMN_NAME_NAME:String = "Name"
        let COLUMN_NAME_TITLE:String = "Title"
        let COLUMN_NAME_TYPE:String = "Tpe"
        let COLUMN_NAME_WIDTH:String = "Width"
        let COLUMN_NAME_SHOW:String = "Show"
    }
    
    public final class Column:BaseColumns{
        let TABLE_NAME:String = "Column"
        let COLUMN_NAME_NAME:String = "Name"
        let COLUMN_NAME_TYPE:String = "Type"
        let COLUMN_NAME_TEXT:String = "Text"
        let COLUMN_NAME_VALUE:String = "Value"
        let COLUMN_NAME_SHOW:String = "Show"

    }
    
    public final class Devices:BaseColumns{
        let TABLE_NAME:String = "Devices"
        let DEFAULT_SORT_ORDER = "`MK Part Number` ASC"
    }
    
}