//
//  UIKitStructAssistant.swift
//  MotionMachine
//
//  Created by Brett Walker on 5/30/16.
//  Copyright © 2016 Poet & Mountain, LLC. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import UIKit

/// UIKitStructAssistant provides support for the UIKit structs `UIEdgeInsets` and `UIOffset`.
public class UIKitStructAssistant : ValueAssistant {
    
    public var additive: Bool = false
    public var additiveWeighting: Double = 1.0 {
        didSet {
            // constrain weighting to range of 0.0 - 1.0
            additiveWeighting = max(min(additiveWeighting, 1.0), 0.0)
        }
    }
    
    /**
     *  Initializer.
     *
     */
    public init() {
        // provide support for UIKit structs
        // doesn't seem like there's a better way to extend the enum array from multiple assistants than this?
        ValueStructTypes.valueTypes[.UIEdgeInsets] = NSValue(UIEdgeInsets: UIEdgeInsetsZero).objCType
        ValueStructTypes.valueTypes[.UIOffset] = NSValue(UIOffset: UIOffsetZero).objCType
    }
    
    
    // MARK: ValueAssistant methods
    
    public func generateProperties(fromObject object: AnyObject, keyPath path: String, targetObject target: AnyObject) throws -> [PropertyData] {
        var properties: [PropertyData] = []
        
        guard let value = object as? NSValue else { throw ValueAssistantError.TypeRequirement("NSValue") }

        let value_type = UIKitStructAssistant.determineType(forValue: value)
        
        switch value_type {
        case .UIEdgeInsets:
            let base_path: String = path + "."

            var org_top: Double?
            var org_left: Double?
            var org_bottom: Double?
            var org_right: Double?
            
            if let unwrapped_nsvalue = target as? NSValue {
                let type = UIKitStructAssistant.determineType(forValue: unwrapped_nsvalue)
                if (type == .UIEdgeInsets) {
                    let org_insets = unwrapped_nsvalue.UIEdgeInsetsValue()
                    org_top = Double(org_insets.top)
                    org_left = Double(org_insets.left)
                    org_bottom = Double(org_insets.bottom)
                    org_right = Double(org_insets.right)
                }
            }
            
            let insets = value.UIEdgeInsetsValue()
            
            if let unwrapped_top = org_top {
                if (Double(insets.top) !≈ unwrapped_top) {
                    var prop = PropertyData("top", Double(insets.top))
                    prop.path = base_path + prop.path
                    properties.append(prop)
                }
            }
            if let unwrapped_left = org_left {
                if (Double(insets.left) !≈ unwrapped_left) {
                    var prop = PropertyData("left", Double(insets.left))
                    prop.path = base_path + prop.path
                    properties.append(prop)
                }
            }
            if let unwrapped_bottom = org_bottom {
                if (Double(insets.bottom) !≈ unwrapped_bottom) {
                    var prop = PropertyData("bottom", Double(insets.bottom))
                    prop.path = base_path + prop.path
                    properties.append(prop)
                }
            }
            if let unwrapped_right = org_right {
                if (Double(insets.right) !≈ unwrapped_right) {
                    var prop = PropertyData("right", Double(insets.right))
                    prop.path = base_path + prop.path
                    properties.append(prop)
                }
            }
            
        case .UIOffset:
            let base_path: String = path + "."
            
            var org_h: Double?
            var org_v: Double?
            
            if let unwrapped_nsvalue = target as? NSValue {
                let type = UIKitStructAssistant.determineType(forValue: unwrapped_nsvalue)
                if (type == .UIOffset) {
                    let org_offset = unwrapped_nsvalue.UIOffsetValue()
                    org_h = Double(org_offset.horizontal)
                    org_v = Double(org_offset.vertical)
                }
            }
            
            let offset = value.UIOffsetValue()
            
            if let unwrapped_h = org_h {
                if (Double(offset.horizontal) !≈ unwrapped_h) {
                    var prop = PropertyData("horizontal", Double(offset.horizontal))
                    prop.path = base_path + prop.path
                    properties.append(prop)
                }
            }
            if let unwrapped_v = org_v {
                if (Double(offset.vertical) !≈ unwrapped_v) {
                    var prop = PropertyData("vertical", Double(offset.vertical))
                    prop.path = base_path + prop.path
                    properties.append(prop)
                }
            }
        
        case .Unsupported: break

        default:
            break
        }
        
        return properties
    }
    
    
    
