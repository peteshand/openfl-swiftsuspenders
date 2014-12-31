/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.reflection;


//import flash.utils.describeType;
import haxe.rtti.Meta;
import haxe.xml.Fast;
import openfl.errors.Error;
import org.swiftsuspenders.utils.CallProxy;

import org.swiftsuspenders.errors.InjectorError;

import org.swiftsuspenders.typedescriptions.ConstructorInjectionPoint;
import org.swiftsuspenders.typedescriptions.MethodInjectionPoint;
import org.swiftsuspenders.typedescriptions.NoParamsConstructorInjectionPoint;
import org.swiftsuspenders.typedescriptions.PostConstructInjectionPoint;
import org.swiftsuspenders.typedescriptions.PreDestroyInjectionPoint;
import org.swiftsuspenders.typedescriptions.PropertyInjectionPoint;
import org.swiftsuspenders.typedescriptions.TypeDescription;

class DescribeTypeReflector extends ReflectorBase implements Reflector
{
	//----------------------       Private / Protected Properties       ----------------------//
	private var _currentFactoryXML:Xml;
	private var _currentFactoryXMLFast:Fast;
	var constructorElem:Fast;

	//----------------------               Public Methods               ----------------------//
	public function typeImplements(type:Class<Dynamic>, superType:Class<Dynamic>):Bool
	{
		/*if (type == superType)
		{
			return true;
		}*/
		
		//var val = cast(type, superType);
		/*if (val != null)
		{
			return true;
		}*/
		// CHECK
		/*var factoryDescription:Xml = describeType(type).factory[0];
		factoryDescription.
		return (factoryDescription.children().(
			name() == "implementsInterface" || name() == "extendsClass").(
			attribute("type") == CallProxy.getClassName(superType)).length() > 0);*/
			
		// CHECK
		//return false;
		
		return classExtendsOrImplements(type, superType);
	}
	
	/*
	Method Credits: 2012-2014 Massive Interactive
	//package minject.Reflector;
	*/
	
	public function classExtendsOrImplements(classOrClassName:Dynamic, superClass:Class<Dynamic>):Bool
	{
		var actualClass:Class<Dynamic> = null;
		
		if (Std.is(classOrClassName, Class))
		{
			actualClass = cast(classOrClassName, Class<Dynamic>);
		}
		else if (Std.is(classOrClassName, String))
		{
			try
			{
				actualClass = Type.resolveClass(cast(classOrClassName, String));
			}
			catch (e:Dynamic)
			{
				throw "The class name " + classOrClassName + " is not valid because of " + e + "\n" + e.getStackTrace();
			}
		}

		if (actualClass == null)
		{
			throw "The parameter classOrClassName must be a Class or fully qualified class name.";
		}

		var classInstance = Type.createEmptyInstance(actualClass);
		return Std.is(classInstance, superClass);
	}
	
	
	
	
	
	public function describeInjections(_type:Class<Dynamic>):TypeDescription
	{
		#if cpp
			var type:Dynamic = _type;
		#else 
			var type:Class<Dynamic> = _type;
		#end
		
		var rtti:String = untyped type.__rtti;
		if (rtti == null) {
			if (!isInterface(type)) trace("Warning: " + type + " missing @:rtti matadata");
		}
		
		if (rtti != null) {
			
			_currentFactoryXML = Xml.parse(rtti).firstElement();
			_currentFactoryXMLFast = new Fast(_currentFactoryXML);
			
			for (elem in _currentFactoryXMLFast.elements) {
				if (elem.name == 'new') constructorElem = elem;
			}
			
		}
		
		var description:TypeDescription = new TypeDescription(false);
		addCtorInjectionPoint(description, type); // TEMP
		addFieldInjectionPoints(description, type); // FIX
		addMethodInjectionPoints(description, type); // FIX
		addPostConstructMethodPoints(description, type); // FIX
		addPreDestroyMethodPoints(description, type); // FIX
		
		_currentFactoryXML = null;
		_currentFactoryXMLFast = null;
		constructorElem = null;
		
		return description;
	}
	
