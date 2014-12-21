/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file 
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.typedescriptions;

import avmplus.getQualifiedClassName;

import openfl.utils.Dictionary;

import org.swiftsuspenders.Injector;
import org.swiftsuspenders.errors.InjectorMissingMappingError;
import org.swiftsuspenders.dependencyproviders.DependencyProvider;

class MethodInjectionPoint extends InjectionPoint
{
	//----------------------       Private / Protected Properties       ----------------------//
	protected var _parameterMappingIDs:Array;
	protected var _requiredParameters:Int;

	private var _isOptional:Bool;
	private var _methodName:String;

	//----------------------               Public Methods               ----------------------//
	public function new(methodName:String, parameters:Array,
		requiredParameters:UInt, isOptional:Bool, injectParameters:Dictionary)
	{
		_methodName = methodName;
		_parameterMappingIDs = parameters;
		_requiredParameters = requiredParameters;
		_isOptional = isOptional;
		this.injectParameters = injectParameters;
	}
	
	override public function applyInjection(
			target:Dynamic, targetType:Class, injector:Injector):Void
	{
		var p:Array = gatherParameterValues(target, targetType, injector);
		if (p.length >= _requiredParameters)
		{
			(target[_methodName] as Function).apply(target, p);
		}

		p.length = 0;
	}

	//----------------------         Private / Protected Methods        ----------------------//
	protected function gatherParameterValues(
			target:Dynamic, targetType:Class, injector:Injector):Array
	{
		var length:Int = _parameterMappingIDs.length;
		var parameters:Array = [];
		parameters.length = length;
		for (var i:Int = 0; i < length; i++)
		{
			var parameterMappingId:String = _parameterMappingIDs[i];
			var provider:DependencyProvider =
				injector.getProvider(parameterMappingId);
			if (!provider)
			{
				if (i >= _requiredParameters || _isOptional)
				{
					break;
				}
				throw(new InjectorMissingMappingError(
					'Injector is missing a mapping to handle injection into target "' +
					target + '" of type "' + getQualifiedClassName(targetType) + '". \
					Target dependency: ' + parameterMappingId +
					', method: ' + _methodName + ', parameter: ' + (i + 1)
				));
			}
			
			parameters[i] = provider.apply(targetType, injector, injectParameters);
		}
		return parameters;
	}
}