    public func retrieveValue(inObject object: AnyObject, keyPath path: String) throws -> Double? {
        var retrieved_value: Double?
        
        guard let value = object as? NSValue else { throw ValueAssistantError.TypeRequirement("NSValue") }

        if (MotionSupport.matchesObjCType(forValue: value, typeToMatch: ValueStructTypes.UIEdgeInsets.toObjCType())) {
            
            retrieved_value = retrieveStructValue(value, type: .UIEdgeInsets, path: path)
        
        } else if (MotionSupport.matchesObjCType(forValue: value, typeToMatch: ValueStructTypes.UIOffset.toObjCType())) {
            
            retrieved_value = retrieveStructValue(value, type: .UIOffset, path: path)
        }
        
        return retrieved_value
    }
    
    
    public func calculateValue(forProperty property: PropertyData, newValue: Double) -> NSObject? {
        
        guard let unwrapped_target = property.target else { return nil }
        
        var new_prop: NSObject? = NSNumber.init(double: property.current)
        
        // this code path will execute if the object passed in was an NSValue
        // as such we must replace the value object directly
        if ((property.targetObject == nil || property.targetObject === unwrapped_target) && unwrapped_target is NSValue) {
            var new_property_value = property.current
            if (additive) {
                new_property_value = newValue
            }
            
            new_prop = updateValue(inObject: unwrapped_target, newValues: [property.path : new_property_value])
            
            return new_prop
        }
        
        
        if let unwrapped_object = property.targetObject {
            // we have a normal object whose property is being changed
            if (unwrapped_target is Double) {
                if let base_prop = unwrapped_object.valueForKeyPath(property.path) {
                    var new_property_value = property.current
                    if (additive) {
                        new_property_value = newValue
                    }
                    new_prop = updateValue(inObject: base_prop, newValues: [property.path : new_property_value])
                }
                
            } else if (unwrapped_target is NSValue) {
                if (!property.replaceParentProperty) {
                    if let base_prop = unwrapped_object.valueForKeyPath(property.path) {
                        
                        if (base_prop is NSObject) {
                            var new_property_value = property.current
                            if (additive) {
                                new_property_value = newValue
                            }
                            
                            new_prop = updateValue(inObject: base_prop, newValues: [property.path : new_property_value])
                            
                        }
                        
                    }
                } else {
                    // replace the top-level struct of the property we're trying to alter
                    // e.g.: key path is "frame.origin.x", so we replace "frame" because that's the closest KVC-compliant prop
                    if let base_prop = unwrapped_object.valueForKeyPath(property.parentKeyPath) {
                        var new_property_value = property.current
                        if (additive) {
                            new_property_value = newValue
                        }
                        
                        new_prop = updateValue(inObject: base_prop, newValues: [property.path : new_property_value])
                        
                    }
                    
                }
                
            }
            
            return new_prop
        }
        
        return new_prop
    }
    
    
    public func updateValue(inObject object: AnyObject, newValues: Dictionary<String, Double>) -> NSObject? {
        guard newValues.count > 0 else { return nil }
        
        var new_parent_value:NSObject?
        
        if let unwrapped_value = object as? NSValue {
            var value = unwrapped_value
            
            if (MotionSupport.matchesObjCType(forValue: value, typeToMatch: ValueStructTypes.UIEdgeInsets.toObjCType())) {
                
                updateStruct(&value, type: .UIEdgeInsets, newValues: newValues)
            
            } else if (MotionSupport.matchesObjCType(forValue: value, typeToMatch: ValueStructTypes.UIOffset.toObjCType())) {
                
                updateStruct(&value, type: .UIOffset, newValues: newValues)
            }
            
            new_parent_value = value
        }
        
        return new_parent_value
    }
    
    
    
    public func supports(object: AnyObject) -> Bool {
        var is_supported: Bool = false
        
        if let unwrapped_value = object as? NSValue {
            if (MotionSupport.matchesObjCType(forValue: unwrapped_value, typeToMatch: ValueStructTypes.UIEdgeInsets.toObjCType())
                || MotionSupport.matchesObjCType(forValue: unwrapped_value, typeToMatch: ValueStructTypes.UIOffset.toObjCType())
                ) {
                
                is_supported = true
            }
        }
        return is_supported
    }
    