	function isInterface(type:Class<Dynamic>):Bool
	{
		// Hack to check if class is an interface by looking at its class name and seeing if it Starts with a (IU)ppercase
		var classPath = CallProxy.getClassName(type);
		var split = classPath.split(".");
		var className:String = split[split.length - 1];
		if (className.length <= 1) {
			return false;
		}
		else {
			var r = ~/(I)([A-Z])/;
			var f2 = className.substr(0, 2);
			if (r.match(f2)) {
				return true;
			}
			else return false;
		}
	}

	//----------------------         Private / Protected Methods        ----------------------//
	private function addCtorInjectionPoint(description:TypeDescription, type:Class<Dynamic>):Void
	{
		// TEMP (no CtorInjectionPoints will be added)
		
		if (constructorElem == null) {
			description.ctor = new NoParamsConstructorInjectionPoint();
			return;
		}
		// FIX
		/*var node:Xml = _currentFactoryXML.constructor[0];
		if (!node)
		{
			if (_currentFactoryXML.parent().@name == 'Dynamic'
					|| _currentFactoryXML.extendsClass.length() > 0)
			{
				description.ctor = new NoParamsConstructorInjectionPoint();
			}
			return;
		}
		var injectParameters:Map<Dynamic,Dynamic> = extractNodeParameters(node.parent().metadata.arg);
		var parameterNames:Array = (injectParameters.name || '').split(',');
		var parameterNodes:XMLList = node.parameter;*/
		
		
		/*
		 In many cases, the flash player doesn't give us type information for constructors until
		 the class has been instantiated at least once. Therefore, we do just that if we don't get
		 type information for at least one parameter.
		 */
		// FIX
		//if (parameterNodes.(@type == '*').length() == parameterNodes.@type.length())
		//{
		//	createDummyInstance(node, type);
		//}
		//var parameters:Array = gatherMethodParameters(parameterNodes, parameterNames);
		//var requiredParameters:UInt = parameters.required;
		//delete parameters.required;
		
		var className = Type.getClassName(type);
		
		
		// FIX add injectParameters
		var injectParameters:Map<String,Dynamic> = null;
		
		
		
		
		var parameterNames:Array<String> = constructorElem.node.f.att.a.split(":");
		//var parameterValues:Array<String> = constructorElem.node.f.att.v.split(":");
		var parameters:Array<String> = [];
		
		var constructorXml = constructorElem.x;
		for (node in constructorXml.firstElement().iterator()) 
		{
			if(node.nodeType == Xml.Element ){
				var nodeFast = new Fast(node);
				parameters.push(nodeFast.att.path + "|");
			}
		}
		
		
		
		/*var count = 0;
		for (i in constructorElem.node.f.nodes.c.iterator()) 
		{
			parameters[count] = i.att.path + "|";
			count += 2;
		}
		count = 1;
		for (i in constructorElem.node.f.nodes.x.iterator()) 
		{
			parameters[count] = i.att.path + "|";
			count += 2;
		}*/
		parameters.pop();
		/*if (parameters.length == 1) {
			if (parameters[0] == null) parameters.pop();
		}*/
		
		var requiredParameters:UInt = 0;
		for (j in 0...parameterNames.length) 
		{
			if (parameterNames[j].indexOf("?") != 0) {
				requiredParameters++;
			}
		}
		description.ctor = new ConstructorInjectionPoint(parameters, requiredParameters, injectParameters);
	}
	
	// FIX
	/*private function extractNodeParameters(args:XMLList):Map<Dynamic,Dynamic>
	{
		var parametersMap:Map<Dynamic,Dynamic> = new Map<Dynamic,Dynamic>();
		var length:UInt = args.length();
		for (i in 0...length)
		{
			var parameter:Xml = args[i];
			var key:String = parameter.@key;
			parametersMap[key] = parametersMap[key]
				? parametersMap[key] + ',' + parameter.attribute('value')
				: parameter.attribute('value');
		}
		return parametersMap;
	}*/
	
