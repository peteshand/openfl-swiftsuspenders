/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.reflection;

import avmplus.DescribeTypeJSON;
import org.swiftsuspenders.utils.CallProxy;

import org.swiftsuspenders.errors.InjectorError;
import org.swiftsuspenders.typedescriptions.ConstructorInjectionPoint;
import org.swiftsuspenders.typedescriptions.MethodInjectionPoint;
import org.swiftsuspenders.typedescriptions.NoParamsConstructorInjectionPoint;
import org.swiftsuspenders.typedescriptions.PostConstructInjectionPoint;
import org.swiftsuspenders.typedescriptions.PreDestroyInjectionPoint;
import org.swiftsuspenders.typedescriptions.PropertyInjectionPoint;
import org.swiftsuspenders.typedescriptions.TypeDescription;

class DescribeTypeJSONReflector extends ReflectorBase implements Reflector
{
	//----------------------       Private / Protected Properties       ----------------------//
	private var _descriptor:DescribeTypeJSON = new DescribeTypeJSON();

	//----------------------               Public Methods               ----------------------//
	public function typeImplements(type:Class<Dynamic>, superType:Class<Dynamic>):Bool
	{
		if (type == superType)
		{
			return true;
		}
		var superClassName:String = CallProxy.replaceClassName(superType);

		var traits:Dynamic = _descriptor.getInstanceDescription(type).traits;
		return (cast (traits.bases, Array<Dynamic>)).indexOf(superClassName) > -1
				|| (cast (traits.interfaces, Array<Dynamic>)).indexOf(superClassName) > -1;
	}

	public function describeInjections(type:Class<Dynamic>):TypeDescription
	{
		var rawDescription:Dynamic = _descriptor.getInstanceDescription(type);
		var traits:Dynamic = rawDescription.traits;
		var typeName:String = rawDescription.name;
		var description:TypeDescription = new TypeDescription(false);
		addCtorInjectionPoint(description, traits, typeName);
		addFieldInjectionPoints(description, traits.variables);
		addFieldInjectionPoints(description, traits.accessors);
		addMethodInjectionPoints(description, traits.methods, typeName);
		addPostConstructMethodPoints(description, traits.variables, typeName);
		addPostConstructMethodPoints(description, traits.accessors, typeName);
		addPostConstructMethodPoints(description, traits.methods, typeName);
		addPreDestroyMethodPoints(description, traits.methods, typeName);
		return description;
	}

	//----------------------         Private / Protected Methods        ----------------------//
	private function addCtorInjectionPoint(description:TypeDescription, traits:Dynamic, typeName:String):Void
	{
		var parameters:Array<Dynamic> = traits.constructor;
		if (parameters == null)
		{
			description.ctor =  traits.bases.length > 0
				? new NoParamsConstructorInjectionPoint()
				: null;
			return;
		}
		var injectParameters:Map<Dynamic,Dynamic> = extractTagParameters('Inject', traits.metadata);
		
		//var parameterNames:Array<Dynamic> = (injectParameters && injectParameters.name || '').split(',');
		// CHECK
		var parameterNames:Array<Dynamic> = [""];
		if (injectParameters != injectParameters && CallProxy.hasField(injectParameters, "name")) {
			parameterNames = Reflect.getProperty(injectParameters, "name").split(',');
		}
		
		var requiredParameters:Int = gatherMethodParameters(parameters, parameterNames, typeName);
		
		description.ctor = new ConstructorInjectionPoint(parameters, requiredParameters, injectParameters);
	}

	private function addMethodInjectionPoints(description:TypeDescription, methods:Array<Dynamic>, typeName:String):Void
	{
		if (methods == null)
		{
			return;
		}
		var length:UInt = methods.length;
		for (i in 0...length)
		{
			var method:Dynamic = methods[i];
			var injectParameters:Map<Dynamic,Dynamic> = extractTagParameters('Inject', method.metadata);
			if (injectParameters == null)
			{
				continue;
			}
			
			var optional:Bool = false;
			if (CallProxy.hasField(injectParameters, "optional")) {
				if (Reflect.getProperty(injectParameters, "optional") == 'true') optional = true;
			}
			
			var mappingName = '';
			if (CallProxy.hasField(injectParameters, 'name')) mappingName = Reflect.getProperty(injectParameters, "name");
			
			var parameterNames:Array<Dynamic> = mappingName.split(',');
			var parameters:Array<Dynamic> = method.parameters;
			var requiredParameters:UInt = gatherMethodParameters(parameters, parameterNames, typeName);
			var injectionPoint:MethodInjectionPoint = new MethodInjectionPoint(method.name, parameters, requiredParameters, optional, injectParameters);
			description.addInjectionPoint(injectionPoint);
		}
	}

	private function addPostConstructMethodPoints(description:TypeDescription, methods:Array<Dynamic>, typeName:String):Void
	{
		var injectionPoints:Array<Dynamic> = gatherOrderedInjectionPointsForTag(PostConstructInjectionPoint, 'PostConstruct', methods, typeName);
		
		var length = injectionPoints.length;
		//for (var i : int = 0, length : int = injectionPoints.length; i < length; i++)
		
		for (i in 0...length)
		{
			length = injectionPoints.length;
			description.addInjectionPoint(injectionPoints[i]);
		}
	}

