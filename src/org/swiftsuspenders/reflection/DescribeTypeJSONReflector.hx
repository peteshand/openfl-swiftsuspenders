/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.reflection;

import avmplus.DescribeTypeJSON;

import openfl.utils.Dictionary;
import flash.utils.getQualifiedClassName;

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
	public function typeImplements(type:Class, superType:Class):Bool
	{
		if (type == superType)
		{
			return true;
		}
		var superClassName:String = getQualifiedClassName(superType);

		var traits:Dynamic = _descriptor.getInstanceDescription(type).traits;
		return (traits.bases as Array).indexOf(superClassName) > -1
				|| (traits.interfaces as Array).indexOf(superClassName) > -1;
	}

	public function describeInjections(type:Class):TypeDescription
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
	private function addCtorInjectionPoint(
		description:TypeDescription, traits:Dynamic, typeName:String):Void
	{
		var parameters:Array = traits.constructor;
		if (!parameters)
		{
			description.ctor =  traits.bases.length > 0
				? new NoParamsConstructorInjectionPoint()
				: null;
			return;
		}
		var injectParameters:Dictionary = extractTagParameters('Inject', traits.metadata);
		var parameterNames:Array =
			(injectParameters && injectParameters.name || '').split(',');
		var requiredParameters:Int =
			gatherMethodParameters(parameters, parameterNames, typeName);
		description.ctor =
			new ConstructorInjectionPoint(parameters, requiredParameters, injectParameters);
	}

	private function addMethodInjectionPoints(
		description:TypeDescription, methods:Array, typeName:String):Void
	{
		if (!methods)
		{
			return;
		}
		var length:UInt = methods.length;
		for (var i:Int = 0; i < length; i++)
		{
			var method:Dynamic = methods[i];
			var injectParameters:Dictionary = extractTagParameters('Inject', method.metadata);
			if (!injectParameters)
			{
				continue;
			}
			var optional:Bool = injectParameters.optional == 'true';
			var parameterNames:Array = (injectParameters.name || '').split(',');
			var parameters:Array = method.parameters;
			var requiredParameters:UInt =
					gatherMethodParameters(parameters, parameterNames, typeName);
			var injectionPoint:MethodInjectionPoint = new MethodInjectionPoint(method.name,
				parameters, requiredParameters, optional, injectParameters);
			description.addInjectionPoint(injectionPoint);
		}
	}

	private function addPostConstructMethodPoints(
		description:TypeDescription, methods:Array, typeName:String):Void
	{
		var injectionPoints:Array = gatherOrderedInjectionPointsForTag(
			PostConstructInjectionPoint, 'PostConstruct', methods, typeName);
		for (var i:Int = 0, length:Int = injectionPoints.length; i < length; i++)
		{
			description.addInjectionPoint(injectionPoints[i]);
		}
	}

	private function addPreDestroyMethodPoints(
		description:TypeDescription, methods:Array, typeName:String):Void
	{
		var injectionPoints:Array = gatherOrderedInjectionPointsForTag(
			PreDestroyInjectionPoint, 'PreDestroy', methods, typeName);
		if (!injectionPoints.length)
		{
			return;
		}
		description.preDestroyMethods = injectionPoints[0];
		description.preDestroyMethods.last = injectionPoints[0];
		for (var i:Int = 1, length:Int = injectionPoints.length; i < length; i++)
		{
			description.preDestroyMethods.last.next = injectionPoints[i];
			description.preDestroyMethods.last = injectionPoints[i];
		}
	}

	private function addFieldInjectionPoints(
		description:TypeDescription, fields:Array):Void
	{
		if (!fields)
		{
			return;
		}
		var length:UInt = fields.length;
		for (var i:Int = 0; i < length; i++)
		{
			var field:Dynamic = fields[i];
			var injectParameters:Dictionary = extractTagParameters('Inject', field.metadata);
			if (!injectParameters)
			{
				continue;
			}
			var mappingName:String = injectParameters.name || '';
			var optional:Bool = injectParameters.optional == 'true';
			var injectionPoint:PropertyInjectionPoint = new PropertyInjectionPoint(
					field.type + '|' + mappingName, field.name, optional, injectParameters);
			description.addInjectionPoint(injectionPoint);
		}
	}

	private function gatherMethodParameters(
		parameters:Array, parameterNames:Array, typeName:String):UInt
	{
		var requiredLength:UInt = 0;
		var length:UInt = parameters.length;
		for (var i:Int = 0; i < length; i++)
		{
			var parameter:Dynamic = parameters[i];
			var injectionName:String = parameterNames[i] || '';
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

	private function gatherOrderedInjectionPointsForTag(
		injectionPointClass:Class, tag:String, methods:Array, typeName:String):Array
	{
		var injectionPoints:Array = [];
		if (!methods)
		{
			return injectionPoints;
		}
		var length:UInt = methods.length;
		for (var i:Int = 0; i < length; i++)
		{
			var method:Dynamic = methods[i];
			var injectParameters:Dynamic = extractTagParameters(tag, method.metadata);
			if (!injectParameters)
			{
				continue;
			}
			var parameterNames:Array = (injectParameters.name || '').split(',');
			var parameters:Array = method.parameters;
			var requiredParameters:UInt;
			if (parameters)
			{
				requiredParameters =
					gatherMethodParameters(parameters, parameterNames, typeName);
			}
			else
			{
				parameters = [];
				requiredParameters = 0;
			}
			var order:Int = parseInt(injectParameters.order, 10);
			//Int can't be NaN, so we have to verify that parsing succeeded by comparison
			if (order.toString(10) != injectParameters.order)
			{
				order = Int.MAX_VALUE;
			}
			injectionPoints.push(new injectionPointClass(
				method.name, parameters, requiredParameters, order));
		}
		if (injectionPoints.length > 0)
		{
			injectionPoints.sortOn('order', Array.NUMERIC);
		}
		return injectionPoints;
	}
	private function extractTagParameters(tag:String, metadata:Array):Dictionary
	{
		var length:UInt = metadata ? metadata.length:0;
		for (var i:Int = 0; i < length; i++)
		{
			var entry:Dynamic = metadata[i];
			if (entry.name == tag)
			{
				var parametersList:Array = entry.value;
				var parametersMap:Dictionary = new Dictionary();
				var parametersCount:Int = parametersList.length;
				for (var j:Int = 0; j < parametersCount; j++)
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