	private function addFieldInjectionPoints(description:TypeDescription, type:Class<Dynamic>):Void
	{
		// CHECK
		var metaFields = Meta.getFields(type);
		
		var fields = Reflect.fields(metaFields);
		for (propertyName in fields) {
			var optional = false;
			var injectParams:Array<String> = Reflect.getProperty(Reflect.getProperty(metaFields, propertyName), "inject");
			if (injectParams != null){
				for (i in 0...injectParams.length) 
				{
					if (injectParams[i].indexOf("optional=") != -1) {
						if (injectParams[i].split("optional=")[1].toLowerCase() == 'true') {
							optional = true;
						}
					}
				}
			}
			
			//var mappingId:String = CallProxy.getClassName(type) + '|';// + node.arg.(@key == 'name').attribute('value');
			
			var mappingId:String = "";
			for (elem in _currentFactoryXMLFast.elements) {
				if (elem.name == propertyName) {
					// FIX missing key 
					var pathFast = new Fast(elem.x.firstElement());
					mappingId = pathFast.att.path + '|';// + node.arg.(@key == 'name').attribute('value');
				}
			}
			//var optional = Reflect.getProperty(injectParams, "optional");
			
			// FIX missing injectParameters
			//var injectParameters:Map<String,Dynamic> = extractNodeParameters(node.arg);
			var injectParameters = new Map<String,Dynamic>();
			
			var injectionPoint:PropertyInjectionPoint = new PropertyInjectionPoint(mappingId, propertyName, optional, injectParameters);
			description.addInjectionPoint(injectionPoint);
			
		}
		
		// FIX
		/*for (var node:Xml in _currentFactoryXML.*.
				(name() == 'variable' || name() == 'accessor').metadata.(@name == 'Inject'))
		{
			var mappingId:String =
					node.parent().@type + '|' + node.arg.(@key == 'name').attribute('value');
			var propertyName:String = node.parent().@name;
			var injectParameters:Map<Dynamic,Dynamic> = extractNodeParameters(node.arg);
			var injectionPoint:PropertyInjectionPoint = new PropertyInjectionPoint(mappingId,
				propertyName, injectParameters.optional == 'true', injectParameters);
			description.addInjectionPoint(injectionPoint);
		}*/
	}

	private function addMethodInjectionPoints(description:TypeDescription, type:Class<Dynamic>):Void
	{
		// FIX
		/*for each (var node:Xml in _currentFactoryXML.method.metadata.(@name == 'Inject'))
		{
			var injectParameters:Map<Dynamic,Dynamic> = extractNodeParameters(node.arg);
			var parameterNames:Array = (injectParameters.name || '').split(',');
			var parameters:Array =
					gatherMethodParameters(node.parent().parameter, parameterNames);
			var requiredParameters:UInt = parameters.required;
			delete parameters.required;
			var injectionPoint:MethodInjectionPoint = new MethodInjectionPoint(
				node.parent().@name, parameters, requiredParameters,
				injectParameters.optional == 'true', injectParameters);
			description.addInjectionPoint(injectionPoint);
		}*/
	}

	private function addPostConstructMethodPoints(description:TypeDescription, type:Class<Dynamic>):Void
	{
		var injectionPoints:Array<Dynamic> = gatherOrderedInjectionPointsForTag(PostConstructInjectionPoint, 'PostConstruct');
		
		var length = injectionPoints.length;
		for (i in 0...length)
		{
			description.addInjectionPoint(injectionPoints[i]);
		}
	}

	private function addPreDestroyMethodPoints(description:TypeDescription, type:Class<Dynamic>):Void
	{
		var injectionPoints:Array<Dynamic> = gatherOrderedInjectionPointsForTag(PreDestroyInjectionPoint, 'PreDestroy');
		
		if (injectionPoints.length == 0)
		{
			return;
		}
		description.preDestroyMethods = injectionPoints[0];
		description.preDestroyMethods.last = injectionPoints[0];
		var length = injectionPoints.length;
		for (i in 0...length)
		{
			description.preDestroyMethods.last.next = injectionPoints[i];
			description.preDestroyMethods.last = injectionPoints[i];
		}
	}