    public func acceptsKeypath(object: AnyObject) -> Bool {
        var accepts = false
        
        if (object is UIEdgeInsets || object is UIOffset) {
            accepts = true
        }
        
        return accepts
    }
    
    
    // MARK: Static methods
    
    /// Determines the type of struct represented by a NSValue object.
    public static func determineType(forValue value: NSValue) -> ValueStructTypes {
        let type: ValueStructTypes
        
        if MotionSupport.matchesObjCType(forValue: value, typeToMatch: ValueStructTypes.UIEdgeInsets.toObjCType()) {
            type = ValueStructTypes.UIEdgeInsets
        } else if MotionSupport.matchesObjCType(forValue: value, typeToMatch: ValueStructTypes.UIOffset.toObjCType()) {
            type = ValueStructTypes.UIOffset
        } else {
            type = ValueStructTypes.Unsupported
        }
        
        
        return type
    }
    
    
    static func valueForStruct(cfStruct: Any) -> NSValue? {
        var value: NSValue?
        
        let insets = UIEdgeInsetsZero
        let offset = UIOffsetZero
        
        if (MotionSupport.matchesType(forValue: cfStruct, typeToMatch: insets.dynamicType)) {
            value = NSValue.init(UIEdgeInsets: (cfStruct as! UIEdgeInsets))
            
        } else if (MotionSupport.matchesType(forValue: cfStruct, typeToMatch: offset.dynamicType)) {
            value = NSValue.init(UIOffset: (cfStruct as! UIOffset))
        }
        
        return value
    }
    
    
    // MARK: Private methods

    func updateStruct(inout structValue: NSValue, type: ValueStructTypes, newValues: Dictionary<String, Double>) {
        
        guard newValues.count > 0 else { return }
        
        switch type {
        case .UIEdgeInsets:
            var insets = structValue.UIEdgeInsetsValue()
            
            for (prop, newValue) in newValues {
                let last_component = lastComponent(forPath: prop)
                
                if (last_component == "top") {
                    applyTo(value: &insets.top, newValue: CGFloat(newValue))
                    
                } else if (last_component == "left") {
                    applyTo(value: &insets.left, newValue: CGFloat(newValue))
                    
                } else if (last_component == "bottom") {
                    applyTo(value: &insets.bottom, newValue: CGFloat(newValue))

                } else if (last_component == "right") {
                    applyTo(value: &insets.right, newValue: CGFloat(newValue))
                }
            }
            
            structValue = NSValue.init(UIEdgeInsets: insets)
            
        case .UIOffset:
            var offset = structValue.UIOffsetValue()
            
            for (prop, newValue) in newValues {
                let last_component = lastComponent(forPath: prop)
                
                if (last_component == "horizontal") {
                    applyTo(value: &offset.horizontal, newValue: CGFloat(newValue))
                    
                } else if (last_component == "vertical") {
                    applyTo(value: &offset.vertical, newValue: CGFloat(newValue))
                }
            }
            
            structValue = NSValue.init(UIOffset: offset)
            
        case .Unsupported: break
            
        default: break
        }
        
    }
    
    
    func retrieveStructValue(structValue: NSValue, type: ValueStructTypes, path: String) -> Double? {
        
        var retrieved_value: Double?
        
        switch type {
        case .UIEdgeInsets:
            let insets = structValue.UIEdgeInsetsValue()
            
            let last_component = lastComponent(forPath: path)
            
            if (last_component == "top") {
                retrieved_value = Double(insets.top)
                
            } else if (last_component == "left") {
                retrieved_value = Double(insets.left)
                
            } else if (last_component == "bottom") {
                retrieved_value = Double(insets.bottom)
                
            } else if (last_component == "right") {
                retrieved_value = Double(insets.right)
            }
            
        case .UIOffset:
            let offset = structValue.UIOffsetValue()
            
            let last_component = lastComponent(forPath: path)
            
            if (last_component == "horizontal") {
                retrieved_value = Double(offset.horizontal)
                
            } else if (last_component == "vertical") {
                retrieved_value = Double(offset.vertical)
            }
            
        case .Unsupported: break
            
        default:
            break
        }
        
        
        return retrieved_value
    }
    
    


    
}

