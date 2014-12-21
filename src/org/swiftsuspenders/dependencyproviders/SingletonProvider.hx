/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.dependencyproviders;

import openfl.utils.Dictionary;
import flash.utils.getQualifiedClassName;

import org.swiftsuspenders.Injector;
import org.swiftsuspenders.errors.InjectorError;

class SingletonProvider implements DependencyProvider
{
	//----------------------       Private / Protected Properties       ----------------------//
	private var _responseType:Class;
	private var _creatingInjector:Injector;
	private var _response:Dynamic;
	private var _destroyed:Bool;

	//----------------------               Public Methods               ----------------------//
	/**
	 *
	 * @param responseType The class the provider returns the same, lazily created, instance
	 * of for each request
	 * @param creatingInjector The injector that was used to create the
	 * <code>InjectionMapping</code> this DependencyProvider is associated with
	 */
	public function new(responseType:Class, creatingInjector:Injector)
	{
		_responseType = responseType;
		_creatingInjector = creatingInjector;
	}

	/**
	 * @inheritDoc
	 *
	 * @return The same, lazily created, instance of the class given to the SingletonProvider's
	 * constructor on each invocation
	 */
	public function apply(
		targetType:Class, activeInjector:Injector, injectParameters:Dictionary):Dynamic
	{
		return _response ||= createResponse(_creatingInjector);
	}


	//----------------------         Private / Protected Methods        ----------------------//
	private function createResponse(injector:Injector):Dynamic
	{
		if (_destroyed)
		{
			throw new InjectorError("Forbidden usage of unmapped singleton provider for type "
				+ getQualifiedClassName(_responseType));
		}
		return injector.instantiateUnmapped(_responseType);
	}

	public function destroy():Void
	{
		_destroyed = true;
		if (_response && _creatingInjector && _creatingInjector.hasManagedInstance(_response))
		{
			_creatingInjector.destroyInstance(_response);
		}
		_creatingInjector = null;
		_response = null;
	}
}