	private function gatherMethodParameters(parameterNodes:Xml/*XMLList*/, parameterNames:Array<Dynamic>):Array<Dynamic>
	{
		// FIX
		/*var requiredParameters:UInt = 0;
		var length:UInt = parameterNodes.length();
		var parameters:Array = new Array(length);
		for (i in 0...length)
		{
			var parameter:Xml = parameterNodes[i];
			var injectionName:String = parameterNames[i] || '';
			var parameterTypeName:String = parameter.@type;
			var optional:Bool = parameter.@optional == 'true';
			if (parameterTypeName == '*')
			{
				if (!optional)
				{
					throw new InjectorError('Error in method definition of injectee "' +
						_currentFactoryXML.@type + 'Required parameters can\'t have type "*".');
				}
				else
				{
					parameterTypeName = null;
				}
			}
			if (!optional)
			{
				requiredParameters++;
			}
			parameters[i] = parameterTypeName + '|' + injectionName;
		}
		parameters.required = requiredParameters;
		return parameters;*/
		
		return null;
	}

	private function gatherOrderedInjectionPointsForTag(injectionPointType:Class<Dynamic>, tag:String):Array<Dynamic>
	{
		var injectionPoints:Array<Dynamic> = [];
		// FIX
		/*for (var node:Xml in _currentFactoryXML..metadata.(@name == tag))
		{
			var injectParameters:Map<Dynamic,Dynamic> = extractNodeParameters(node.arg);
			var parameterNames:Array = (injectParameters.name || '').split(',');
			var parameters:Array =
				gatherMethodParameters(node.parent().parameter, parameterNames);
			var requiredParameters:UInt = parameters.required;
			delete parameters.required;
			var order:Float = parseInt(node.arg.(@key == 'order').@value);
			injectionPoints.push(new injectionPointType(node.parent().@name,
				parameters, requiredParameters, isNaN(order) ? Limits.IntMax:order));
		}
		if (injectionPoints.length > 0)
		{
			injectionPoints.sortOn('order', Array.NUMERIC);
		}*/
		return injectionPoints;
	}

	private function createDummyInstance(constructorNode:Xml, clazz:Class<Dynamic>):Void
	{
		// FIX
		/*try
		{
			switch (constructorNode.children().length())
			{
				case 0 :(Type.createInstance(clazz, null));
				case 1 :(Type.createInstance(clazz, [null]));
				case 2 :(Type.createInstance(clazz, [null, null]));
				case 3 :(Type.createInstance(clazz, [null, null, null]));
				case 4 :(Type.createInstance(clazz, [null, null, null, null]));
				case 5 :(Type.createInstance(clazz, [null, null, null, null, null]));
				case 6 :(Type.createInstance(clazz, [null, null, null, null, null, null]));
				case 7 :(Type.createInstance(clazz, [null, null, null, null, null, null, null]));
				case 8 :(Type.createInstance(clazz, [null, null, null, null, null, null, null, null]));
				case 9 :(Type.createInstance(clazz, [null, null, null, null, null, null, null, null, null]));
				case 10 :(Type.createInstance(clazz, [null, null, null, null, null, null, null, null, null, null]));
			}
		}
		catch (error:Error)
		{
			trace('Exception caught while trying to create dummy instance for constructor ' +
					'injection. It\'s almost certainly ok to ignore this exception, but you ' +
					'might want to restructure your constructor to prevent errors from ' +
					'happening. See the Swiftsuspenders documentation for more details.\n' +
					'The caught exception was:\n' + error);
		}*/
		// FIX
		//constructorNode.setChildren(describeType(clazz).factory.constructor[0].children());
	}
}