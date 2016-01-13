//
//  FGR_NSObjectExtension.swift
//  SwiftReflect
//
//  Created by fenggeren on 15/12/18.
//  Copyright © 2015年 fenggeren. All rights reserved.
//

import Foundation

/// 属性类型  在swift的原生类不支持kvc，所以。。。。
/// 模型属性 只能是String Array 和NSObject的子类。
private enum PropertyType {
    
    case Normal(String)
    
    case Array(String)
}

/// 获取 属性的类型。
private func propertyType(property: Any) -> PropertyType {
    
    let full = "\(property.dynamicType)"
    let name = full.realType
    
    if full.containsString("Array") {
        return .Array(name)
    } else {
        return .Normal(name)
    }
    
}

private extension String {
    func removeStrings(array: [String]) -> String {
        var result = self
        for str in array {
            result = result.stringByReplacingOccurrencesOfString(str, withString: "")
        }
        return result
    }
    
    var realType: String {
        return self.removeStrings(["Array", "ImplicitlyUnwrappedOptional", "<", ">", "Optional"])
    }
}


extension NSObject {
    /// 这里参数 特殊化， 一位 有些类的初始化是  init(data: xxx)
    convenience init(adata: AnyObject) {
        self.init()
        self.modelWith(adata)
    }
    
    
    class func modelWith(adata: AnyObject) -> Self {
        let model = self.init()
        model.modelWith(adata)
        return model
    }
    
    private func modelWith(adata: AnyObject) {
      
        enumerateChild { child in
            if let key =  child.label {
                // 字典对应 键有值 且 不为 NSNull
                if let value = self.valueForKey(key, data: adata) where (value is NSNull) == false {
                    // 模型 对应 属性的 类型 字符串
                    switch propertyType(child.value) {
                    case .Normal(let typeName):
                        if typeName == "String" {
                            self.setValue(self.objectToString(value), forKey: key)
                        } else if let subModelClass = classWith(typeName) ,
                            let subDict =  value as? [String : AnyObject]{
                                let subModel = subModelClass.modelWith(subDict)
                                self.setValue(subModel, forKey: key)
                        }

                    case .Array(let eleTypeName):
                        if let arrayData = value as? [AnyObject] {
                            if eleTypeName == "String" {
                                self.setValue(self.objectArrayToStrintArray(arrayData), forKey: key)
                            } else if let subModelClass = classWith(eleTypeName) ,
                                let subDict =  value as? [[String : AnyObject]]{
                                    var arraySubModels: [AnyObject] = []
                                    for v in subDict {
                                        arraySubModels.append(subModelClass.modelWith(v))
                                    }
                                    self.setValue(arraySubModels, forKey: key)
                            }
                        }
                    }
                }
            }

        }
    }
    
    private func objectArrayToStrintArray(arr: [AnyObject]) -> [String] {
        var result: [String] = []
        for obj in arr {
            result.append(objectToString(obj))
        }
        return result
    }
    
    /// 所有的基础属性都是 String类型-
    private func objectToString(obj: AnyObject) -> String {
        if obj is NSNull {
            return "0"
        } else if obj is String {
            return obj as! String
        } else {
            return "\(obj)"
        }
    }
    
    /// 遍历一个类的所有属性-
    /// 包括继承自其父类(非NSObject)的属性
    func enumerateChild(result: (Mirror.Child) -> Void) {
        let mirror = Mirror(reflecting: self)
        
        var mirrors: [Mirror] = [mirror]
        
        var tempMirror = mirror.superclassMirror()
        
        /// 获取 self的所有的 超类-- (父类、父类的父类----) 
        /// 必须是 非NSObject的模型类
        while tempMirror != nil &&
            tempMirror!.subjectType != NSObject.self {
            mirrors.append(tempMirror!)
            tempMirror = tempMirror?.superclassMirror()
        }
        
        for mr in mirrors {
            for child in mr.children {
                result(child)
            }
        }
    }
    
    
    private func valueInDict(dict: AnyObject?, key: String) -> AnyObject? {
        if let dict = dict as? [String: AnyObject] {
            return dict[key]
        }
        return nil
    }
    
    /// 数据字典中 获取 key对应的值，
    /// key可能是a_b_c形式 代表字典的2层嵌套关系。["a":["b":["c": "value"]]]
    /// 获取 值value--
    private func valueForKey(key: String, data: AnyObject) -> AnyObject? {
        let keys = dataKeyFrom(key).componentsSeparatedByString("_")
       
        var value: AnyObject? = data
        
        if keys.count == 1 {
            value = valueInDict(value, key: key)
        } else {
            for key in keys {
                value = valueInDict(value, key: key)
            }
        }
        return value
    }
    
    /// 由 属性名 获取  字典数据中的真正关键字 ->  用于获取 数据
    /// 属性名 不一定要和 数据字典的 关键字相匹配 只需重载replacedKeys即可
    private func dataKeyFrom(ivarName: String) -> String {
        if let key = replacedKeys[ivarName] {
            return key
        }
        return ivarName
    }
    
    /// 用于子类重载。   替换属性名->  从字典中获取数据
    var replacedKeys: [String: String] {
        return [: ]
    }
    
 }

