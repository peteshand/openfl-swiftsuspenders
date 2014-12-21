/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.dependencyproviders;

import openfl.utils.Dictionary;
import org.swiftsuspenders.Injector;

class FactoryProvider implements DependencyProvider
{
	//----------------------       Private / Protected Properties       ----------------------//
	private var _factoryClass:Class;

	//----------------------               Public Methods               ----------------------//
	public function new(factoryClass:Class)
	{
		_factoryClass = factoryClass;
	}

	public function apply(
		targetType:Class, activeInjector:Injector, injectParameters:Dictionary):Dynamic
	{
		return DependencyProvider(activeInjector.getInstance(_factoryClass))
				.apply(targetType, activeInjector, injectParameters);
	}

	public function destroy():Void
	{
	}
}