	private function addPreDestroyMethodPoints(description:TypeDescription, methods:Array<Dynamic>, typeName:String):Void
	{
		var injectionPoints:Array<Dynamic> = gatherOrderedInjectionPointsForTag(PreDestroyInjectionPoint, 'PreDestroy', methods, typeName);
		if (injectionPoints.length == 0)
		{
			return;
		}
		description.preDestroyMethods = injectionPoints[0];
		description.preDestroyMethods.last = injectionPoints[0];
		var length = injectionPoints.length;
		for (i in 1...length)
		{
			description.preDestroyMethods.last.next = injectionPoints[i];
			description.preDestroyMethods.last = injectionPoints[i];
		}
	}

	private function addFieldInjectionPoints(description:TypeDescription, fields:Array<Dynamic>):Void
	{
		if (fields == null)
		{
			return;
		}
		var length:UInt = fields.length;
		for (i in 0...length)
		{
			var field:Dynamic = fields[i];
			var injectParameters:Map<Dynamic,Dynamic> = extractTagParameters('Inject', field.metadata);
			if (injectParameters == null)
			{
				continue;
			}
			var mappingName = '';
			
			if (CallProxy.hasField(injectParameters, 'name')) mappingName = Reflect.getProperty(injectParameters, "name");
			//var mappingName:String = injectParameters.name || '';
			
			var optional:Bool = false;
			if (CallProxy.hasField(injectParameters, "optional")) {
				if (Reflect.getProperty(injectParameters, "optional") == 'true') optional = true;
			}
			
			var injectionPoint:PropertyInjectionPoint = new PropertyInjectionPoint(
					field.type + '|' + mappingName, field.name, optional, injectParameters);
			description.addInjectionPoint(injectionPoint);
		}
	}

	private function gatherMethodParameters(parameters:Array<Dynamic>, parameterNames:Array<Dynamic>, typeName:String):UInt
	{
		var requiredLength:UInt = 0;
		var length:UInt = parameters.length;
		for (i in 0...length)
		{
			var parameter:Dynamic = parameters[i];
			var injectionName:String = '';
			if (parameterNames[i] != null) injectionName = parameterNames[i];
			//var injectionName:String = parameterNames[i] || '';
			
			var parameterTypeName:String = parameter.type;
			if (parameterTypeName == '*')
			{
				if (!parameter.optional)
				{
					throw new InjectorError('Error in method definition of injectee "' +
							typeName + '. Required parameters can\'t have type "*".');
				}
				else
				{
					parameterTypeName = null;
				}
			}
			if (!parameter.optional)
			{
				requiredLength++;
			}
			parameters[i] = parameterTypeName + '|' + injectionName;
		}
		return requiredLength;
	}

	private function gatherOrderedInjectionPointsForTag(injectionPointClass:Class<Dynamic>, tag:String, methods:Array<Dynamic>, typeName:String):Array<Dynamic>
	{
		var injectionPoints:Array<Dynamic> = [];
		if (methods == null)
		{
			return injectionPoints;
		}
		var length:UInt = methods.length;
		for (i in 0...length)
		{
			var method:Dynamic = methods[i];
			var injectParameters:Dynamic = extractTagParameters(tag, method.metadata);
			if (!injectParameters)
			{
				continue;
			}
			
			var mappingName = '';
			if (CallProxy.hasField(injectParameters, 'name')) mappingName = Reflect.getProperty(injectParameters, "name");
			
			var parameterNames:Array<Dynamic> = mappingName.split(',');
			var parameters:Array<Dynamic> = method.parameters;
			var requiredParameters:UInt;
			if (parameters != null)
			{
				requiredParameters = gatherMethodParameters(parameters, parameterNames, typeName);
			}
			else
			{
				parameters = [];
				requiredParameters = 0;
			}
			var order:Int = Std.parseInt(injectParameters.order);
			
			//Int can't be NaN, so we have to verify that parsing succeeded by comparison
			// CHECK
			//if (order.toString(10) != injectParameters.order)
			if (Std.string(order) != injectParameters.order)
			{
				order = 0x3FFFFFFF;
			}
			//var injectionPoint = Type.createInstance( injectionPointClass, [method.name, parameters, requiredParameters, order] );
			var injectionPoint = CallProxy.createInstance( injectionPointClass, [method.name, parameters, requiredParameters, order] );
			injectionPoints.push(injectionPoint);
		}
		//FIX
		/*if (injectionPoints.length > 0)
		{
			injectionPoints.sortOn('order', Array.NUMERIC);
		}*/
		return injectionPoints;
	}
	private function extractTagParameters(tag:String, metadata:Array<Dynamic>):Map<Dynamic,Dynamic>
	{
		var length:UInt = 0;
		if (metadata != null) length = metadata.length;
		//var length:UInt = metadata ? metadata.length:0;
		
		for (i in 0...length)
		{
			var entry:Dynamic = metadata[i];
			if (entry.name == tag)
			{
				var parametersList:Array<Dynamic> = entry.value;
				var parametersMap = new Map<String,Dynamic>();
				var parametersCount:Int = parametersList.length;
				for (j in 0...parametersCount)
				{
					var parameter:Dynamic = parametersList[j];
					parametersMap[parameter.key] = parametersMap[parameter.key]
						? parametersMap[parameter.key] + ',' + parameter.value
						: parameter.value;
				}
				return parametersMap;
			}
		}
		return null;
	}
}