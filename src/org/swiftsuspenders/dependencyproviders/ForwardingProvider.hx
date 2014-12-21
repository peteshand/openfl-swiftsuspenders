/*
 * Copyright (c) 2012 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.dependencyproviders;

import openfl.utils.Dictionary;

import org.swiftsuspenders.Injector;

class ForwardingProvider implements DependencyProvider
{
	//----------------------              Public Properties             ----------------------//
	public var provider:DependencyProvider;

	//----------------------               Public Methods               ----------------------//
	public function new(provider:DependencyProvider)
	{
		this.provider = provider;
	}

	public function apply(
		targetType:Class, activeInjector:Injector, injectParameters:Dictionary):Dynamic
	{
		return provider.apply(targetType, activeInjector, injectParameters);
	}

	public function destroy():Void
	{
		provider.destroy();
	}
}