extension Array where Element: NSObject {
    
    init(adata: AnyObject) {
        self.init()
    
        let eleType = "\(self.dynamicType)".realType
        
        var result: [NSObject] = []
      
        if let eleClass = classWith(eleType),
            let dictArray = adata as? [[String: AnyObject]]{
                
            for dict in dictArray {
                result.append(eleClass.modelWith(dict))
            }
        }
        
        self = result as! Array<Element>
    }
    
    var toString: [AnyObject] {

        var result: [AnyObject] = []
        
        for ele in self {
            if ele is String {
                result.append(ele)
            } else {
                result.append(ele.toString)
            }
        }
        
        return result
    }
}


private func enumerateChild(obj: AnyObject, result: (Mirror.Child) -> Void) {
    let mirror = Mirror(reflecting: obj)
    
    var mirrors: [Mirror] = [mirror]
    
    var tempMirror = mirror.superclassMirror()
    
    /// 获取 self的所有的 超类-- (父类、父类的父类----)
    /// 必须是 非NSObject的模型类
    while tempMirror != nil{
        mirrors.append(tempMirror!)
        tempMirror = tempMirror?.superclassMirror()
    }
    
    for mr in mirrors {
        for child in mr.children {
            result(child)
        }
    }
}


private func classWith(className: String) -> NSObject.Type? {
    // 是UIKit/Foundation框架中的类
    if let cls = NSClassFromString(className) as? NSObject.Type {
        return cls
    }
    
    // 自己创建的类
    var bundleName = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName")!.description
    bundleName = bundleName.stringByReplacingOccurrencesOfString(".", withString: "_")
    
    let clsName = bundleName + "." + className
    if let cls = NSClassFromString(clsName) as? NSObject.Type {
        return cls
    }
    return nil
}



extension NSObject {
    
    // MARK: - 打印 对象- 简单的处理
    /// 模型转字典
    var toString: [String: AnyObject] {
        
        var param: [String: AnyObject] = [:]
        
        var ivarCount: UInt32 = 0
        let ivarList = class_copyIvarList(self.classForCoder, &ivarCount)
        
        for var i = 0; i < Int(ivarCount); ++i {
            let ivar = ivarList[i]
            let ivarName = String.fromCString(ivar_getName(ivar))!
            
            if let value = valueForKey(ivarName) {
                if let value = value as? String {
                    param[ivarName] = value
                } else if let value = value as? [String] {
                    param[ivarName] = value
                } else if let value = value as? [NSObject] {
                    param[ivarName] = value.toString
                } else {
                    let value = value.toString
                    param[ivarName] = value
                }
            }
        }
        free(ivarList)
        return param
    }
    
}

private extension NSObject {
    
    func valueForChild(child: Mirror.Child) -> (String, String) {
        var key = child.label!
        
        key = key.stringByReplacingOccurrencesOfString("_", withString: ".")
        let value = valueForKey(key)
        
        if let value = value as? String {
            return (key, value)
        } else if let value = value as? [String] {
            return (key, paramStringFromStringArray(key, array: value))
        } else if let value = value as? [NSObject] {
            return (key, paramStringFromModels(key, models: value))
        }
        
        return (key, "")
    }
    
    var params: [String: AnyObject] {
        var param:[String : AnyObject] = [: ]
        
        enumerateChild { child in
            let vfc = self.valueForChild(child)
            param[vfc.0] = vfc.1
        }
        
        return param
    }

    
    private func paramStringFromStringArray(key: String, array: [String]) -> String {
        var result: [String] = []
        for v in array {
            result.append(String(format: "%@=%@", argument: key, v))
        }
        return result.joinWithSeparator("&")
    }
    
    private func paramStringFromModels(key: String, models: [NSObject]) -> String {
        var dict: [String: AnyObject] = [: ]
        
        for (index, obj) in models.enumerate() {
            let params = obj.params
            for pp in params {
                let key = String(format: "%@[%ld].%@", argument: key, index, pp.0)
                dict[key] = pp.1
            }
        }
        
        var result: [String] = []
        for pp in dict {
            result.append(String(format: "%@=%@", argument: pp.0, pp.1))
        }
        
        return result.joinWithSeparator("&")
    }
}



// MARK: -  转换 JSON字符串
extension NSObject {
    
    func JSONString() -> String {
        var result =  dict2JSONString(toString)
        result = result.stringByReplacingOccurrencesOfString(",]", withString: "]")
        result = result.stringByReplacingOccurrencesOfString(",}", withString: "}")
        let nsResult = result as NSString
        return nsResult.substringToIndex(nsResult.length - 1)
    }
    
    func dict2JSONString(dict: [String: AnyObject]) -> String {
        var result = "{"
        for dd in dict {
            if let value = dd.1 as? String {
                result += String(format: "\"%@\" : \"%@\",", dd.0, value)
            } else if let value = dd.1 as? [[String: AnyObject]] {
                var subResult = "["
                for subv in value {
                    subResult += dict2JSONString(subv)
                }
                subResult += "],"
                result += String(format: "\"%@\" : %@", dd.0, subResult)
            }
        }
        result += "},"
        return result
    }
}


















